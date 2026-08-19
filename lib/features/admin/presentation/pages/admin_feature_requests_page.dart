import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        body: StreamBuilder<List<FeatureRequestAdminRow>>(
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
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth < 820
                          ? 820
                          : constraints.maxWidth,
                    ),
                    child: DataTable(
                      columnSpacing: 28,
                      columns: const [
                        DataColumn(label: Text('الشركة')),
                        DataColumn(label: Text('الوظيفة المطلوبة')),
                        DataColumn(label: Text('تاريخ الطلب')),
                        DataColumn(label: Text('الإجراء')),
                      ],
                      rows: requests
                          .map(
                            (row) => DataRow(
                              cells: [
                                DataCell(Text(row.companyName)),
                                DataCell(Text(row.jobTitle)),
                                DataCell(
                                  Text(_formatDate(row.request.requestedAt)),
                                ),
                                DataCell(
                                  _FeatureRequestActions(
                                    row: row,
                                    repository: repository,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year.toString().padLeft(4, '0')}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
}

class _FeatureRequestActions extends StatelessWidget {
  const _FeatureRequestActions({required this.row, required this.repository});

  final FeatureRequestAdminRow row;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ElevatedButton(
        onPressed: row.job == null
            ? null
            : () => _run(
                context,
                () => repository.approveFeatureRequest(row.request.id),
                'تم اعتماد الدفعة وتمييز الوظيفة وإرسال إشعار لصاحب العمل.',
              ),
        child: const Text('اعتماد الدفع وتمييز الوظيفة'),
      ),
      OutlinedButton(
        onPressed: () => _run(
          context,
          () => repository.rejectFeatureRequest(row.request.id),
          'تم رفض طلب التمييز.',
        ),
        child: const Text('رفض'),
      ),
    ],
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
