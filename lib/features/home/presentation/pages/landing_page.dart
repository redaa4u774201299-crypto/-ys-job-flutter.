import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/firebase/firebase_runtime.dart';
import '../../../jobs/data/jobs_repository.dart';
import '../../../jobs/presentation/jobs_providers.dart';
import '../../../jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../jobs/presentation/widgets/job_summary_card.dart';
import '../../../../shared/responsive/responsive_builder.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});
  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  final _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    context.go(
      query.isEmpty ? '/jobs' : '/jobs?q=${Uri.encodeQueryComponent(query)}',
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.beige,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 72,
                ),
                child: ResponsiveBuilder(
                  builder: (context, size) => Column(
                    crossAxisAlignment: size == ResponsiveSize.desktop
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ابحث عن فرصتك القادمة',
                        textAlign: size == ResponsiveSize.desktop
                            ? TextAlign.start
                            : TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.navy,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 650),
                        child: Text(
                          'YS.JOB تجمع الباحثين عن عمل وأصحاب الشركات في منصة عربية واضحة تساعدك على الوصول إلى فرص مناسبة.',
                          textAlign: size == ResponsiveSize.desktop
                              ? TextAlign.start
                              : TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                height: 1.8,
                                color: AppColors.navySoft,
                              ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 740),
                        child: size == ResponsiveSize.mobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SearchField(
                                    controller: _searchController,
                                    onSearch: _search,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _search,
                                    icon: const Icon(Icons.search),
                                    label: const Text('ابحث عن وظيفة'),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _SearchField(
                                      controller: _searchController,
                                      onSearch: _search,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _search,
                                    icon: const Icon(Icons.search),
                                    label: const Text('ابحث'),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const _LatestJobsSection(),
      ],
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Semantics(
    textField: true,
    label: 'البحث عن وظيفة أو مهارة',
    child: TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSearch(),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'ابحث عن المسمى الوظيفي أو المهارة',
      ),
    ),
  );
}

class _LatestJobsSection extends ConsumerWidget {
  const _LatestJobsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = ref.watch(firebaseRuntimeProvider).isReady;
    final jobsState = isReady
        ? ref.watch(availableJobsProvider(const JobFilters()))
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أحدث الوظائف',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 10),
              const Text('فرص منشورة وفعالة حاليًا على المنصة.'),
              const SizedBox(height: 22),
              if (!isReady)
                const FirebaseSetupState()
              else
                jobsState!.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => _DiscoveryMessage(
                    icon: Icons.cloud_off_outlined,
                    message: 'تعذر تحميل أحدث الوظائف حاليًا.',
                    actionLabel: 'عرض كل الوظائف',
                    onAction: () => context.go('/jobs'),
                  ),
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return _DiscoveryMessage(
                        icon: Icons.work_outline,
                        message: 'لا توجد وظائف منشورة حاليًا.',
                        actionLabel: 'استكشف الوظائف',
                        onAction: () => context.go('/jobs'),
                      );
                    }
                    return Column(
                      children: [
                        ...jobs
                            .take(4)
                            .map(
                              (job) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: JobSummaryCard(
                                  job: job,
                                  onTap: () => context.go(
                                    '/job-details/${Uri.encodeComponent(job.id)}',
                                  ),
                                ),
                              ),
                            ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/jobs'),
                            icon: const Icon(Icons.arrow_back_outlined),
                            label: const Text('عرض كل الوظائف'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryMessage extends StatelessWidget {
  const _DiscoveryMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Icon(icon, color: AppColors.gold, size: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              message,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}
