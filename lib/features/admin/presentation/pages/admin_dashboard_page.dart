import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';
import '../widgets/admin_access_gate.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAccessGate(
    builder: (context, admin) {
      final repository = ref.watch(adminRepositoryProvider);
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
                Text(
                  'مرحبًا ${admin.name}. المؤشرات التالية تُحدّث مباشرةً من بيانات المنصة.',
                ),
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
                      title: 'إجمالي الوظائف',
                      icon: Icons.work_outline,
                      stream: repository.watchJobsCount(),
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
                      onPressed: () => context.go('/admin/users'),
                      icon: const Icon(Icons.manage_accounts_outlined),
                      label: const Text('إدارة المستخدمين'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/admin/jobs'),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('مراجعة الوظائف'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/admin/feature-requests'),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('طلبات التمييز'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
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
