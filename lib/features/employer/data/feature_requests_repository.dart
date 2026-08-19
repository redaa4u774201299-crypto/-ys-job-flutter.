import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../../../shared/models/feature_request_model.dart';
import '../../../shared/models/job_model.dart';

final featureRequestsRepositoryProvider = Provider<FeatureRequestsRepository>((
  ref,
) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) throw StateError('Firebase غير مهيأ لهذا المشروع.');
  return FeatureRequestsRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

class FeatureRequestsRepository {
  FeatureRequestsRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> requestFeature(JobModel job) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('سجل الدخول أولًا لإرسال طلب التمييز.');
    if (job.employerId != user.uid) {
      throw StateError('لا تملك صلاحية طلب تمييز هذه الوظيفة.');
    }
    if (job.isFeatured) throw StateError('هذه الوظيفة مميزة بالفعل.');

    // يستخدم معرف الوظيفة ذاته لمنع إنشاء أكثر من طلب نشط أو مكرر لنفس الوظيفة.
    final reference = _firestore.collection('feature_requests').doc(job.id);
    final existing = await reference.get();
    if (existing.exists) {
      final request = FeatureRequestModel.fromFirestore(existing);
      throw StateError(
        request.status == FeatureRequestStatus.pending
            ? 'يوجد طلب تمييز لهذه الوظيفة قيد المراجعة بالفعل.'
            : 'يوجد سجل سابق لطلب تمييز هذه الوظيفة. تواصل مع الإدارة للمراجعة.',
      );
    }

    final request = FeatureRequestModel(
      id: reference.id,
      jobId: job.id,
      employerId: user.uid,
      status: FeatureRequestStatus.pending,
      requestedAt: DateTime.now().toUtc(),
    );
    await reference.set({
      ...request.toFirestore(),
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }
}
