/// أسماء المسارات العامة والمحمية التي تعتمدها واجهة YS JOB.
///
/// يجمع هذا العقد نقاط التنقل الخاصة بصاحب العمل لمنع استمرار أي شاشة في
/// استخدام مسار نشر الوظيفة القديم بعد اعتماد المسار المستقل.
abstract final class AppRoutes {
  static const jobs = '/jobs';
  static const jobDetailsPattern = '/job-details/:id';
  static const legacyJobDetailsPattern = '/job/:id';
  static const employerDashboard = '/employer-dashboard';
  static const addJob = '/add-job';

  /// يبني رابط تفاصيل الوظيفة من معرّف Firestore الحقيقي دون تكرار نص المسار.
  static String jobDetails(String jobId) => '/job-details/$jobId';

  /// يحافظ على روابط التفاصيل القديمة دون إبقائها مسارًا رئيسيًا في الواجهة.
  static String redirectLegacyJobDetails(String jobId) => jobDetails(jobId);

  /// مسار قديم يُحافَظ عليه كرابط متوافق مع الروابط المحفوظة فقط.
  static const legacyEmployerPostJob = '/employer/post-job';

  /// يعيد توجيه رابط النشر القديم إلى المسار المستقل المعتمد.
  static String? redirectLegacyEmployerPostJob(String location) =>
      location == legacyEmployerPostJob ? addJob : null;
}
