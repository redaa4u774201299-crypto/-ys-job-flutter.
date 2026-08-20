import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/firebase/firebase_runtime.dart';
import '../../../shared/models/company_directory_entry.dart';
import '../../../shared/models/user_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) throw StateError('Firebase غير مهيأ لهذا المشروع.');
  return ProfileRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

enum ProfileSyncOutcome { synced, pending }

class ProfileImagePayload {
  const ProfileImagePayload({
    required this.fullBase64,
    required this.thumbnailBase64,
  });

  final String fullBase64;
  final String thumbnailBase64;
}

class ProfileRepository {
  ProfileRepository(
    this._firestore,
    this._auth, {
    this.syncConfirmationTimeout = const Duration(seconds: 2),
    Future<void> Function()? waitForPendingWrites,
  }) : _waitForPendingWrites =
           waitForPendingWrites ?? _firestore.waitForPendingWrites;

  static const int maxSourceImageBytes = 2 * 1024 * 1024;
  // يترك هذا السقف هامشًا كبيرًا للحقول النصية الأخرى داخل مستند المستخدم.
  // Base64 نص ASCII؛ لذلك يمثل طوله عدد البايتات التي ستضاف إلى مستند Firestore.
  static const int maxImageBase64Bytes = 512 * 1024;
  static const int maxImageDimension = 512;
  static const int maxThumbnailBase64Bytes = 16 * 1024;
  static const int maxThumbnailDimension = 96;
  static const List<int> _jpegQualitySteps = [72, 64, 56, 48, 40];
  static const List<int> _thumbnailQualitySteps = [56, 48, 40, 32];
  static const List<int> _dimensionSteps = [512, 448, 384, 320, 256];

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Duration syncConfirmationTimeout;
  final Future<void> Function() _waitForPendingWrites;

  Future<ProfileSyncOutcome> updateProfile({
    required String name,
    required String bio,
    required List<String> skills,
  }) async {
    return _savePayload({
      'name': name.trim(),
      'bio': bio.trim(),
      'skills': normalizedSkills(skills),
    });
  }

  Future<ProfileSyncOutcome> updateSeekerProfile({
    required String name,
    required String bio,
    required List<String> skills,
    required String phone,
    required String jobTitle,
    required String cvUrl,
  }) async {
    return _savePayload(
      seekerProfilePayload(
        name: name,
        bio: bio,
        skills: skills,
        phone: phone,
        jobTitle: jobTitle,
        cvUrl: cvUrl,
      ),
    );
  }

  Future<ProfileSyncOutcome> updateEmployerProfile({
    required String name,
    required String companyName,
    required String industry,
    required String bio,
    required String phone,
  }) async {
    return _saveEmployerPayload(
      employerProfilePayload(
        name: name,
        companyName: companyName,
        industry: industry,
        bio: bio,
        phone: phone,
      ),
    );
  }

  Future<ProfileSyncOutcome> saveSeekerImage(PlatformFile file) {
    final image = encodeProfileImage(file);
    return _saveSeekerImagePayload(image);
  }

  Future<ProfileSyncOutcome> saveSeekerImageBytes(Uint8List bytes) {
    return _saveSeekerImagePayload(encodeProfileImageFromBytes(bytes));
  }

  Future<ProfileSyncOutcome> _saveSeekerImagePayload(
    ProfileImagePayload image,
  ) {
    return _savePayload({
      'imageBase64': image.fullBase64,
      'imageThumbBase64': image.thumbnailBase64,
    });
  }

  Future<ProfileSyncOutcome> saveCompanyLogo(PlatformFile file) async {
    return _saveCompanyLogoPayload(encodeProfileImage(file));
  }

  Future<ProfileSyncOutcome> saveCompanyLogoBytes(Uint8List bytes) {
    return _saveCompanyLogoPayload(encodeProfileImageFromBytes(bytes));
  }

  Future<ProfileSyncOutcome> _saveCompanyLogoPayload(
    ProfileImagePayload logo,
  ) async {
    final user = _requireUser();
    await _writeEmployerPayload(user.uid, {
      'logoBase64': logo.fullBase64,
      'logoThumbBase64': logo.thumbnailBase64,
    });
    await _synchronizeEmployerLogoThumbnail(user.uid, logo.thumbnailBase64);
    return _confirmPendingWrites();
  }

