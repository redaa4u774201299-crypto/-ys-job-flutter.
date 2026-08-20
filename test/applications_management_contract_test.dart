import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/core/router/app_routes.dart';
import 'package:ys_job/features/seeker/presentation/seeker_dashboard_stats.dart';
import 'package:ys_job/shared/models/application_model.dart';

ApplicationModel _application(String id, ApplicationStatus status) =>
    ApplicationModel(
      id: id,
      jobId: 'job-$id',
      seekerId: 'seeker-1',
      employerId: 'employer-1',
      status: status,
      appliedAt: DateTime.utc(2026, 8, 20),
    );

void main() {
  group('مسارات إدارة طلبات التقديم', () {
    test('يبني رابط الشركة لمسار إدارة طلبات الوظيفة', () {
      expect(
        AppRoutes.employerApplications('job-42'),
        '/employer/applications/job-42',
      );
    });

    test('يعيد توجيه الرابط القديم إلى المسار المعتمد', () {
      expect(
        AppRoutes.redirectLegacyEmployerApplications('job-42'),
        '/employer/applications/job-42',
      );
    });

    test('يثبت مسار لوحة الباحث المستقل', () {
      expect(AppRoutes.seekerDashboard, '/seeker-dashboard');
    });
  });

  test('تحسب لوحة الباحث حالات الطلبات من بيانات فعلية', () {
    final stats = SeekerDashboardStats.fromApplications([
      _application('1', ApplicationStatus.pending),
      _application('2', ApplicationStatus.viewed),
      _application('3', ApplicationStatus.interview),
      _application('4', ApplicationStatus.accepted),
      _application('5', ApplicationStatus.rejected),
    ]);

    expect(stats.total, 5);
    expect(stats.inProgress, 3);
    expect(stats.accepted, 1);
  });

  test('تبقى حالات الشركة القابلة للتحديث ممثلة بتسميات عربية', () {
    expect(ApplicationStatus.pending.arabicLabel, 'قيد المراجعة');
    expect(ApplicationStatus.accepted.arabicLabel, 'تم القبول');
    expect(ApplicationStatus.rejected.arabicLabel, 'لم يتم القبول');
  });
}
