/// أسماء المسارات العامة والمحمية التي تعتمدها واجهة YS JOB.
///
/// يجمع هذا العقد نقاط التنقل الخاصة بصاحب العمل لمنع استمرار أي شاشة في
/// استخدام مسار نشر الوظيفة القديم بعد اعتماد المسار المستقل.
abstract final class AppRoutes {
  static const home = '/';
  static const jobs = '/jobs';
  static const jobDetailsPattern = '/job-details/:id';
  static const legacyJobDetailsPattern = '/job/:id';
  static const employerDashboard = '/employer-dashboard';
  static const addJob = '/add-job';
  static const seekerDashboard = '/seeker-dashboard';
  static const seekerSearch = '/seeker-dashboard/search';
  static const seekerApplications = '/seeker-dashboard/applications';
  static const seekerProfile = '/seeker-dashboard/profile';
  static const adminDashboard = '/admin-dashboard';
  static const adminUsers = '/admin/users';
  static const adminJobs = '/admin/jobs';
  static const adminFeatureRequests = '/admin/feature-requests';
  static const employerApplicationsPattern = '/employer/applications/:jobId';
  static const legacyEmployerApplicationsPattern =
      '/employer/jobs/:jobId/applications';

  /// يبني رابط تفاصيل الوظيفة من معرّف Firestore الحقيقي دون تكرار نص المسار.
  ///
  /// يُرمَّز المعرّف حتى يبقى رابط الويب صالحًا وقابلًا للمشاركة إذا احتوى على
  /// رموز خاصة، مع بقاء مسار go_router الموحد هو نقطة الدخول للرابط العميق.
  static String jobDetails(String jobId) =>
      '/job-details/${Uri.encodeComponent(jobId)}';

  /// يبني رابط الدخول مع الاحتفاظ بمسار تفاصيل وظيفة واحد فقط كوجهة عودة.
  static String loginForJobDetails(String jobId) =>
      '/login?returnTo=${Uri.encodeQueryComponent(jobDetails(jobId))}';

  /// يبني رابط إدارة طلبات وظيفة يملكها الحساب الحالي.
  static String employerApplications(String jobId) =>
      '/employer/applications/$jobId';

  /// يحافظ على روابط التفاصيل القديمة دون إبقائها مسارًا رئيسيًا في الواجهة.
  static String redirectLegacyJobDetails(String jobId) => jobDetails(jobId);

  /// مسار قديم يُحافَظ عليه كرابط متوافق مع الروابط المحفوظة فقط.
  static const legacyEmployerPostJob = '/employer/post-job';

  /// يعيد توجيه رابط النشر القديم إلى المسار المستقل المعتمد.
  static String? redirectLegacyEmployerPostJob(String location) =>
      location == legacyEmployerPostJob ? addJob : null;

  /// يحافظ على روابط طلبات الوظائف السابقة دون اعتمادها كمسار رئيسي.
  static String redirectLegacyEmployerApplications(String jobId) =>
      employerApplications(jobId);
}
