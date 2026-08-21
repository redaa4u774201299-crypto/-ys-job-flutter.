import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/shared/models/job_model.dart';
import 'package:ys_job/shared/search/job_search_index.dart';

void main() {
  group('فهرس بحث الوظائف', () {
    test('يوحّد صيغ العربية والمسافات لمفتاح بحث ثابت', () {
      expect(JobSearchIndex.normalize('  مُدير   إدارى  '), 'مدير اداري');
      expect(JobSearchIndex.normalize('شركة  الرّيادة'), 'شركه الرياده');
    });

    test('ينشئ بادئات للعنوان واسم الشركة ضمن سقف محدود', () {
      final terms = JobSearchIndex.buildTerms(
        title: 'محاسب قانوني',
        employerName: 'شركة الريادة',
      );

      expect(terms, containsAll(['م', 'مح', 'محا', 'ق', 'قا', 'ش', 'شر']));
      expect(terms.length, lessThanOrEqualTo(JobSearchIndex.maxTerms));
    });

    test('يخزن فقط مفاتيح عامة مشتقة من العنوان والشركة', () {
      final job = JobModel(
        id: 'job-1',
        employerId: 'employer-1',
        employerName: 'شركة الريادة',
        title: 'محاسب',
        description: 'تواصل عبر private@example.com',
        requirements: 'رقم هاتف 777000000',
        jobType: 'دوام كامل',
        salaryRange: 'غير محدد',
        location: 'صنعاء',
        isFeatured: false,
        postedAt: DateTime.utc(2026),
      );

      final data = job.toFirestore();
      final terms = data['searchTerms']! as List<String>;

      expect(data['locationKey'], 'صنعاء');
      expect(terms, contains('مح'));
      expect(terms, contains('شر'));
      expect(terms, isNot(contains('خ')));
      expect(terms, isNot(contains('7')));
    });
  });
}