  Future<ProfileSyncOutcome> retryPendingSync() => _confirmPendingWrites();

  Future<ProfileSyncOutcome> _savePayload(Map<String, dynamic> payload) async {
    final user = _requireUser();
    await _writePayload(user.uid, payload);
    return _confirmPendingWrites();
  }

  Future<ProfileSyncOutcome> _saveEmployerPayload(
    Map<String, dynamic> payload,
  ) async {
    final user = _requireUser();
    await _writeEmployerPayload(user.uid, payload);
    return _confirmPendingWrites();
  }

  Future<void> _writePayload(String userId, Map<String, dynamic> payload) {
    return _firestore
        .collection('users')
        .doc(userId)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> _writeEmployerPayload(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final profileReference = _firestore.collection('users').doc(userId);
    final snapshot = await profileReference.get();
    if (!snapshot.exists) {
      throw StateError('تعذر العثور على ملف الشركة الحالي.');
    }

    final currentData = snapshot.data() ?? const <String, dynamic>{};
    final profile = UserModel.fromJson({
      ...currentData,
      ...payload,
      'id': userId,
    });
    if (profile.role != UserRole.employer) {
      throw StateError('لا يمكن مزامنة دليل الشركات إلا لحساب صاحب عمل.');
    }

    final directoryEntry = CompanyDirectoryEntry.fromEmployerProfile(
      profile,
      city: currentData['city']?.toString() ?? '',
    );
    final batch = _firestore.batch()
      ..set(profileReference, payload, SetOptions(merge: true))
      ..set(
        _firestore.collection('company_directory').doc(userId),
        directoryEntry.toFirestore(),
      );
    await batch.commit();
  }

  Future<void> _synchronizeEmployerLogoThumbnail(
    String employerId,
    String thumbnailBase64,
  ) async {
    final jobs = await _firestore
        .collection('jobs')
        .where('employerId', isEqualTo: employerId)
        .get();
    for (var start = 0; start < jobs.docs.length; start += 450) {
      final end = (start + 450).clamp(0, jobs.docs.length);
      final batch = _firestore.batch();
      for (final job in jobs.docs.sublist(start, end)) {
        batch.update(job.reference, {
          'employerLogoThumbBase64': thumbnailBase64,
        });
      }
      await batch.commit();
    }
  }

  Future<ProfileSyncOutcome> _confirmPendingWrites() async {
    try {
      await _waitForPendingWrites().timeout(syncConfirmationTimeout);
      return ProfileSyncOutcome.synced;
    } on TimeoutException {
      // تظل الكتابة في طابور Firestore المحلي وستعاد تلقائيًا عند عودة الشبكة.
      return ProfileSyncOutcome.pending;
    } on FirebaseException catch (error) {
      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
        return ProfileSyncOutcome.pending;
      }
      rethrow;
    }
  }

  static List<String> normalizedSkills(Iterable<String> skills) {
    final uniqueSkills = <String>{};
    for (final skill in skills) {
      final normalized = skill.trim();
      if (normalized.isNotEmpty) uniqueSkills.add(normalized);
    }
    return uniqueSkills.toList(growable: false);
  }

  static Map<String, dynamic> seekerProfilePayload({
    required String name,
    required String bio,
    required Iterable<String> skills,
    required String phone,
    required String jobTitle,
    required String cvUrl,
  }) => {
    'name': name.trim(),
    'bio': bio.trim(),
    'skills': normalizedSkills(skills),
    'phone': phone.trim(),
    'jobTitle': jobTitle.trim(),
    'cvUrl': normalizedExternalCvUrl(cvUrl),
  };

  static Map<String, dynamic> employerProfilePayload({
    required String name,
    required String companyName,
    required String industry,
    required String bio,
    required String phone,
  }) => {
    'name': name.trim(),
    'companyName': companyName.trim(),
    'industry': industry.trim(),
    'bio': bio.trim(),
    'phone': phone.trim(),
  };

