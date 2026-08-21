import '../../../shared/models/job_model.dart';

/// ذاكرة تطبيق قصيرة العمر لنتائج بطاقات الوظائف العامة.
///
/// لا تحفظ أي بيانات على القرص ولا تحل محل Firestore؛ وظيفتها تفادي قراءة
/// إضافية عند فتح تفاصيل وظيفة نُقلت للتو من قائمة نتائج محمّلة بالفعل.
class JobDetailsCache {
  final Map<String, JobModel> _jobsById = <String, JobModel>{};

  JobModel? read(String jobId) => _jobsById[jobId.trim()];

  void put(JobModel job) {
    final id = job.id.trim();
    if (id.isEmpty) return;
    _jobsById[id] = job;
  }

  void putAll(Iterable<JobModel> jobs) {
    for (final job in jobs) {
      put(job);
    }
  }

  void remove(String jobId) => _jobsById.remove(jobId.trim());
}
