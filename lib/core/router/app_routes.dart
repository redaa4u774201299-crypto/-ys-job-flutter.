/// أسماء المسارات العامة والمحمية التي تعتمدها واجهة YS JOB.
///
/// يجمع هذا العقد نقاط التنقل الخاصة بصاحب العمل لمنع استمرار أي شاشة في
/// استخدام مسار نشر الوظيفة القديم بعد اعتماد المسار المستقل.
abstract final class AppRoutes {
  static const employerDashboard = '/employer-dashboard';
  static const addJob = '/add-job';

  /// مسار قديم يُحافَظ عليه كرابط متوافق مع الروابط المحفوظة فقط.
  static const legacyEmployerPostJob = '/employer/post-job';

  /// يعيد توجيه رابط النشر القديم إلى المسار المستقل المعتمد.
  static String? redirectLegacyEmployerPostJob(String location) =>
      location == legacyEmployerPostJob ? addJob : null;
}
