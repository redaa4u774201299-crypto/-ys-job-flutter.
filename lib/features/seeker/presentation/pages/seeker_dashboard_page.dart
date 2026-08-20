import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../features/seeker/data/applications_repository.dart';
import '../../../../shared/models/application_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../seeker_dashboard_stats.dart';
import '../seeker_providers.dart';

class SeekerDashboardPage extends ConsumerWidget {
  const SeekerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(firebaseRuntimeProvider);
    if (!runtime.isReady) return const Center(child: FirebaseSetupState());

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _SeekerNotice('تعذر التحقق من جلسة الحساب.'),
      data: (user) {
        if (user == null) {
          return const _SeekerNotice(
            'سجّل الدخول بحساب باحث عن عمل لمتابعة طلباتك.',
          );
        }
        final profileAsync = ref.watch(userProfileProvider(user.uid));
        return profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _SeekerNotice('تعذر قراءة ملف الحساب.'),
          data: (profile) {
            if (profile == null ||
                profile.role != UserRole.seeker ||
                !profile.isActive) {
              return const _SeekerNotice(
                'هذه اللوحة متاحة لحسابات الباحثين عن عمل النشطة فقط.',
              );
            }
            return _SeekerDashboard(profile: profile);
          },
        );
      },
    );
  }
}

class _SeekerDashboard extends ConsumerWidget {
  const _SeekerDashboard({required this.profile});

  final UserModel profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(seekerApplicationsProvider);
    return applicationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _SeekerNotice('$error'),
      data: (records) {
        final stats = SeekerDashboardStats.fromApplications(
          records.map((record) => record.application),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحبًا ${profile.name}',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text('تابع طلباتك وحالة كل فرصة وظيفية من مكان واحد.'),
                  const SizedBox(height: 24),
                  ResponsiveBuilder(
                    builder: (context, size) => Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StatCard(
                          label: 'إجمالي الطلبات',
                          value: '${stats.total}',
                          icon: Icons.description_outlined,
                          width: size == ResponsiveSize.mobile
                              ? double.infinity
                              : 240,
                        ),
                        _StatCard(
                          label: 'قيد المتابعة',
                          value: '${stats.inProgress}',
                          icon: Icons.hourglass_top_outlined,
                          width: size == ResponsiveSize.mobile
                              ? double.infinity
                              : 240,
                        ),
                        _StatCard(
                          label: 'تم قبولها',
                          value: '${stats.accepted}',
                          icon: Icons.check_circle_outline,
                          width: size == ResponsiveSize.mobile
                              ? double.infinity
                              : 240,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'طلباتي',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.jobs),
                        icon: const Icon(Icons.search_outlined),
                        label: const Text('استكشاف الوظائف'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (records.isEmpty)
                    const _SeekerNotice(
                      'لم تقدّم على أي وظيفة بعد. استكشف الفرص المتاحة لتبدأ.',
                    )
                  else
                    ...records.map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SeekerApplicationCard(record: record),
                      ),
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

class _SeekerApplicationCard extends StatelessWidget {
  const _SeekerApplicationCard({required this.record});

  final SeekerApplicationRecord record;

  @override
  Widget build(BuildContext context) {
    final application = record.application;
    final job = record.job;
    final title = job?.title.trim().isNotEmpty == true
        ? job!.title
        : 'وظيفة لم تعد متاحة';
    final employer = job?.employerName.trim().isNotEmpty == true
        ? job!.employerName
        : 'بيانات الشركة غير متاحة';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: job == null
            ? null
            : () => context.go(AppRoutes.jobDetails(job.id)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(child: Icon(Icons.work_outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(employer),
                    const SizedBox(height: 5),
                    Text(
                      'تاريخ التقديم: ${_formatDate(application.appliedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _ApplicationStatusChip(status: application.status),
            ],
          ),
        ),
      ),
    );
  }
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
        padding: const EdgeInsets.all(20),
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

class _ApplicationStatusChip extends StatelessWidget {
  const _ApplicationStatusChip({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.arabicLabel),
    backgroundColor: switch (status) {
      ApplicationStatus.accepted => const Color(0xFFE8F5EC),
      ApplicationStatus.rejected => const Color(0xFFFFECEB),
      ApplicationStatus.interview => const Color(0xFFFFF3DB),
      _ => const Color(0xFFEAF1F8),
    },
    side: BorderSide.none,
  );
}

class _SeekerNotice extends StatelessWidget {
  const _SeekerNotice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(message, textAlign: TextAlign.center),
      ),
    ),
  );
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
