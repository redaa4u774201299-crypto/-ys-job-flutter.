import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/admin_repository.dart';
import '../widgets/admin_access_gate.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAccessGate(
    builder: (context, admin) {
      final repository = ref.watch(adminRepositoryProvider);
      return Scaffold(
        appBar: AppBar(title: const Text('إدارة المستخدمين')),
        body: StreamBuilder<List<UserModel>>(
          stream: repository.watchUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return _FeedbackState(
                message: 'تعذر جلب المستخدمين من Firestore.',
              );
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final users = snapshot.data!;
            if (users.isEmpty)
              return const _FeedbackState(
                message: 'لا توجد حسابات مسجلة حتى الآن.',
              );
            return LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: const EdgeInsets.all(20),
                child: constraints.maxWidth >= 860
                    ? _UsersTable(
                        users: users,
                        currentAdminId: admin.id,
                        repository: repository,
                      )
                    : _UsersList(
                        users: users,
                        currentAdminId: admin.id,
                        repository: repository,
                      ),
              ),
            );
          },
        ),
      );
    },
  );
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.currentAdminId,
    required this.repository,
  });
  final List<UserModel> users;
  final String currentAdminId;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('الاسم')),
        DataColumn(label: Text('البريد الإلكتروني')),
        DataColumn(label: Text('الدور')),
        DataColumn(label: Text('الحالة')),
        DataColumn(label: Text('إجراء')),
      ],
      rows: users
          .map(
            (user) => DataRow(
              cells: [
                DataCell(Text(user.name)),
                DataCell(Text(user.email)),
                DataCell(_RoleChip(role: user.role)),
                DataCell(_StatusChip(isActive: user.isActive)),
                DataCell(
                  _AccountAction(
                    user: user,
                    currentAdminId: currentAdminId,
                    repository: repository,
                  ),
                ),
              ],
            ),
          )
          .toList(growable: false),
    ),
  );
}

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.currentAdminId,
    required this.repository,
  });
  final List<UserModel> users;
  final String currentAdminId;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: users.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final user = users[index];
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(user.email),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RoleChip(role: user.role),
                  _StatusChip(isActive: user.isActive),
                  _AccountAction(
                    user: user,
                    currentAdminId: currentAdminId,
                    repository: repository,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.user,
    required this.currentAdminId,
    required this.repository,
  });
  final UserModel user;
  final String currentAdminId;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    final canChange = user.id != currentAdminId;
    return OutlinedButton(
      onPressed: canChange ? () => _setActive(context, !user.isActive) : null,
      child: Text(user.isActive ? 'حظر الحساب' : 'إلغاء الحظر'),
    );
  }

  Future<void> _setActive(BuildContext context, bool isActive) async {
    try {
      await repository.setUserActive(userId: user.id, isActive: isActive);
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'تم تفعيل الحساب.' : 'تم حظر الحساب.'),
          ),
        );
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final UserRole role;
  @override
  Widget build(BuildContext context) => Chip(label: Text(role.label));
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});
  final bool isActive;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(isActive ? 'نشط' : 'محظور'),
    backgroundColor: isActive
        ? const Color(0xFFE5F5E9)
        : const Color(0xFFFDE8E8),
    labelStyle: TextStyle(
      color: isActive ? const Color(0xFF19733B) : const Color(0xFFB42318),
    ),
  );
}

class _FeedbackState extends StatelessWidget {
  const _FeedbackState({required this.message});
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
