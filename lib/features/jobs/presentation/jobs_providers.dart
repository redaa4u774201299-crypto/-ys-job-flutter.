import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/jobs_repository.dart';
import '../../../shared/models/job_model.dart';

/// يبقي تدفقات Firestore الخاصة بواجهة الباحث قابلة لإعادة الاستخدام
/// ومتصلة تلقائيًا بالفلاتر النشطة من دون تخزين بيانات مكررة محليًا.
final availableJobsProvider = StreamProvider.autoDispose
    .family<List<JobModel>, JobFilters>((ref, filters) {
      return ref.watch(jobsRepositoryProvider).watchAvailableJobs(filters);
    });

final jobDetailsProvider = StreamProvider.autoDispose.family<JobModel?, String>(
  (ref, jobId) {
    return ref.watch(jobsRepositoryProvider).watchJob(jobId);
  },
);
