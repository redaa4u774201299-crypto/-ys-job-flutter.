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
      'skills': skills
          .where((skill) => skill.trim().isNotEmpty)
          .map((skill) => skill.trim())
          .toList(growable: false),
    });
  }

  Future<String> uploadResume(PlatformFile file) async {
    final user = _requireUser();
    final fileName = file.name.toLowerCase();
    if (!fileName.endsWith('.pdf')) {
      throw const FormatException('يسمح برفع ملفات PDF فقط.');
    }
    if (file.size > 5 * 1024 * 1024) {
      throw const FormatException(
        'الحد الأقصى لحجم السيرة الذاتية 5 ميغابايت.',
      );
    }
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

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('سجل الدخول أولًا لإدارة ملفك الشخصي.');
    }
    return user;
  }
}
