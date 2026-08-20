import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/core/router/app_routes.dart';

void main() {
  group('عقد مسار إضافة وظيفة لصاحب العمل', () {
    test('يعتمد المسار المستقل لإضافة الوظيفة', () {
      expect(AppRoutes.addJob, '/add-job');
      expect(AppRoutes.employerDashboard, '/employer-dashboard');
    });

    test('يوجه الرابط السابق إلى المسار المستقل فقط', () {
      expect(AppRoutes.legacyEmployerPostJob, '/employer/post-job');
      expect(AppRoutes.legacyEmployerPostJob, isNot(AppRoutes.addJob));
      expect(
        AppRoutes.redirectLegacyEmployerPostJob(
          AppRoutes.legacyEmployerPostJob,
        ),
        AppRoutes.addJob,
      );
      expect(AppRoutes.redirectLegacyEmployerPostJob('/jobs'), isNull);
    });
  });
}
