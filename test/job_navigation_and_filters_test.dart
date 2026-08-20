import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/core/router/app_routes.dart';
import 'package:ys_job/features/jobs/data/jobs_repository.dart';

void main() {
  group('عقد مسارات استكشاف الوظائف', () {
    test('يبني رابط التفاصيل الجديد من معرّف الوظيفة الحقيقي', () {
      expect(AppRoutes.jobs, '/jobs');
      expect(
        AppRoutes.jobDetails('firestore-job-42'),
        '/job-details/firestore-job-42',
      );
    });

    test('يعيد توجيه رابط التفاصيل القديم إلى الرابط المعتمد', () {
      expect(
        AppRoutes.redirectLegacyJobDetails('firestore-job-42'),
        '/job-details/firestore-job-42',
      );
    });
  });

  group('فلاتر الوظائف الحية', () {
    test('تتعامل مع القيم المتطابقة كفلتر واحد قابل لإعادة الاستخدام', () {
      const first = JobFilters(
        query: 'محاسب',
        jobType: 'عن بُعد',
        location: 'صنعاء',
      );
      const second = JobFilters(
        query: 'محاسب',
        jobType: 'عن بُعد',
        location: 'صنعاء',
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('يفصل بين الفلاتر المختلفة حتى لا تختلط نتائجها', () {
      const remote = JobFilters(jobType: 'عن بُعد');
      const fullTime = JobFilters(jobType: 'كامل');

      expect(remote, isNot(fullTime));
    });
  });
}
