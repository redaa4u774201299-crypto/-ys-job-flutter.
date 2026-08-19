import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/job_model.dart';

final applicationsRepositoryProvider = Provider<ApplicationsRepository>((ref) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) throw StateError('Firebase غير مهيأ لهذا المشروع.');
  return ApplicationsRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

class ApplicationsRepository {
  ApplicationsRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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
}
