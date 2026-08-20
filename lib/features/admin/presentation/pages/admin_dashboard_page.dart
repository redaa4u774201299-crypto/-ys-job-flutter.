import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/job_model.dart';
import '../../data/admin_repository.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(adminRepositoryProvider);

    Future<void> confirmDelete(JobModel job) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('حذف الوظيفة'),
          content: Text(
            'سيُحذف إعلان "${job.title}" نهائيًا من المنصة. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      try {
        await repository.deleteJob(job.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الوظيفة بنجاح.')));
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر حذف الوظيفة: $error')));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لوحة الإدارة',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text('المؤشرات التالية تُحدّث مباشرةً من بيانات المنصة.'),
              const SizedBox(height: 26),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _LiveMetric(
                    title: 'إجمالي المستخدمين',
                    icon: Icons.people_outline,
                    stream: repository.watchUsersCount(),
                  ),
                  _LiveMetric(
                    title: 'الوظائف النشطة',
                    icon: Icons.work_outline,
                    stream: repository.watchActiveJobsCount(),
                  ),
                  _LiveMetric(
                    title: 'إجمالي التقديمات',
                    icon: Icons.assignment_outlined,
                    stream: repository.watchApplicationsCount(),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'الإدارة والمراجعة',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.adminUsers),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('إدارة المستخدمين'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.adminJobs),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('مراجعة الوظائف'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.adminFeatureRequests),
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('طلبات التمييز'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _RecentJobsPreview(
                stream: repository.watchJobs(),
                onDelete: confirmDelete,
                onShowAll: () => context.go(AppRoutes.adminJobs),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveMetric extends StatelessWidget {
  const _LiveMetric({
    required this.title,
    required this.icon,
    required this.stream,
  });
  final String title;
  final IconData icon;
  final Stream<int> stream;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 260,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: StreamBuilder<int>(
          stream: stream,
          builder: (context, snapshot) => Row(
            children: [
              Icon(icon, size: 30, color: AppColors.gold),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 5),
                    Text(
                      snapshot.hasError
                          ? 'تعذر الجلب'
                          : '${snapshot.data ?? 0}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.navy,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RecentJobsPreview extends StatelessWidget {
  const _RecentJobsPreview({
    required this.stream,
    required this.onDelete,
    required this.onShowAll,
  });

  final Stream<List<JobModel>> stream;
  final Future<void> Function(JobModel job) onDelete;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: StreamBuilder<List<JobModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('تعذر جلب أحدث الوظائف حاليًا.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data!.take(5).toList(growable: false);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'أحدث الوظائف المنشورة',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    onPressed: onShowAll,
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (jobs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('لا توجد وظائف منشورة بعد.'),
                )
              else
                ...jobs.map(
                  (job) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.beige,
                      child: Icon(Icons.work_outline, color: AppColors.navy),
                    ),
                    title: Text(job.title),
                    subtitle: Text('${job.employerName} • ${job.status.label}'),
                    trailing: IconButton(
                      tooltip: 'حذف الوظيفة',
                      onPressed: () => onDelete(job),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
