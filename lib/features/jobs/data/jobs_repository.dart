import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../domain/job.dart';

final jobsRepositoryProvider = Provider<JobsRepository>(
  (ref) => JobsRepository(FirebaseFirestore.instance),
);

final publicJobsProvider = StreamProvider.autoDispose.family<List<Job>, String>(
  (ref, query) {
    final runtime = ref.watch(firebaseRuntimeProvider);
    if (!runtime.isReady) return Stream.value(const <Job>[]);
    return ref.watch(jobsRepositoryProvider).watchPublishedJobs(query: query);
  },
);

class JobsRepository {
  JobsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// يعرض فقط مستندات jobs النشطة التي تحتوي على عنوان واسم شركة حقيقيين.
  Stream<List<Job>> watchPublishedJobs({String query = ''}) {
    return _firestore
        .collection('jobs')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Job.fromFirestore)
              .where((job) => job.isDisplayable && job.matchesSearch(query))
              .toList(growable: false),
        );
  }
}
