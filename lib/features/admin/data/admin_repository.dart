import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/user_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) {
    throw StateError('Firebase غير مهيأ لهذا المشروع.');
  }
  return AdminRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class AdminRepository {
  AdminRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<UserModel>> watchUsers() => _firestore
      .collection('users')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(UserModel.fromFirestore).toList(growable: false)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  Stream<List<JobModel>> watchJobs() => _firestore
      .collection('jobs')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(JobModel.fromFirestore).toList(growable: false)
              ..sort((a, b) => b.postedAt.compareTo(a.postedAt)),
      );

  Stream<int> watchUsersCount() => watchUsers().map((users) => users.length);

  Stream<int> watchJobsCount() => _firestore
      .collection('jobs')
      .snapshots()
      .map((snapshot) => snapshot.size);

  Stream<int> watchApplicationsCount() => _firestore
      .collection('applications')
      .snapshots()
      .map((snapshot) => snapshot.size);

  Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    final admin = await _requireAdmin();
    if (admin.id == userId && !isActive) {
      throw StateError('لا يمكن للحساب الإداري إيقاف نفسه.');
    }
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
    });
  }

  Future<void> hideJob(String jobId) async {
    await _requireAdmin();
    await _firestore.collection('jobs').doc(jobId).update({
      'status': JobStatus.hidden.value,
      'isFeatured': false,
    });
  }

  Future<void> setJobFeatured({
    required String jobId,
    required bool isFeatured,
  }) async {
    await _requireAdmin();
    await _firestore.collection('jobs').doc(jobId).update({
      'isFeatured': isFeatured,
    });
  }

  Future<UserModel> _requireAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('سجل الدخول بحساب إداري أولًا.');
    }
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    if (!snapshot.exists) {
      throw StateError('تعذر التحقق من ملف المستخدم.');
    }
    final profile = UserModel.fromFirestore(snapshot);
    if (profile.role != UserRole.admin || !profile.isActive) {
      throw StateError('لا تملك صلاحية تنفيذ إجراء إداري.');
    }
    return profile;
  }
}
