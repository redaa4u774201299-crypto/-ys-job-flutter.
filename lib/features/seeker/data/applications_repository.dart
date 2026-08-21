import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../../../core/monitoring/app_performance_monitor.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/user_model.dart';
import '../../notifications/data/notifications_repository.dart';

final applicationsRepositoryProvider = Provider<ApplicationsRepository>((ref) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) throw StateError('Firebase غير مهيأ لهذا المشروع.');
  return ApplicationsRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref.watch(notificationsRepositoryProvider),
    ref.watch(appPerformanceMonitorProvider),
  );
});

class ApplicationsRepository {
  ApplicationsRepository(
    this._firestore,
    this._auth,
    this._notifications,
    this._performanceMonitor,
  );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationsRepository _notifications;
  final AppPerformanceMonitor _performanceMonitor;

  Future<void> applyToJob(
    JobModel job,
  ) => _performanceMonitor.measure<void>('application_submit', () async {
    final seeker = _auth.currentUser;
    if (seeker == null)
      throw StateError('سجل الدخول أولًا للتقديم على الوظيفة.');
    if (seeker.uid == job.employerId) {
      throw StateError('لا يمكن لصاحب الوظيفة التقديم عليها.');
    }
    final seekerProfile = await _firestore
        .collection('users')
        .doc(seeker.uid)
        .get();
    final profileData = seekerProfile.data();
    if (!seekerProfile.exists ||
        profileData?['role'] != 'seeker' ||
        profileData?['isActive'] == false) {
      throw StateError('التقديم متاح لحساب الباحث النشط فقط.');
    }

    final id = '${job.id}_${seeker.uid}';
    final reference = _firestore.collection('applications').doc(id);
    final jobReference = _firestore.collection('jobs').doc(job.id);
    await _firestore.runTransaction((transaction) async {
      final jobSnapshot = await transaction.get(jobReference);
      if (!jobSnapshot.exists ||
          jobSnapshot.data()?['status'] != JobStatus.active.value) {
        throw StateError('هذه الوظيفة لم تعد متاحة للتقديم.');
      }
      final existing = await transaction.get(reference);
      if (existing.exists) throw StateError('لقد قدمت على هذه الوظيفة مسبقًا.');
      final employerId = jobSnapshot.data()?['employerId']?.toString() ?? '';
      if (employerId.isEmpty) {
        throw StateError('تعذر التحقق من صاحب الوظيفة.');
      }
      final application = ApplicationModel(
        id: id,
        jobId: job.id,
        seekerId: seeker.uid,
        employerId: employerId,
        status: ApplicationStatus.pending,
        appliedAt: DateTime.now().toUtc(),
      );
      transaction.set(reference, {
        ...application.toFirestore(),
        'appliedAt': FieldValue.serverTimestamp(),
      });
    });
  });

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

  Stream<List<EmployerApplicationRecord>> watchCurrentEmployerJobApplications(
    String jobId,
  ) async* {
    final employer = _requireUser();
    await _requireActiveRole(employer.uid, UserRole.employer);

    final jobSnapshot = await _firestore.collection('jobs').doc(jobId).get();
    if (!jobSnapshot.exists ||
        jobSnapshot.data()?['employerId']?.toString() != employer.uid) {
      throw StateError('لا تملك صلاحية عرض طلبات هذه الوظيفة.');
    }

    yield* _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .asyncMap((snapshot) async {
          final applications =
              snapshot.docs
                  .map(ApplicationModel.fromFirestore)
                  .where(
                    (application) => application.employerId == employer.uid,
                  )
                  .toList(growable: false)
                ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          final records = await Future.wait(
            applications.map((application) async {
              final seekerSnapshot = await _firestore
                  .collection('users')
                  .doc(application.seekerId)
                  .get();
              return EmployerApplicationRecord(
                application: application,
                seeker: seekerSnapshot.exists
                    ? UserModel.fromFirestore(seekerSnapshot)
                    : null,
              );
            }),
          );
          return records;
        });
  }

  Stream<List<SeekerApplicationRecord>>
  watchCurrentSeekerApplications() async* {
    final seeker = _requireUser();
    await _requireActiveRole(seeker.uid, UserRole.seeker);

    yield* _firestore
        .collection('applications')
        .where('seekerId', isEqualTo: seeker.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final applications =
              snapshot.docs
                  .map(ApplicationModel.fromFirestore)
                  .toList(growable: false)
                ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          final records = await Future.wait(
            applications.map((application) async {
              final jobSnapshot = await _firestore
                  .collection('jobs')
                  .doc(application.jobId)
                  .get();
              return SeekerApplicationRecord(
                application: application,
                job: jobSnapshot.exists
                    ? JobModel.fromFirestore(jobSnapshot)
                    : null,
              );
            }),
          );
          return records;
        });
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    final employer = _auth.currentUser;
    if (employer == null) {
      throw StateError('سجل الدخول أولًا لإدارة طلبات المتقدمين.');
    }
    await _requireActiveRole(employer.uid, UserRole.employer);
    final reference = _firestore.collection('applications').doc(applicationId);
    final snapshot = await reference.get();
    if (!snapshot.exists) throw StateError('لم يعد طلب التقديم متاحًا.');
    final application = ApplicationModel.fromFirestore(snapshot);
    if (application.employerId != employer.uid) {
      throw StateError('لا تملك صلاحية تحديث حالة هذا الطلب.');
    }
    final jobSnapshot = await _firestore
        .collection('jobs')
        .doc(application.jobId)
        .get();
    if (!jobSnapshot.exists ||
        jobSnapshot.data()?['employerId']?.toString() != employer.uid) {
      throw StateError(
        'لا تملك صلاحية تحديث طلب لا يخص وظيفة منشورة من حسابك.',
      );
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

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('سجل الدخول أولًا للوصول إلى طلبات التقديم.');
    }
    return user;
  }

  Future<void> _requireActiveRole(String userId, UserRole role) async {
    final profile = await _firestore.collection('users').doc(userId).get();
    final data = profile.data();
    if (!profile.exists ||
        data?['role'] != role.name ||
        data?['isActive'] == false) {
      throw StateError('هذه العملية متاحة لحساب ${role.label} النشط فقط.');
    }
  }
}

class EmployerApplicationRecord {
  const EmployerApplicationRecord({required this.application, this.seeker});

  final ApplicationModel application;
  final UserModel? seeker;
}

class SeekerApplicationRecord {
  const SeekerApplicationRecord({required this.application, this.job});

  final ApplicationModel application;
  final JobModel? job;
}
