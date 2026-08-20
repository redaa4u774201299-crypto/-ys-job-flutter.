import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/firebase/firebase_runtime.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) throw StateError('Firebase غير مهيأ لهذا المشروع.');
  return ProfileRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class ProfileRepository {
  ProfileRepository(this._firestore, this._auth);

  static const int maxSourceImageBytes = 2 * 1024 * 1024;
  // يترك هذا السقف هامشًا كبيرًا للحقول النصية الأخرى داخل مستند المستخدم.
  // Base64 نص ASCII؛ لذلك يمثل طوله عدد البايتات التي ستضاف إلى مستند Firestore.
  static const int maxImageBase64Bytes = 512 * 1024;
  static const int maxImageDimension = 512;
  static const List<int> _jpegQualitySteps = [72, 64, 56, 48, 40];
  static const List<int> _dimensionSteps = [512, 448, 384, 320, 256];

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> updateProfile({
    required String name,
    required String bio,
    required List<String> skills,
  }) async {
    final user = _requireUser();
    await _firestore.collection('users').doc(user.uid).update({
      'name': name.trim(),
      'bio': bio.trim(),
      'skills': normalizedSkills(skills),
    });
  }

  Future<void> updateSeekerProfile({
    required String name,
    required String bio,
    required List<String> skills,
    required String phone,
    required String jobTitle,
    required String cvUrl,
  }) async {
    final user = _requireUser();
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(
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

  Future<void> updateEmployerProfile({
    required String name,
    required String companyName,
    required String industry,
    required String bio,
    required String phone,
  }) async {
    final user = _requireUser();
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(
          employerProfilePayload(
            name: name,
            companyName: companyName,
            industry: industry,
            bio: bio,
            phone: phone,
          ),
        );
  }

  Future<void> saveSeekerImage(PlatformFile file) async {
    final user = _requireUser();
    await _firestore.collection('users').doc(user.uid).update({
      'imageBase64': encodeImageBase64(file),
    });
  }

  Future<void> saveCompanyLogo(PlatformFile file) async {
    final user = _requireUser();
    await _firestore.collection('users').doc(user.uid).update({
      'logoBase64': encodeImageBase64(file),
    });
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
    if (maxEncodedBytes <= 0) {
      throw ArgumentError.value(
        maxEncodedBytes,
        'maxEncodedBytes',
        'يجب أن تكون ميزانية Base64 أكبر من صفر.',
      );
    }
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('تعذر قراءة الصورة المختارة.');
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('تعذر معالجة الصورة المختارة.');
    }
    final oriented = img.bakeOrientation(decoded);

    for (final dimension in _dimensionSteps) {
      final resized = _resizeImage(oriented, maxDimension: dimension);
      for (final quality in _jpegQualitySteps) {
        final compressed = Uint8List.fromList(
          img.encodeJpg(resized, quality: quality),
        );
        final encoded = base64Encode(compressed);
        if (encoded.length <= maxEncodedBytes) return encoded;
      }
    }

    throw const FormatException(
      'تعذر ضغط الصورة ضمن الحد الآمن. اختر صورة أبسط أو أصغر.',
    );
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
