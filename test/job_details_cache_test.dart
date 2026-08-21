import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/jobs/data/job_details_cache.dart';
import 'package:ys_job/shared/models/job_model.dart';

void main() {
  JobModel buildJob({String id = 'job-42', String title = 'محاسب'}) => JobModel(
    id: id,
    employerId: 'employer-1',
    employerName: 'شركة يمنية',
    title: title,
    description: 'وصف وظيفي حقيقي للاختبار.',
    location: 'صنعاء',
    jobType: 'دوام كامل',
    salaryRange: 'حسب الاتفاق',
    isFeatured: false,
    postedAt: DateTime.utc(2026, 8, 21),
  );

  group('ذاكرة تفاصيل الوظائف', () {
    test('تعيد الوظيفة التي حُمّلت في قائمة سابقة بالمعرّف نفسه', () {
      final cache = JobDetailsCache();
      final job = buildJob();

      cache.put(job);

      expect(cache.read('job-42'), same(job));
    });

    test('تحدّث النتيجة عند وصول نسخة أحدث من Firestore', () {
      final cache = JobDetailsCache();
      cache.put(buildJob(title: 'محاسب مبتدئ'));
      final updated = buildJob(title: 'محاسب أول');

      cache.put(updated);

      expect(cache.read('job-42')?.title, 'محاسب أول');
    });

    test('تتجاهل السجلات التي لا تملك معرّف Firestore صالحًا', () {
      final cache = JobDetailsCache();

      cache.put(buildJob(id: '   '));

      expect(cache.read(''), isNull);
    });

    test('تحذف السجل عند تأكيد عدم وجود الوظيفة في Firestore', () {
      final cache = JobDetailsCache();
      cache.put(buildJob());

      cache.remove('job-42');

      expect(cache.read('job-42'), isNull);
    });
  });
}
