import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/job_model.dart';
import '../../data/admin_repository.dart';
import '../widgets/admin_access_gate.dart';

class AdminJobsPage extends ConsumerWidget {
  const AdminJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAccessGate(
    builder: (context, _) {
      final repository = ref.watch(adminRepositoryProvider);
      return Scaffold(
        appBar: AppBar(title: const Text('مراجعة الوظائف')),
        body: StreamBuilder<List<JobModel>>(
          stream: repository.watchJobs(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const _JobsFeedback(
                message: 'تعذر جلب الوظائف من Firestore.',
              );
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final jobs = snapshot.data!;
            if (jobs.isEmpty)
              return const _JobsFeedback(
                message: 'لا توجد وظائف منشورة للمراجعة حتى الآن.',
              );
            return LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: const EdgeInsets.all(20),
                child: constraints.maxWidth >= 900
                    ? _JobsTable(jobs: jobs, repository: repository)
                    : _JobsList(jobs: jobs, repository: repository),
              ),
            );
          },
        ),
      );
    },
  );
}

class _JobsTable extends StatelessWidget {
  const _JobsTable({required this.jobs, required this.repository});
  final List<JobModel> jobs;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('المسمى')),
        DataColumn(label: Text('الموقع')),
        DataColumn(label: Text('نوع العمل')),
        DataColumn(label: Text('الحالة')),
        DataColumn(label: Text('الإجراءات')),
      ],
      rows: jobs
          .map(
            (job) => DataRow(
              cells: [
                DataCell(Text(job.title)),
                DataCell(Text(job.location)),
                DataCell(Text(job.jobType)),
                DataCell(
                  Wrap(
                    spacing: 5,
                    children: [
                      _JobStatusChip(status: job.status),
                      if (job.isFeatured) const Chip(label: Text('مميزة')),
                    ],
                  ),
                ),
                DataCell(_JobActions(job: job, repository: repository)),
              ],
            ),
          )
          .toList(growable: false),
    ),
  );
}

class _JobsList extends StatelessWidget {
  const _JobsList({required this.jobs, required this.repository});
  final List<JobModel> jobs;
  final AdminRepository repository;
  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: jobs.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final job = jobs[index];
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text('${job.location} · ${job.jobType}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _JobStatusChip(status: job.status),
                  if (job.isFeatured) const Chip(label: Text('مميزة')),
                  _JobActions(job: job, repository: repository),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _JobActions extends StatelessWidget {
  const _JobActions({required this.job, required this.repository});
  final JobModel job;
  final AdminRepository repository;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton(
        onPressed: job.status == JobStatus.hidden
            ? null
            : () => _run(
                context,
                () => repository.hideJob(job.id),
                'تم إخفاء الوظيفة.',
              ),
        child: const Text('إخفاء'),
      ),
      OutlinedButton(
        onPressed: () => _run(
          context,
          () => repository.setJobFeatured(
            jobId: job.id,
            isFeatured: !job.isFeatured,
          ),
          job.isFeatured ? 'تم إلغاء تمييز الوظيفة.' : 'تم تمييز الوظيفة.',
        ),
        child: Text(job.isFeatured ? 'إلغاء التمييز' : 'تمييز'),
      ),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade800),
        onPressed: () => _confirmDelete(context),
        icon: const Icon(Icons.delete_outline),
        label: const Text('حذف'),
      ),
    ],
  );

  Future<void> _confirmDelete(BuildContext context) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الوظيفة؟'),
        content: Text(
          'سيُحذف إعلان "${job.title}" نهائيًا. تبقى سجلات طلبات التقديم محفوظة لأغراض المتابعة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف الوظيفة'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;
    await _run(context, () => repository.deleteJob(job.id), 'تم حذف الوظيفة.');
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _JobStatusChip extends StatelessWidget {
  const _JobStatusChip({required this.status});
  final JobStatus status;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.label),
    backgroundColor: status == JobStatus.active
        ? const Color(0xFFE5F5E9)
        : const Color(0xFFF5EFE6),
  );
}

class _JobsFeedback extends StatelessWidget {
  const _JobsFeedback({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppColors.navy),
      ),
    ),
  );
}
