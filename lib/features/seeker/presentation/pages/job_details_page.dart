import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/jobs/presentation/jobs_providers.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../shared/models/job_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/base64_thumbnail_avatar.dart';
import '../../data/applications_repository.dart';
import '../application_submission_state.dart';
import '../job_share_service.dart';

class JobDetailsPage extends ConsumerWidget {
  const JobDetailsPage({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(firebaseRuntimeProvider).isReady)
      return const Center(child: FirebaseSetupState());
    final jobState = ref.watch(jobDetailsProvider(jobId));
    return jobState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _DetailsNotice(
        'تعذر تحميل تفاصيل الوظيفة.',
        onRetry: () => ref.invalidate(jobDetailsProvider(jobId)),
      ),
      data: (job) {
        if (job == null || !job.isActive) {
          return const _DetailsNotice('هذه الوظيفة غير متاحة حاليًا.');
        }
        return _JobDetails(job: job);
      },
    );
  }
}

class _JobDetails extends ConsumerWidget {
  const _JobDetails({required this.job});
  final JobModel job;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('تفاصيل الوظيفة'),
      actions: [_ShareJobButton(job: job)],
    ),
    body: SingleChildScrollView(
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
    ),
  );
}

class _ShareJobButton extends StatelessWidget {
  const _ShareJobButton({required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'مشاركة الوظيفة',
    icon: const Icon(Icons.share_outlined),
    onPressed: () async {
      try {
        final result = await const JobShareService().share(job);
        if (!context.mounted) return;
        final message = result == JobShareResult.copiedToClipboard
            ? 'تم نسخ رابط الوظيفة إلى الحافظة.'
            : 'فُتحت خيارات مشاركة الوظيفة.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذرت مشاركة الوظيفة. حاول مجددًا.')),
        );
      }
    },
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Base64ThumbnailAvatar(
                encoded: job.employerLogoThumbBase64,
                fallbackLabel: job.employerName,
                radius: 31,
                fallbackIcon: Icons.business_outlined,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.navy,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      job.employerName.isEmpty
                          ? 'جهة العمل غير محددة'
                          : job.employerName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
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
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            value: 'نُشرت في ${_formatPostedAt(job.postedAt)}',
          ),
          const SizedBox(height: 20),
          _ApplyButton(job: job),
        ],
      ),
    ),
  );

  String _formatPostedAt(DateTime postedAt) {
    final day = postedAt.day.toString().padLeft(2, '0');
    final month = postedAt.month.toString().padLeft(2, '0');
    return '$day/$month/${postedAt.year}';
  }
}

class _ApplyButton extends ConsumerStatefulWidget {
  const _ApplyButton({required this.job});
  final JobModel job;

  @override
  ConsumerState<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends ConsumerState<_ApplyButton> {
  bool _isSubmitting = false;
  bool _isAppliedLocally = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('تعذر التحقق من الجلسة.'),
      data: (user) {
        if (user == null)
          return ElevatedButton(
            onPressed: () =>
                context.go(AppRoutes.loginForJobDetails(widget.job.id)),
            child: const Text('سجل الدخول للتقديم'),
          );
        return StreamBuilder<UserModel?>(
          stream: ref.read(authServiceProvider).watchProfile(user.uid),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;
            if (profileSnapshot.hasError) {
              return const Text(
                'تعذر التحقق من صلاحية حسابك للتقديم.',
                textAlign: TextAlign.center,
              );
            }
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (profile == null || !profile.isActive) {
              return const Text(
                'يتطلب التقديم حساب باحث عن عمل نشطًا.',
                textAlign: TextAlign.center,
              );
            }
            if (profile.role != UserRole.seeker) {
              return const Text(
                'التقديم متاح لحسابات الباحثين عن عمل فقط.',
                textAlign: TextAlign.center,
              );
            }
            return StreamBuilder<bool>(
              stream: ref
                  .read(applicationsRepositoryProvider)
                  .watchApplicationState(widget.job.id),
              builder: (context, appliedSnapshot) {
                final submission = ApplicationSubmissionState(
                  isSubmitting: _isSubmitting,
                  isApplied: _isAppliedLocally || appliedSnapshot.data == true,
                );
                return ElevatedButton(
                  onPressed: submission.isDisabled ? null : _confirmAndApply,
                  child: submission.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(submission.label),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndApply() async {
    final confirmed = await showApplyConfirmationDialog(context, widget.job);
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(applicationsRepositoryProvider).applyToJob(widget.job);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isAppliedLocally = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب التقديم بنجاح.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }
}

Future<bool> showApplyConfirmationDialog(
  BuildContext context,
  JobModel job,
) async {
  final employer = job.employerName.trim().isEmpty
      ? 'هذه الوظيفة'
      : 'وظيفة لدى ${job.employerName.trim()}';
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.assignment_turned_in_outlined),
          title: const Text('تأكيد التقديم'),
          content: Text(
            'هل تريد إرسال طلب التقديم إلى $employer بعنوان «${job.title}»؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('تأكيد التقديم'),
            ),
          ],
        ),
      ) ??
      false;
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
  const _DetailsNotice(this.message, {this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    ),
  );
}
