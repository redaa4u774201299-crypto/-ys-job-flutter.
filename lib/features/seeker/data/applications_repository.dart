import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/job_model.dart';
import '../../notifications/data/notifications_repository.dart';

final applicationsRepositoryProvider = Provider<ApplicationsRepository>((ref) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) throw StateError('Firebase غير مهيأ لهذا المشروع.');
  return ApplicationsRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref.watch(notificationsRepositoryProvider),
  );
});

class ApplicationsRepository {
  ApplicationsRepository(this._firestore, this._auth, this._notifications);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationsRepository _notifications;

  Future<void> applyToJob(JobModel job) async {
    final seeker = _auth.currentUser;
    if (seeker == null)
      throw StateError('سجل الدخول أولًا للتقديم على الوظيفة.');
    if (seeker.uid == job.employerId) {
      throw StateError('لا يمكن لصاحب الوظيفة التقديم عليها.');
    }
    final id = '${job.id}_${seeker.uid}';
    final reference = _firestore.collection('applications').doc(id);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) throw StateError('لقد قدمت على هذه الوظيفة مسبقًا.');
      final application = ApplicationModel(
        id: id,
        jobId: job.id,
        seekerId: seeker.uid,
        employerId: job.employerId,
        status: ApplicationStatus.pending,
        appliedAt: DateTime.now().toUtc(),
      );
      transaction.set(reference, {
        ...application.toFirestore(),
        'appliedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<bool> watchApplicationState(String jobId) {
    final seeker = _auth.currentUser;
    if (seeker == null) return Stream.value(false);
    return _firestore
        .collection('applications')
        .doc('${jobId}_${seeker.uid}')
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<int> watchEmployerApplicantCount(String employerId) => _firestore
      .collection('applications')
      .where('employerId', isEqualTo: employerId)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  Stream<List<ApplicationModel>> watchEmployerApplications(String employerId) =>
      _firestore
          .collection('applications')
          .where('employerId', isEqualTo: employerId)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(ApplicationModel.fromFirestore)
                    .toList(growable: false)
                  ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt)),
          );

  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    final employer = _auth.currentUser;
    if (employer == null) {
      throw StateError('سجل الدخول أولًا لإدارة طلبات المتقدمين.');
    }
    final reference = _firestore.collection('applications').doc(applicationId);
    final snapshot = await reference.get();
    if (!snapshot.exists) throw StateError('لم يعد طلب التقديم متاحًا.');
    final application = ApplicationModel.fromFirestore(snapshot);
    if (application.employerId != employer.uid) {
      throw StateError('لا تملك صلاحية تحديث حالة هذا الطلب.');
    }
    if (application.status == status) return;

    // يُحدّث الطلب ويُنشئ الإشعار معًا؛ لا يرى الباحث حالة جديدة من دون إشعارها.
    final batch = _firestore.batch();
    batch.update(reference, {'status': status.value});
    _notifications.createNotification(
      batch: batch,
      application: application,
      newStatus: status,
    );
    await batch.commit();
  }
}
