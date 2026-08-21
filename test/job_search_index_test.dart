import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/jobs/data/jobs_repository.dart';
import 'package:ys_job/features/jobs/presentation/jobs_providers.dart';
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
      expect(data['createdAt'], isNotNull);
      expect(terms, contains('مح'));
      expect(terms, contains('شر'));
      expect(terms, isNot(contains('خ')));
      expect(terms, isNot(contains('7')));
    });

    test('يحدد عقد الصفحة وجود دفعة تالية عند اكتمال حد 20 وظيفة', () {
      final jobs = List<JobModel>.generate(
        JobsRepository.searchPageSize,
        (index) => JobModel(
          id: 'job-$index',
          employerId: 'employer-1',
          employerName: 'شركة الريادة',
          title: 'محاسب $index',
          description: '',
          requirements: '',
          jobType: 'دوام كامل',
          salaryRange: 'غير محدد',
          location: 'صنعاء',
          isFeatured: false,
          postedAt: DateTime.utc(2026),
        ),
      );

      final fullPage = JobsSearchPage(
        jobs: jobs,
        lastDocument: null,
        hasMore: jobs.length == JobsRepository.searchPageSize,
      );
      final partialPage = JobsSearchPage(
        jobs: jobs.take(3).toList(growable: false),
        lastDocument: null,
        hasMore: false,
      );

      expect(fullPage.hasMore, isTrue);
      expect(partialPage.hasMore, isFalse);
    });

    test('يكشف حالة تحميل الدفعة الأولى عبر متغير منطقي واضح', () {
      const loadingState = PaginatedJobsState();
      const loadedState = PaginatedJobsState(isLoadingInitial: false);

      expect(loadingState.isLoading, isTrue);
      expect(loadedState.isLoading, isFalse);
    });
  });
}
