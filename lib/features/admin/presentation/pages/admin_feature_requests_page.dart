import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/feature_request_model.dart';
import '../../data/admin_repository.dart';
import '../widgets/admin_access_gate.dart';

class AdminFeatureRequestsPage extends ConsumerWidget {
  const AdminFeatureRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAccessGate(
    builder: (context, _) {
      final repository = ref.watch(adminRepositoryProvider);
      return Scaffold(
        appBar: AppBar(title: const Text('طلبات تمييز الوظائف')),
        body: StreamBuilder<List<FeatureRequestModel>>(
          stream: repository.watchPendingFeatureRequests(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('تعذر تحميل طلبات التمييز من Firestore.'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final requests = snapshot.data!;
            if (requests.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد طلبات تمييز قيد المراجعة حاليًا.'),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _FeatureRequestCard(
                request: requests[index],
                repository: repository,
              ),
            );
          },
        ),
      );
    },
  );
}

class _FeatureRequestCard extends StatelessWidget {
  const _FeatureRequestCard({required this.request, required this.repository});

  final FeatureRequestModel request;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'طلب للوظيفة: ${request.jobId}',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text('معرف صاحب الشركة: ${request.employerId}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _run(
                  context,
                  () => repository.approveFeatureRequest(request.id),
                  'تم اعتماد الطلب وتمييز الوظيفة.',
                ),
                child: const Text('اعتماد'),
              ),
              OutlinedButton(
                onPressed: () => _run(
                  context,
                  () => repository.rejectFeatureRequest(request.id),
                  'تم رفض طلب التمييز.',
                ),
                child: const Text('رفض'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}
