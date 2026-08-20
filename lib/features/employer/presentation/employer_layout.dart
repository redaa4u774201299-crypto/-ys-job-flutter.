import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_model.dart';

class EmployerLayout extends ConsumerWidget {
  const EmployerLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final profile = currentUser == null
        ? null
        : ref.watch(userProfileProvider(currentUser.uid)).valueOrNull;
    final companyName = profile?.name.trim().isNotEmpty == true
        ? profile!.name
        : 'حساب الشركة';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لوحة تحكم الشركة',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              companyName,
              style: const TextStyle(
                color: Color(0xFFD8E1EC),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: _EmployerDrawer(companyName: companyName, profile: profile),
      body: child,
    );
  }
}

class _EmployerDrawer extends ConsumerWidget {
  const _EmployerDrawer({required this.companyName, required this.profile});

  final String companyName;
  final UserModel? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    child: Icon(Icons.business_outlined),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (profile?.email.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile!.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFD8E1EC)),
                    ),
                  ],
                ],
              ),
            ),
            _DrawerLink(
              label: 'لوحة التحكم',
              icon: Icons.dashboard_outlined,
              path: '/employer-dashboard',
            ),
            _DrawerLink(
              label: 'إضافة وظيفة جديدة',
              icon: Icons.add_circle_outline,
              path: '/employer/post-job',
            ),
            _DrawerLink(
              label: 'استعراض الوظائف',
              icon: Icons.work_outline,
              path: '/jobs',
            ),
            _DrawerLink(
              label: 'الملف الشخصي',
              icon: Icons.person_outline,
              path: '/profile',
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('تسجيل الخروج'),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  const _DrawerLink({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        context.go(path);
      },
    );
  }
}