  static void validateImageFile(PlatformFile file) {
    final extension = _imageExtension(file);
    if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
      throw const FormatException('يسمح باختيار صور JPG أو PNG فقط.');
    }
    if (file.size > maxSourceImageBytes) {
      throw const FormatException(
        'الحد الأقصى لحجم الصورة قبل المعالجة 2 ميغابايت.',
      );
    }
  }

  static String encodeImageBase64(
    PlatformFile file, {
    int maxEncodedBytes = maxImageBase64Bytes,
  }) {
    validateImageFile(file);
    return encodeImageBase64FromBytes(
      file.bytes ?? Uint8List(0),
      maxEncodedBytes: maxEncodedBytes,
    );
  }

  static String encodeImageBase64FromBytes(
    Uint8List bytes, {
    int maxEncodedBytes = maxImageBase64Bytes,
  }) {
    if (maxEncodedBytes <= 0) {
      throw ArgumentError.value(
        maxEncodedBytes,
        'maxEncodedBytes',
        'يجب أن تكون ميزانية Base64 أكبر من صفر.',
      );
    }
    return _encodeImageWithinBudget(
      _decodeImageBytes(bytes),
      maxEncodedBytes: maxEncodedBytes,
    );
  }

  static ProfileImagePayload encodeProfileImage(PlatformFile file) {
    validateImageFile(file);
    return encodeProfileImageFromBytes(file.bytes ?? Uint8List(0));
  }

  static ProfileImagePayload encodeProfileImageFromBytes(Uint8List bytes) {
    final image = _decodeImageBytes(bytes);
    return ProfileImagePayload(
      fullBase64: _encodeImageWithinBudget(image),
      thumbnailBase64: _encodeThumbnailBase64(image),
    );
  }

  static img.Image _decodeImageBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('تعذر قراءة الصورة المختارة.');
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('تعذر معالجة الصورة المختارة.');
    }
    return img.bakeOrientation(decoded);
  }

  static String _encodeImageWithinBudget(
    img.Image image, {
    int maxEncodedBytes = maxImageBase64Bytes,
  }) {
    if (maxEncodedBytes <= 0) {
      throw ArgumentError.value(
        maxEncodedBytes,
        'maxEncodedBytes',
        'يجب أن تكون ميزانية Base64 أكبر من صفر.',
      );
    }
    for (final dimension in _dimensionSteps) {
      final resized = _resizeImage(image, maxDimension: dimension);
      for (final quality in _jpegQualitySteps) {
        final encoded = base64Encode(img.encodeJpg(resized, quality: quality));
        if (encoded.length <= maxEncodedBytes) return encoded;
      }
    }
    throw const FormatException(
      'تعذر ضغط الصورة ضمن الحد الآمن. اختر صورة أبسط أو أصغر.',
    );
  }

  static String _encodeThumbnailBase64(img.Image image) {
    final thumbnail = _resizeImage(image, maxDimension: maxThumbnailDimension);
    for (final quality in _thumbnailQualitySteps) {
      final encoded = base64Encode(img.encodeJpg(thumbnail, quality: quality));
      if (encoded.length <= maxThumbnailBase64Bytes) return encoded;
    }
    throw const FormatException('تعذر إنشاء نسخة مصغرة آمنة للصورة.');
  }

  static img.Image _resizeImage(img.Image image, {required int maxDimension}) {
    final longestSide = image.width > image.height ? image.width : image.height;
    if (longestSide <= maxDimension) return image;
    return image.width >= image.height
        ? img.copyResize(image, width: maxDimension)
        : img.copyResize(image, height: maxDimension);
  }

  static String normalizedExternalCvUrl(String value) {
    final url = value.trim();
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const FormatException('أدخل رابطًا خارجيًا صالحًا للسيرة الذاتية.');
    }
    return uri.toString();
  }

  static String _imageExtension(PlatformFile file) {
    final extension = file.extension?.toLowerCase().trim();
    if (extension != null && extension.isNotEmpty) return extension;
    final parts = file.name.toLowerCase().split('.');
    return parts.length > 1 ? parts.last : '';
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('سجل الدخول أولًا لإدارة ملفك الشخصي.');
    }
    return user;
  }
}
