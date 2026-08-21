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

  static const _destinations = <_SeekerDestination>[
    _SeekerDestination(
      label: 'البحث',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      path: AppRoutes.seekerSearch,
    ),
    _SeekerDestination(
      label: 'طلباتي',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      path: AppRoutes.seekerApplications,
    ),
    _SeekerDestination(
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
        final selectedIndex = _selectedIndex(currentPath);
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
          body: isDesktop
              ? Row(
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
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      context.go(_destinations[index].path),
                  destinations: _destinations
                      .map(
                        (destination) => NavigationDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: destination.label,
                        ),
                      )
                      .toList(growable: false),
                ),
        );
      },
    ),
  );

  int _selectedIndex(String currentPath) {
    final index = _destinations.indexWhere(
      (destination) => currentPath == destination.path,
    );
    return index < 0 ? 1 : index;
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) context.go(AppRoutes.home);
  }
}

class _SeekerSidebar extends StatelessWidget {
  const _SeekerSidebar({required this.seekerName, required this.currentPath});

  final String seekerName;
  final String currentPath;

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
      ...SeekerLayout._destinations.map(
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
          onTap: () => context.go(destination.path),
        ),
      ),
    ],
  );
}

class _SeekerDestination {
  const _SeekerDestination({
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
