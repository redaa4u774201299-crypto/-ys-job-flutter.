import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../auth/data/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_model.dart';
import '../../notifications/data/notifications_repository.dart';

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
          const _EmployerNotificationsButton(),
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

class _EmployerNotificationsButton extends ConsumerWidget {
  const _EmployerNotificationsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(notificationsRepositoryProvider);
    return StreamBuilder<int>(
      stream: repository.watchUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return IconButton(
          tooltip: unreadCount == 0
              ? 'الإشعارات'
              : 'لديك $unreadCount إشعارًا غير مقروء',
          onPressed: () => _showNotifications(context, repository),
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }

  Future<void> _showNotifications(
    BuildContext context,
    NotificationsRepository repository,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: StreamBuilder(
          stream: repository.watchCurrentUserNotifications(limit: 20),
          builder: (context, snapshot) {
            final notifications = snapshot.data ?? const [];
            if (notifications.isEmpty) {
              return const SizedBox(
                height: 180,
                child: Center(child: Text('لا توجد إشعارات جديدة حاليًا.')),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: Icon(
                    notification.isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active_outlined,
                  ),
                  title: Text(notification.title),
                  subtitle: Text(notification.message),
                  onTap: () async {
                    await repository.markAsRead(notification);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    if (context.mounted)
                      context.go(AppRoutes.employerDashboard);
                  },
                );
              },
            );
          },
        ),
      ),
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
              path: AppRoutes.employerDashboard,
            ),
            _DrawerLink(
              label: 'إضافة وظيفة جديدة',
              icon: Icons.add_circle_outline,
              path: AppRoutes.addJob,
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
