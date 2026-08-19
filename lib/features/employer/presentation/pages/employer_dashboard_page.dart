import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/employer/data/feature_requests_repository.dart';
import '../../../../features/jobs/data/jobs_repository.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../features/seeker/data/applications_repository.dart';
import '../../../../shared/models/job_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/responsive/responsive_builder.dart';

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
        return StreamBuilder<UserModel?>(
          stream: ref.read(authServiceProvider).watchProfile(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final profile = snapshot.data;
            if (profile?.role != UserRole.employer) {
              return const _EmployerNotice(
                'هذه اللوحة متاحة لحسابات أصحاب الشركات فقط.',
              );
            }
            return _EmployerDashboard(profile: profile!, ref: ref);
          },
        );
      },
    );
  }
}

class _EmployerDashboard extends StatelessWidget {
  const _EmployerDashboard({required this.profile, required this.ref});

  final UserModel profile;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.read(jobsRepositoryProvider).watchEmployerJobs(profile.id);
    final applicants = ref
        .read(applicationsRepositoryProvider)
        .watchEmployerApplicantCount(profile.id);
    return StreamBuilder<List<JobModel>>(
      stream: jobs,
      builder: (context, jobsSnapshot) {
        if (jobsSnapshot.hasError)
          return const _EmployerNotice(
            'تعذر تحميل وظائفك. تحقق من قواعد Firestore.',
          );
        if (!jobsSnapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final publishedJobs = jobsSnapshot.data!;
        return StreamBuilder<int>(
          stream: applicants,
          builder: (context, applicantsSnapshot) {
            final applicantCount = applicantsSnapshot.data ?? 0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'لوحة صاحب الشركة',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'إدارة الوظائف المنشورة والمتقدمين لحساب ${profile.name}.',
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/employer/post-job'),
                            icon: const Icon(Icons.add),
                            label: const Text('نشر وظيفة'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      ResponsiveBuilder(
                        builder: (context, size) => Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _StatCard(
                              label: 'إجمالي الوظائف',
                              value: '${publishedJobs.length}',
                              icon: Icons.work_outline,
                              width: size == ResponsiveSize.mobile
                                  ? double.infinity
                                  : 250,
                            ),
                            _StatCard(
                              label: 'إجمالي المتقدمين',
                              value: '$applicantCount',
                              icon: Icons.groups_outlined,
                              width: size == ResponsiveSize.mobile
                                  ? double.infinity
                                  : 250,
                            ),
                            _StatCard(
                              label: 'الوظائف النشطة',
                              value:
                                  '${publishedJobs.where((job) => job.isActive).length}',
                              icon: Icons.check_circle_outline,
                              width: size == ResponsiveSize.mobile
                                  ? double.infinity
                                  : 250,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                      Text(
                        'وظائفي',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 14),
                      if (publishedJobs.isEmpty)
                        const _EmployerNotice(
                          'لا توجد وظائف منشورة لهذا الحساب حتى الآن.',
                        )
                      else
                        ResponsiveBuilder(
                          builder: (context, size) =>
                              size == ResponsiveSize.desktop
                              ? _JobsTable(jobs: publishedJobs, ref: ref)
                              : _JobsCards(jobs: publishedJobs, ref: ref),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _JobsTable extends StatelessWidget {
  const _JobsTable({required this.jobs, required this.ref});
  final List<JobModel> jobs;
  final WidgetRef ref;

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
                  DataCell(_StatusChip(status: job.status)),
                  DataCell(_JobActions(job: job, ref: ref)),
                ],
              ),
            )
            .toList(growable: false),
      ),
    ),
  );
}

class _JobsCards extends StatelessWidget {
  const _JobsCards({required this.jobs, required this.ref});
  final List<JobModel> jobs;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => Column(
    children: jobs
        .map(
          (job) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                title: Text(
                  job.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${job.location} · ${job.jobType}'),
                trailing: Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusChip(status: job.status),
                    _JobActions(job: job, ref: ref),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList(growable: false),
  );
}

class _JobActions extends StatelessWidget {
  const _JobActions({required this.job, required this.ref});
  final JobModel job;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
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
          onPressed: () => _requestFeature(context),
          child: const Text('ترقية إلى وظيفة مميزة'),
        ),
    ],
  );

  Future<void> _requestFeature(BuildContext context) async {
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
    label: Text(status == JobStatus.active ? 'نشطة' : 'مغلقة'),
    backgroundColor: status == JobStatus.active
        ? const Color(0xFFE8F5EC)
        : const Color(0xFFF2F3F5),
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
