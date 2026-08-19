import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../responsive/responsive_builder.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.child});

  final Widget child;
  static const links = <_NavLink>[
    _NavLink('الرئيسية', '/', Icons.home_outlined),
    _NavLink('الوظائف', '/jobs', Icons.work_outline),
    _NavLink('الشركات', '/companies', Icons.business_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        final isDesktop = size == ResponsiveSize.desktop;
        return Scaffold(
          appBar: isDesktop ? null : AppBar(title: const _Brand()),
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

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation();

  @override
  Widget build(BuildContext context) {
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
