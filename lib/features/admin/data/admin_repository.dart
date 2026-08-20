import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../../../shared/models/feature_request_model.dart';
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

  Stream<int> watchActiveJobsCount() => _firestore
      .collection('jobs')
      .where('status', isEqualTo: JobStatus.active.value)
      .snapshots()
      .map((snapshot) => snapshot.size);

  Stream<int> watchApplicationsCount() => _firestore
      .collection('applications')
      .snapshots()
      .map((snapshot) => snapshot.size);

  Stream<List<FeatureRequestAdminRow>> watchPendingFeatureRequests() =>
      _firestore
          .collection('feature_requests')
          .where('status', isEqualTo: FeatureRequestStatus.pending.value)
          .orderBy('requestedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            final requests = snapshot.docs
                .map(FeatureRequestModel.fromFirestore)
                .toList(growable: false);
            return Future.wait(
              requests.map((request) async {
                final jobSnapshot = await _firestore
                    .collection('jobs')
                    .doc(request.jobId)
                    .get();
                final job = jobSnapshot.exists
                    ? JobModel.fromFirestore(jobSnapshot)
                    : null;
                return FeatureRequestAdminRow(request: request, job: job);
              }),
            );
          });

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

  Future<void> deleteJob(String jobId) async {
    await _requireAdmin();
    final reference = _firestore.collection('jobs').doc(jobId);
    final snapshot = await reference.get();
    if (!snapshot.exists)
      throw StateError('الوظيفة غير متاحة أو حُذفت مسبقًا.');
    await reference.delete();
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

  Future<void> approveFeatureRequest(String requestId) async {
    final admin = await _requireAdmin();
    final requestReference = _firestore
        .collection('feature_requests')
        .doc(requestId);
    final requestSnapshot = await requestReference.get();
    if (!requestSnapshot.exists) throw StateError('طلب التمييز غير متاح.');
    final request = FeatureRequestModel.fromFirestore(requestSnapshot);
    if (request.status != FeatureRequestStatus.pending) {
      throw StateError('تمت مراجعة هذا الطلب مسبقًا.');
    }

    final jobReference = _firestore.collection('jobs').doc(request.jobId);
    final jobSnapshot = await jobReference.get();
    if (!jobSnapshot.exists) {
      throw StateError('الوظيفة المرتبطة بالطلب غير متاحة.');
    }
    final job = JobModel.fromFirestore(jobSnapshot);
    if (job.employerId != request.employerId) {
      throw StateError('بيانات ملكية الوظيفة لا تطابق طلب التمييز.');
    }

    final notificationReference = _firestore.collection('notifications').doc();
    final batch = _firestore.batch();
    batch.update(jobReference, {'isFeatured': true});
    batch.update(requestReference, {
      'status': FeatureRequestStatus.approved.value,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': admin.id,
    });
    batch.set(notificationReference, {
      'id': notificationReference.id,
      'userId': request.employerId,
      'title': 'تم تمييز وظيفتك',
      'message': 'تم استلام الدفعة وتم تمييز وظيفتك "${job.title}" بنجاح.',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'applicationId': '',
    });
    await batch.commit();
  }

  Future<void> rejectFeatureRequest(String requestId) async {
    await _requireAdmin();
    final reference = _firestore.collection('feature_requests').doc(requestId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) throw StateError('طلب التمييز غير متاح.');
      if (FeatureRequestStatus.fromValue(
            snapshot.data()?['status']?.toString(),
          ) !=
          FeatureRequestStatus.pending) {
        throw StateError('تمت مراجعة هذا الطلب مسبقًا.');
      }
      transaction.update(reference, {
        'status': FeatureRequestStatus.rejected.value,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
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

class FeatureRequestAdminRow {
  const FeatureRequestAdminRow({required this.request, required this.job});

  final FeatureRequestModel request;
  final JobModel? job;

  String get companyName {
    final name = job?.employerName.trim() ?? '';
    return name.isEmpty ? 'اسم الشركة غير متاح' : name;
  }

  String get jobTitle {
    final title = job?.title.trim() ?? '';
    return title.isEmpty ? 'الوظيفة غير متاحة' : title;
  }
}
