import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/responsive/responsive_builder.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ResponsiveBuilder(
    builder: (context, size) {
      final isDesktop = size == ResponsiveSize.desktop;
      if (!isDesktop) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: child,
                ),
              ),
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: Row(
          children: [
            const Expanded(flex: 5, child: _BrandPanel()),
            Expanded(
              flex: 6,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.navy, AppColors.navySoft],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
    ),
    padding: const EdgeInsets.all(64),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(fontWeight: FontWeight.w900),
            children: const [
              TextSpan(
                text: 'YS',
                style: TextStyle(color: AppColors.gold),
              ),
              TextSpan(
                text: '.JOB',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'فرص مهنية أقرب إليك.',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Text(
          'منصة عربية تجمع الباحثين عن العمل وأصحاب الشركات في تجربة مهنية واضحة وآمنة.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
            height: 1.8,
          ),
        ),
      ],
    ),
  );
}
