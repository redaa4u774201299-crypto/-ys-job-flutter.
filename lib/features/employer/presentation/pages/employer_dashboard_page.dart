import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/employer/data/feature_requests_repository.dart';
import '../../../../features/jobs/data/jobs_repository.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../shared/models/job_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../employer_providers.dart';

class EmployerDashboardPage extends ConsumerWidget {
  const EmployerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(firebaseRuntimeProvider);
    if (!runtime.isReady) {
      return const Center(child: FirebaseSetupState());
    }

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _EmployerNotice('تعذر التحقق من جلسة الحساب.'),
      data: (user) {
        if (user == null) {
          return const _EmployerNotice(
            'سجل الدخول بحساب صاحب شركة للوصول إلى لوحة التحكم.',
          );
        }

        final profileAsync = ref.watch(userProfileProvider(user.uid));
        return profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _EmployerNotice('تعذر قراءة ملف الشركة.'),
          data: (profile) {
            if (profile?.role != UserRole.employer) {
              return const _EmployerNotice(
                'هذه اللوحة متاحة لحسابات أصحاب الشركات فقط.',
              );
            }
            return _EmployerDashboard(profile: profile!);
          },
        );
      },
    );
  }
}

class _EmployerDashboard extends ConsumerWidget {
  const _EmployerDashboard({required this.profile});

  final UserModel profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(employerJobsProvider(profile.id));
    final applicantsAsync = ref.watch(
      employerApplicantCountProvider(profile.id),
    );

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const _EmployerNotice('تعذر تحميل وظائفك. تحقق من قواعد Firestore.'),
      data: (publishedJobs) {
        final overview = EmployerJobsOverview.fromJobs(publishedJobs);
        final applicantCount = applicantsAsync.when(
          data: (value) => '$value',
          loading: () => '…',
          error: (_, __) => '—',
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveBuilder(
                    builder: (context, size) => Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StatCard(
                          label: 'إجمالي الوظائف',
                          value: '${overview.totalJobs}',
                          icon: Icons.work_outline,
                          width: size == ResponsiveSize.mobile
                              ? double.infinity
                              : 250,
                        ),
                        _StatCard(
                          label: 'إجمالي المتقدمين',
                          value: applicantCount,
                          icon: Icons.groups_outlined,
                          width: size == ResponsiveSize.mobile
                              ? double.infinity
                              : 250,
                        ),
                        _StatCard(
                          label: 'الوظائف النشطة',
                          value: '${overview.activeJobs}',
                          icon: Icons.check_circle_outline,
                          width: size == ResponsiveSize.mobile
                              ? double.infinity
                              : 250,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'وظائفي',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'الوظائف المنشورة من حساب الشركة الحالي.',
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/employer/post-job'),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة وظيفة جديدة'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (publishedJobs.isEmpty)
                    const _EmployerNotice(
                      'لا توجد وظائف منشورة لهذا الحساب حتى الآن.',
                    )
                  else
                    ResponsiveBuilder(
                      builder: (context, size) => size == ResponsiveSize.desktop
                          ? _JobsTable(jobs: publishedJobs)
                          : _JobsCards(jobs: publishedJobs),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _JobsTable extends StatelessWidget {
  const _JobsTable({required this.jobs});

  final List<JobModel> jobs;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('المسمى')),
          DataColumn(label: Text('الموقع')),
          DataColumn(label: Text('النوع')),
          DataColumn(label: Text('تاريخ النشر')),
          DataColumn(label: Text('الحالة')),
          DataColumn(label: Text('إجراء')),
        ],
        rows: jobs
            .map(
              (job) => DataRow(
                cells: [
                  DataCell(Text(job.title)),
                  DataCell(Text(job.location)),
                  DataCell(Text(job.jobType)),
                  DataCell(Text(_formatDate(job.postedAt))),
                  DataCell(_StatusChip(status: job.status)),
                  DataCell(_JobActions(job: job)),
                ],
              ),
            )
            .toList(growable: false),
      ),
    ),
  );
}

class _JobsCards extends StatelessWidget {
  const _JobsCards({required this.jobs});

  final List<JobModel> jobs;

  @override
  Widget build(BuildContext context) => Column(
    children: jobs
        .map(
          (job) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _StatusChip(status: job.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${job.location} · ${job.jobType}'),
                    const SizedBox(height: 4),
                    Text(
                      'نُشرت في ${_formatDate(job.postedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 26),
                    _JobActions(job: job),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList(growable: false),
  );
}

class _JobActions extends ConsumerWidget {
  const _JobActions({required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      OutlinedButton.icon(
        onPressed: () => context.go('/employer/jobs/${job.id}/applications'),
        icon: const Icon(Icons.groups_outlined),
        label: const Text('طلبات التقديم'),
      ),
      TextButton(
        onPressed: () async {
          try {
            await ref
                .read(jobsRepositoryProvider)
                .updateJobStatus(
                  jobId: job.id,
                  status: job.isActive ? JobStatus.closed : JobStatus.active,
                );
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تعذر تحديث حالة الوظيفة.')),
              );
            }
          }
        },
        child: Text(job.isActive ? 'إغلاق' : 'إعادة تفعيل'),
      ),
      if (job.isFeatured)
        const Chip(label: Text('مميزة'))
      else
        OutlinedButton(
          onPressed: () => _requestFeature(context, ref),
          child: const Text('ترقية إلى وظيفة مميزة'),
        ),
    ],
  );

  Future<void> _requestFeature(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ترقية إلى وظيفة مميزة'),
        content: const Text(
          'ستظهر الوظيفة المميزة في مواضع بارزة من نتائج البحث. لإتمام التمييز، '
          'سدّد الرسوم عبر التحويل البنكي أو المحفظة الإلكترونية وفق وسيلة الدفع '
          'المتفق عليها، ثم تواصل مع الإدارة. إرسال الطلب لا يفعّل التمييز تلقائيًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد إرسال الطلب للإدارة'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(featureRequestsRepositoryProvider).requestFeature(job);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أُرسل الطلب للإدارة وهو قيد المراجعة.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.label),
    backgroundColor: switch (status) {
      JobStatus.active => const Color(0xFFE8F5EC),
      JobStatus.closed => const Color(0xFFF2F3F5),
      JobStatus.hidden => const Color(0xFFFFECEB),
    },
    side: BorderSide.none,
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.width,
  });

  final String label;
  final String value;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 30),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(label),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmployerNotice extends StatelessWidget {
  const _EmployerNotice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
