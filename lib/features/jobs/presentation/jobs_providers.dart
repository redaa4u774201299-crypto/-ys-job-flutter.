import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/jobs_repository.dart';
import '../../../shared/models/job_model.dart';

class PaginatedJobsState {
  const PaginatedJobsState({
    this.jobs = const [],
    this.lastDocument,
    this.isLoadingInitial = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<JobModel> jobs;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  /// حالة تحميل الدفعة الأولى التي تقود واجهة نتائج البحث.
  /// تبقى منفصلة عن [isLoadingMore] حتى لا تُخفي النتائج أثناء التمرير.
  bool get isLoading => isLoadingInitial;

  PaginatedJobsState copyWith({
    List<JobModel>? jobs,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) => PaginatedJobsState(
    jobs: jobs ?? this.jobs,
    lastDocument: lastDocument ?? this.lastDocument,
    isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: error,
  );
}

class JobsPaginationController extends StateNotifier<PaginatedJobsState> {
  JobsPaginationController(this._repository, this._filters)
    : super(const PaginatedJobsState()) {
    loadInitial();
  }

  final JobsRepository _repository;
  final JobFilters _filters;

  Future<void> loadInitial() async {
    state = const PaginatedJobsState();
    try {
      final page = await _repository.searchJobs(_filters);
      state = PaginatedJobsState(
        jobs: page.jobs,
        lastDocument: page.lastDocument,
        isLoadingInitial: false,
        hasMore: page.hasMore,
      );
    } catch (error) {
      state = PaginatedJobsState(isLoadingInitial: false, error: error);
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current.isLoadingInitial ||
        current.isLoadingMore ||
        !current.hasMore ||
        current.lastDocument == null) {
      return;
    }

    state = current.copyWith(isLoadingMore: true);
    try {
      final page = await _repository.searchJobs(
        _filters,
        startAfterDocument: current.lastDocument,
      );
      state = PaginatedJobsState(
        jobs: [...current.jobs, ...page.jobs],
        lastDocument: page.lastDocument ?? current.lastDocument,
        isLoadingInitial: false,
        hasMore: page.hasMore,
      );
    } catch (error) {
      state = current.copyWith(isLoadingMore: false, error: error);
    }
  }
}

/// دفعة الصفحة الرئيسية المحدودة؛ تبقى مستقلة عن حالة تمرير صفحة الاستكشاف.
final availableJobsProvider = FutureProvider.autoDispose
    .family<List<JobModel>, JobFilters>((ref, filters) async {
      final page = await ref.watch(jobsRepositoryProvider).searchJobs(filters);
      return page.jobs;
    });

/// ينشئ حالة مستقلة لكل مجموعة فلاتر، ويحمل الدفعة التالية فقط عند طلب الواجهة.
final paginatedJobsProvider = StateNotifierProvider.autoDispose
    .family<JobsPaginationController, PaginatedJobsState, JobFilters>((
      ref,
      filters,
    ) {
      return JobsPaginationController(
        ref.watch(jobsRepositoryProvider),
        filters,
      );
    });

/// يفضّل نتيجة موجودة أصلًا في ذاكرة جلسة التطبيق، ثم يقرأ Firestore عند
/// فتح رابط مباشر أو إعادة تحميل صفحة الويب. بذلك لا تتضاعف قراءة المستند
/// لمجرد الانتقال من بطاقة وظيفة إلى تفاصيلها.
final jobDetailsProvider = FutureProvider.autoDispose.family<JobModel?, String>(
  (ref, jobId) {
    final repository = ref.watch(jobsRepositoryProvider);
    final cachedJob = repository.findCachedJob(jobId);
    return cachedJob == null
        ? repository.getJob(jobId)
        : Future<JobModel?>.value(cachedJob);
  },
);
