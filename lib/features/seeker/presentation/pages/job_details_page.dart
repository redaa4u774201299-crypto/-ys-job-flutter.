import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/jobs/data/jobs_repository.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../shared/models/job_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../data/applications_repository.dart';

class JobDetailsPage extends ConsumerWidget {
  const JobDetailsPage({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(firebaseRuntimeProvider).isReady)
      return const Center(child: FirebaseSetupState());
    return StreamBuilder<JobModel?>(
      stream: ref.read(jobsRepositoryProvider).watchJob(jobId),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const _DetailsNotice('تعذر تحميل تفاصيل الوظيفة.');
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final job = snapshot.data;
        if (job == null || !job.isActive)
          return const _DetailsNotice('هذه الوظيفة غير متاحة حاليًا.');
        return _JobDetails(job: job);
      },
    );
  }
}

class _JobDetails extends ConsumerWidget {
  const _JobDetails({required this.job});
  final JobModel job;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: ResponsiveBuilder(
          builder: (context, size) {
            final details = _DetailsBody(job: job);
            final sidebar = _JobSidebar(job: job);
            return size == ResponsiveSize.desktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: details),
                      const SizedBox(width: 24),
                      SizedBox(width: 320, child: sidebar),
                    ],
                  )
                : Column(
                    children: [details, const SizedBox(height: 18), sidebar],
                  );
          },
        ),
      ),
    ),
  );
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.job});
  final JobModel job;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          Text(
            job.employerName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(height: 36),
          Text(
            'الوصف',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(job.description, style: const TextStyle(height: 1.8)),
          if (job.requirements.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'المتطلبات',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(job.requirements, style: const TextStyle(height: 1.8)),
          ],
        ],
      ),
    ),
  );
}

class _JobSidebar extends ConsumerWidget {
  const _JobSidebar({required this.job});
  final JobModel job;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'معلومات الوظيفة',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          _MetaRow(icon: Icons.location_on_outlined, value: job.location),
          _MetaRow(icon: Icons.timer_outlined, value: job.jobType),
          _MetaRow(icon: Icons.payments_outlined, value: job.salaryRange),
          const SizedBox(height: 20),
          _ApplyButton(job: job),
        ],
      ),
    ),
  );
}

class _ApplyButton extends ConsumerWidget {
  const _ApplyButton({required this.job});
  final JobModel job;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('تعذر التحقق من الجلسة.'),
      data: (user) {
        if (user == null)
          return ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('سجل الدخول للتقديم'),
          );
        return StreamBuilder<UserModel?>(
          stream: ref.read(authServiceProvider).watchProfile(user.uid),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;
            if (profile?.role == UserRole.employer)
              return const Text(
                'حسابات أصحاب الشركات لا تتقدم للوظائف.',
                textAlign: TextAlign.center,
              );
            return StreamBuilder<bool>(
              stream: ref
                  .read(applicationsRepositoryProvider)
                  .watchApplicationState(job.id),
              builder: (context, appliedSnapshot) {
                final applied = appliedSnapshot.data == true;
                return ElevatedButton(
                  onPressed: applied
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(applicationsRepositoryProvider)
                                .applyToJob(job);
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم إرسال طلب التقديم.'),
                                ),
                              );
                          } catch (error) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error.toString().replaceFirst(
                                      'Bad state: ',
                                      '',
                                    ),
                                  ),
                                ),
                              );
                          }
                        },
                  child: Text(applied ? 'تم التقديم' : 'قدم الآن'),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 19, color: AppColors.gold),
        const SizedBox(width: 9),
        Expanded(child: Text(value.isEmpty ? 'غير محدد' : value)),
      ],
    ),
  );
}

class _DetailsNotice extends StatelessWidget {
  const _DetailsNotice(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}
