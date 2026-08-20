import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_service.dart';
import '../../../shared/models/user_model.dart';
import 'widgets/admin_access_gate.dart';

class AdminLayout extends ConsumerWidget {
  const AdminLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAccessGate(
    builder: (context, admin) => LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;
        final navigation = _AdminNavigation(admin: admin, compact: !isDesktop);
        return Scaffold(
          appBar: AppBar(
            title: const Text('إدارة YS JOB'),
            actions: [
              if (!isDesktop)
                Builder(
                  builder: (scaffoldContext) => IconButton(
                    tooltip: 'قائمة الإدارة',
                    onPressed: () =>
                        Scaffold.of(scaffoldContext).openEndDrawer(),
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ),
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: () => _signOut(context, ref),
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          endDrawer: isDesktop
              ? null
              : Drawer(child: SafeArea(child: navigation)),
          body: isDesktop
              ? Row(
                  children: [
                    Expanded(child: child),
                    SizedBox(width: 250, child: Material(child: navigation)),
                  ],
                )
              : child,
        );
      },
    ),
  );

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) context.go(AppRoutes.home);
  }
}

class _AdminNavigation extends StatelessWidget {
  const _AdminNavigation({required this.admin, required this.compact});

  final UserModel admin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.gold,
              ),
              const SizedBox(height: 12),
              Text(
                admin.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'حساب مدير نشط',
                style: TextStyle(color: Color(0xFFF5EFE6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _AdminNavItem(
          label: 'نظرة عامة',
          icon: Icons.dashboard_outlined,
          path: AppRoutes.adminDashboard,
          selected: currentPath == AppRoutes.adminDashboard,
          compact: compact,
        ),
        _AdminNavItem(
          label: 'إدارة المستخدمين',
          icon: Icons.manage_accounts_outlined,
          path: AppRoutes.adminUsers,
          selected: currentPath == AppRoutes.adminUsers,
          compact: compact,
        ),
        _AdminNavItem(
          label: 'مراجعة الوظائف',
          icon: Icons.fact_check_outlined,
          path: AppRoutes.adminJobs,
          selected: currentPath == AppRoutes.adminJobs,
          compact: compact,
        ),
        _AdminNavItem(
          label: 'طلبات التمييز',
          icon: Icons.workspace_premium_outlined,
          path: AppRoutes.adminFeatureRequests,
          selected: currentPath == AppRoutes.adminFeatureRequests,
          compact: compact,
        ),
      ],
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.path,
    required this.selected,
    required this.compact,
  });

  final String label;
  final IconData icon;
  final String path;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListTile(
    selected: selected,
    selectedTileColor: const Color(0x1AD9A441),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: Icon(icon, color: selected ? AppColors.navy : null),
    title: Text(label),
    onTap: () {
      if (compact) Navigator.of(context).pop();
      context.go(path);
    },
  );
}
