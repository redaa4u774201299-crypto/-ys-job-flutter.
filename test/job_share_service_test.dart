import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/seeker/presentation/job_share_service.dart';
import 'package:ys_job/shared/models/job_model.dart';

void main() {
  JobModel buildJob({String employerName = 'شركة يمنية'}) => JobModel(
    id: 'job-42',
    employerId: 'employer-1',
    employerName: employerName,
    title: 'مصمم واجهات',
    description: 'وصف اختبار لوظيفة حقيقية البنية.',
    location: 'عدن',
    jobType: 'عن بُعد',
    salaryRange: 'حسب الاتفاق',
    isFeatured: false,
    postedAt: DateTime.utc(2026, 8, 21),
  );

  group('رسالة مشاركة الوظيفة للهاتف', () {
    test('تحتوي على المسمى وجهة العمل واسم المنصة', () {
      final text = nativeJobShareText(buildJob());

      expect(text, contains('مصمم واجهات'));
      expect(text, contains('شركة يمنية'));
      expect(text, contains('YS.JOB'));
    });

    test('لا تترك اسم جهة العمل فارغًا في رسالة المشاركة', () {
      final text = nativeJobShareText(buildJob(employerName: '  '));

      expect(text, contains('جهة عمل على منصة YS.JOB'));
    });
  });
}
