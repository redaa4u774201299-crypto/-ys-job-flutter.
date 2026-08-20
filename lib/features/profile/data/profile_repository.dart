import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) throw StateError('Firebase غير مهيأ لهذا المشروع.');
  return ProfileRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    FirebaseStorage.instance,
  );
});

class ProfileRepository {
  ProfileRepository(this._firestore, this._auth, this._storage);

  static const int maxResumeBytes = 5 * 1024 * 1024;
  static const int maxImageBytes = 2 * 1024 * 1024;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

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

  Future<String> uploadResume(PlatformFile file) async {
    final user = _requireUser();
    validateResumeFile(file);
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('تعذر قراءة ملف السيرة الذاتية.');
    }
    final reference = _storage.ref(
      'resumes/${user.uid}/${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    await reference.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    final url = await reference.getDownloadURL();
    await _firestore.collection('users').doc(user.uid).update({
      'resumeUrl': url,
    });
    return url;
  }

  Future<String> uploadPhoto(PlatformFile file) =>
      _uploadImage(file, folder: 'photos');

  Future<String> uploadCompanyLogo(PlatformFile file) =>
      _uploadImage(file, folder: 'logos');

  Future<String> _uploadImage(
    PlatformFile file, {
    required String folder,
  }) async {
    final user = _requireUser();
    validateImageFile(file);
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('تعذر قراءة الصورة المختارة.');
    }

    final extension = _imageExtension(file);
    final reference = _storage.ref(
      '$folder/${user.uid}/${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await reference.putData(
      bytes,
      SettableMetadata(contentType: _imageContentType(extension)),
    );
    final url = await reference.getDownloadURL();
    await _firestore.collection('users').doc(user.uid).update({
      'photoUrl': url,
    });
    return url;
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
  }) => {
    'name': name.trim(),
    'bio': bio.trim(),
    'skills': normalizedSkills(skills),
    'phone': phone.trim(),
    'jobTitle': jobTitle.trim(),
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

  static void validateResumeFile(PlatformFile file) {
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      throw const FormatException('يسمح برفع ملفات PDF فقط.');
    }
    if (file.size > maxResumeBytes) {
      throw const FormatException(
        'الحد الأقصى لحجم السيرة الذاتية 5 ميغابايت.',
      );
    }
  }

  static void validateImageFile(PlatformFile file) {
    final extension = _imageExtension(file);
    if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
      throw const FormatException('يسمح برفع صور JPG أو PNG فقط.');
    }
    if (file.size > maxImageBytes) {
      throw const FormatException('الحد الأقصى لحجم الصورة 2 ميغابايت.');
    }
  }

  static String _imageExtension(PlatformFile file) {
    final extension = file.extension?.toLowerCase().trim();
    if (extension != null && extension.isNotEmpty) return extension;
    final parts = file.name.toLowerCase().split('.');
    return parts.length > 1 ? parts.last : '';
  }

  static String _imageContentType(String extension) => switch (extension) {
    'png' => 'image/png',
    _ => 'image/jpeg',
  };

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('سجل الدخول أولًا لإدارة ملفك الشخصي.');
    }
    return user;
  }
}
