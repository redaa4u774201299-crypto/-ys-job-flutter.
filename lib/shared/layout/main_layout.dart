import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase/firebase_runtime.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/notifications/data/notifications_repository.dart';
import '../models/notification_model.dart';
import '../responsive/responsive_builder.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key, required this.child});

  final Widget child;
  static const links = <_NavLink>[
    _NavLink('الرئيسية', '/', Icons.home_outlined),
    _NavLink('الوظائف', '/jobs', Icons.work_outline),
    _NavLink('طلباتي', '/seeker-dashboard', Icons.assignment_outlined),
    _NavLink('الشركات', '/companies', Icons.business_outlined),
    _NavLink('حسابي', '/profile', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveBuilder(
      builder: (context, size) {
        final isDesktop = size == ResponsiveSize.desktop;
        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const _Brand(),
                  actions: const [_NotificationsBell()],
                ),
          drawer: isDesktop ? null : const Drawer(child: _MobileNavigation()),
          body: Column(
            children: [
              if (isDesktop) const _DesktopNavigation(),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopNavigation extends ConsumerWidget {
  const _DesktopNavigation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF2))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                const _Brand(),
                const SizedBox(width: 52),
                ...MainLayout.links.map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextButton(
                      onPressed: () => context.go(link.path),
                      child: Text(link.label),
                    ),
                  ),
                ),
                const Spacer(),
                const _NotificationsBell(),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('تسجيل الدخول'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('أضف وظيفة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(firebaseRuntimeProvider);
    if (!runtime.isReady) return const SizedBox.shrink();
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const SizedBox(width: 44),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final repository = ref.read(notificationsRepositoryProvider);
        return StreamBuilder<List<NotificationModel>>(
          stream: repository.watchCurrentUserNotifications(),
          builder: (context, snapshot) {
            final notifications = snapshot.data ?? const <NotificationModel>[];
            final unreadCount = notifications
                .where((notification) => !notification.isRead)
                .length;
            return Badge.count(
              count: unreadCount,
              isLabelVisible: unreadCount > 0,
              alignment: AlignmentDirectional.topStart,
              child: PopupMenuButton<NotificationModel>(
                tooltip: 'الإشعارات',
                icon: const Icon(Icons.notifications_none_outlined),
                onSelected: (notification) async {
                  try {
                    await repository.markAsRead(notification);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$error')));
                    }
                  }
                },
                itemBuilder: (context) {
                  if (snapshot.hasError) {
                    return const [
                      PopupMenuItem<NotificationModel>(
                        enabled: false,
                        child: SizedBox(
                          width: 260,
                          child: Text('تعذر تحميل الإشعارات حاليًا.'),
                        ),
                      ),
                    ];
                  }
                  if (notifications.isEmpty) {
                    return const [
                      PopupMenuItem<NotificationModel>(
                        enabled: false,
                        child: SizedBox(
                          width: 260,
                          child: Text('لا توجد إشعارات جديدة.'),
                        ),
                      ),
                    ];
                  }
                  return notifications
                      .map(
                        (notification) => PopupMenuItem<NotificationModel>(
                          value: notification,
                          child: SizedBox(
                            width: 280,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(padding: EdgeInsets.all(24), child: _Brand()),
          const Divider(height: 1),
          ...MainLayout.links.map(
            (link) => ListTile(
              leading: Icon(link.icon),
              title: Text(link.label),
              onTap: () {
                Navigator.pop(context);
                context.go(link.path);
              },
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login');
              },
              child: const Text('تسجيل الدخول'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w900),
        children: const [
          TextSpan(
            text: 'YS',
            style: TextStyle(color: AppColors.gold),
          ),
          TextSpan(
            text: '.JOB',
            style: TextStyle(color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}

class _NavLink {
  const _NavLink(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;
}
