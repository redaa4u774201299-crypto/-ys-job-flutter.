import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_service.dart';
import '../../../shared/layout/main_layout.dart';
import 'widgets/seeker_access_gate.dart';

class SeekerLayout extends ConsumerWidget {
  const SeekerLayout({super.key, required this.child});

  final Widget child;

  static const navigationDestinations = <SeekerNavigationDestination>[
    SeekerNavigationDestination(
      label: 'البحث عن وظائف',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      path: AppRoutes.seekerSearch,
    ),
    SeekerNavigationDestination(
      label: 'طلباتي',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      path: AppRoutes.seekerApplications,
    ),
    SeekerNavigationDestination(
      label: 'ملفي الشخصي',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      path: AppRoutes.seekerProfile,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) => SeekerAccessGate(
    builder: (context, seeker) => LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;
        final currentPath = GoRouterState.of(context).uri.path;
        return Scaffold(
          appBar: AppBar(
            title: const Text('مساحة الباحث عن عمل'),
            actions: [
              const NotificationsBell(),
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: () => _signOut(context, ref),
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          drawer: isDesktop
              ? null
              : Drawer(
                  child: SafeArea(
                    child: _SeekerSidebar(
                      seekerName: seeker.name,
                      currentPath: currentPath,
                      closeOnNavigate: true,
                    ),
                  ),
                ),
          body: isDesktop
              ? Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Expanded(child: child),
                    SizedBox(
                      width: 260,
                      child: Material(
                        color: Colors.white,
                        child: _SeekerSidebar(
                          seekerName: seeker.name,
                          currentPath: currentPath,
                        ),
                      ),
                    ),
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

class _SeekerSidebar extends StatelessWidget {
  const _SeekerSidebar({
    required this.seekerName,
    required this.currentPath,
    this.closeOnNavigate = false,
  });

  final String seekerName;
  final String currentPath;
  final bool closeOnNavigate;

  @override
  Widget build(BuildContext context) => ListView(
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
            const Icon(Icons.person_search_outlined, color: AppColors.gold),
            const SizedBox(height: 12),
            Text(
              seekerName,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'باحث عن عمل نشط',
              style: TextStyle(color: Color(0xFFF5EFE6)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      ...SeekerLayout.navigationDestinations.map(
        (destination) => ListTile(
          selected: currentPath == destination.path,
          selectedTileColor: const Color(0x1AD9A441),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            currentPath == destination.path
                ? destination.selectedIcon
                : destination.icon,
            color: currentPath == destination.path ? AppColors.navy : null,
          ),
          title: Text(destination.label),
          onTap: () {
            if (closeOnNavigate) Navigator.of(context).pop();
            context.go(destination.path);
          },
        ),
      ),
    ],
  );
}

class SeekerNavigationDestination {
  const SeekerNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}
