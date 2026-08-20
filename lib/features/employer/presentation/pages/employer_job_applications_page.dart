import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../features/seeker/data/applications_repository.dart';
import '../../../../shared/models/application_model.dart';
import '../../../../shared/models/job_model.dart';
import '../../../../shared/models/user_model.dart';
import '../employer_providers.dart';

class EmployerJobApplicationsPage extends ConsumerWidget {
  const EmployerJobApplicationsPage({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(firebaseRuntimeProvider);
    if (!runtime.isReady) return const Center(child: FirebaseSetupState());

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const _ApplicationsNotice('تعذر التحقق من جلسة الحساب.'),
      data: (user) {
        if (user == null) {
          return const _ApplicationsNotice(
            'سجّل الدخول بحساب صاحب شركة لعرض المتقدمين.',
          );
        }

        final profileAsync = ref.watch(userProfileProvider(user.uid));
        return profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _ApplicationsNotice('تعذر قراءة ملف الشركة.'),
          data: (profile) {
            if (profile == null ||
                profile.role != UserRole.employer ||
                !profile.isActive) {
              return const _ApplicationsNotice(
                'هذه الصفحة متاحة لحسابات أصحاب الشركات النشطة فقط.',
              );
            }

            final jobsAsync = ref.watch(employerJobsProvider(profile.id));
            return jobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const _ApplicationsNotice('تعذر التحقق من ملكية الوظيفة.'),
              data: (jobs) {
                final job = jobs
                    .where((candidate) => candidate.id == jobId)
                    .firstOrNull;
                if (job == null) {
                  return const _ApplicationsNotice(
                    'لا تتوفر هذه الوظيفة ضمن حساب الشركة الحالي.',
                  );
                }

                final applicationsAsync = ref.watch(
                  employerJobApplicationsProvider(jobId),
                );
                return applicationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ApplicationsNotice('$error'),
                  data: (applications) =>
                      _ApplicationsView(job: job, applications: applications),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ApplicationsView extends ConsumerWidget {
  const _ApplicationsView({required this.job, required this.applications});

  final JobModel job;
  final List<EmployerApplicationRecord> applications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/employer-dashboard'),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('العودة إلى لوحة الشركة'),
              ),
              const SizedBox(height: 12),
              Text(
                'إدارة طلبات التقديم',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text('الوظيفة: ${job.title}'),
              const SizedBox(height: 22),
              if (applications.isEmpty)
                const _ApplicationsNotice(
                  'لم يصل أي طلب تقديم لهذه الوظيفة حتى الآن.',
                )
              else
                ...applications.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ApplicantCard(record: record),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicantCard extends ConsumerWidget {
  const _ApplicantCard({required this.record});

  final EmployerApplicationRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final application = record.application;
    final seeker = record.seeker;
    final seekerName = seeker?.name.trim().isNotEmpty == true
        ? seeker!.name
        : 'باحث عن عمل';
    final seekerEmail = seeker?.email.trim().isNotEmpty == true
        ? seeker!.email
        : 'بيانات البريد غير متاحة';
    final cvUrl = seeker?.cvUrl.trim() ?? '';
    final imageProvider = _base64ImageProvider(seeker?.imageBase64 ?? '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seekerName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(seekerEmail),
                      if (seeker?.jobTitle.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          seeker!.jobTitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 4),
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
            const SizedBox(height: 16),
            if (cvUrl.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: () => _openResume(context, cvUrl),
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('فتح رابط السيرة الذاتية'),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<ApplicationStatus>(
              initialValue: application.status,
              decoration: const InputDecoration(
                labelText: 'تحديث حالة الطلب',
                border: OutlineInputBorder(),
              ),
              items: ApplicationStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.arabicLabel),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (status) async {
                if (status == null || status == application.status) return;
                try {
                  await ref
                      .read(applicationsRepositoryProvider)
                      .updateApplicationStatus(
                        applicationId: application.id,
                        status: status,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث حالة الطلب بنجاح.'),
                      ),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('$error')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openResume(BuildContext context, String cvUrl) async {
    final uri = Uri.tryParse(cvUrl);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط السيرة الذاتية غير صالح.')),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط السيرة الذاتية.')),
      );
    }
  }

  ImageProvider<Object>? _base64ImageProvider(String encoded) {
    if (encoded.trim().isEmpty) return null;
    try {
      final bytes = base64Decode(encoded);
      return bytes.isEmpty ? null : MemoryImage(bytes);
    } on FormatException {
      return null;
    }
  }
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

class _ApplicationsNotice extends StatelessWidget {
  const _ApplicationsNotice(this.message);

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
