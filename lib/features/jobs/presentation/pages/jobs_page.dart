import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../data/jobs_repository.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../widgets/firebase_setup_state.dart';
import '../widgets/job_summary_card.dart';
import '../jobs_providers.dart';

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key, this.query, this.city});
  final String? query;
  final String? city;

  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends ConsumerState<JobsPage> {
  late final TextEditingController _queryController;
  final _locationController = TextEditingController();
  String _jobType = '';

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.query ?? '');
    _locationController.text = widget.city ?? '';
  }

  @override
  void dispose() {
    _queryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  JobFilters get _filters => JobFilters(
    query: _queryController.text,
    jobType: _jobType,
    location: _locationController.text,
  );

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(firebaseRuntimeProvider).isReady) {
      return const Center(child: FirebaseSetupState());
    }
    return ResponsiveBuilder(
      builder: (context, size) => Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: TextField(
            controller: _queryController,
            onChanged: (_) => _refresh(),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'ابحث عن وظيفة أو شركة',
              prefixIcon: Icon(Icons.search),
              filled: true,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _showFilters(context),
              tooltip: 'تصفية الوظائف',
              icon: const Icon(Icons.tune_outlined),
            ),
            ref
                .watch(authStateProvider)
                .when(
                  loading: () => const SizedBox(width: 48),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (user) => IconButton(
                    onPressed: () async {
                      if (user == null) {
                        context.go('/login');
                        return;
                      }
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    tooltip: user == null ? 'تسجيل الدخول' : 'تسجيل الخروج',
                    icon: Icon(user == null ? Icons.login : Icons.logout),
                  ),
                ),
          ],
        ),
        floatingActionButton: size == ResponsiveSize.mobile
            ? FloatingActionButton.extended(
                onPressed: () => _showFilters(context),
                icon: const Icon(Icons.tune),
                label: const Text('تصفية'),
              )
            : null,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تظهر الوظائف النشطة المنشورة فعليًا في Firestore فقط.',
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: size == ResponsiveSize.desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 270,
                                child: _FiltersPanel(
                                  queryController: _queryController,
                                  locationController: _locationController,
                                  jobType: _jobType,
                                  onTypeChanged: (value) =>
                                      setState(() => _jobType = value),
                                  onChanged: _refresh,
                                ),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                child: _PaginatedJobsList(filters: _filters),
                              ),
                            ],
                          )
                        : _PaginatedJobsList(filters: _filters),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: _FiltersPanel(
          queryController: _queryController,
          locationController: _locationController,
          jobType: _jobType,
          onTypeChanged: (value) => setState(() => _jobType = value),
          onChanged: () {
            _refresh();
            Navigator.pop(sheetContext);
          },
        ),
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.queryController,
    required this.locationController,
    required this.jobType,
    required this.onTypeChanged,
    required this.onChanged,
  });

  final TextEditingController queryController;
  final TextEditingController locationController;
  final String jobType;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'البحث والتصفية',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: queryController,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'البحث بالنص',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: jobType,
            decoration: const InputDecoration(labelText: 'نوع العمل'),
            items: const [
              DropdownMenuItem(value: '', child: Text('كل الأنواع')),
              DropdownMenuItem(value: 'كامل', child: Text('دوام كامل')),
              DropdownMenuItem(value: 'جزئي', child: Text('دوام جزئي')),
              DropdownMenuItem(value: 'عن بُعد', child: Text('عن بُعد')),
            ],
            onChanged: (value) {
              onTypeChanged(value ?? '');
              onChanged();
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: locationController,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'الموقع',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () {
              queryController.clear();
              locationController.clear();
              onTypeChanged('');
              onChanged();
            },
            child: const Text('مسح الفلاتر'),
          ),
        ],
      ),
    ),
  );
}

class _PaginatedJobsList extends ConsumerStatefulWidget {
  const _PaginatedJobsList({required this.filters});
  final JobFilters filters;

  @override
  ConsumerState<_PaginatedJobsList> createState() => _PaginatedJobsListState();
}

class _PaginatedJobsListState extends ConsumerState<_PaginatedJobsList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadNextPageIfNeeded);
  }

  @override
  void didUpdateWidget(covariant _PaginatedJobsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPageIfNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadNextPageIfNeeded() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 360) {
      return;
    }
    ref.read(paginatedJobsProvider(widget.filters).notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(paginatedJobsProvider(widget.filters));
    final controller = ref.read(paginatedJobsProvider(widget.filters).notifier);

    if (jobsState.isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (jobsState.error != null && jobsState.jobs.isEmpty) {
      return Center(
        child: FilledButton.tonal(
          onPressed: controller.loadInitial,
          child: const Text('تعذر تحميل الوظائف. حاول مجددًا.'),
        ),
      );
    }
    if (jobsState.jobs.isEmpty) {
      return const Center(
        child: Text('لا توجد وظائف تطابق معايير البحث الحالية.'),
      );
    }

    final footerCount = jobsState.isLoadingMore || jobsState.error != null
        ? 1
        : 0;
    return ListView.separated(
      controller: _scrollController,
      itemCount: jobsState.jobs.length + footerCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == jobsState.jobs.length) {
          if (jobsState.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Center(
            child: TextButton(
              onPressed: controller.loadMore,
              child: const Text('تعذر تحميل المزيد. حاول مجددًا.'),
            ),
          );
        }
        final job = jobsState.jobs[index];
        return JobSummaryCard(
          job: job,
          onTap: () => context.go(AppRoutes.jobDetails(job.id)),
        );
      },
    );
  }
}
