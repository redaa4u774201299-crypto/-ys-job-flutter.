import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/responsive/responsive_builder.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    context.go(
      query.isEmpty ? '/jobs' : '/jobs?q=${Uri.encodeQueryComponent(query)}',
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.beige,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 72,
                ),
                child: ResponsiveBuilder(
                  builder: (context, size) => Column(
                    crossAxisAlignment: size == ResponsiveSize.desktop
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ابحث عن فرصتك القادمة',
                        textAlign: size == ResponsiveSize.desktop
                            ? TextAlign.start
                            : TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.navy,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 650),
                        child: Text(
                          'YS.JOB تجمع الباحثين عن عمل وأصحاب الشركات في منصة عربية واضحة تساعدك على الوصول إلى فرص مناسبة.',
                          textAlign: size == ResponsiveSize.desktop
                              ? TextAlign.start
                              : TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                height: 1.8,
                                color: AppColors.navySoft,
                              ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 740),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _search(),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  hintText: 'ابحث عن المسمى الوظيفي أو المهارة',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _search,
                              child: const Text('ابحث'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const _LatestJobsSection(),
      ],
    ),
  );
}

class _LatestJobsSection extends StatelessWidget {
  const _LatestJobsSection();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أحدث الوظائف',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ستعرض هذه المساحة الوظائف المنشورة فعليًا عند ربط مصدر البيانات وإدخال وظائف معتمدة.',
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Row(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      color: AppColors.gold,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'لا توجد وظائف منشورة بعد. لا يعرض YS.JOB وظائف تجريبية.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/jobs'),
                      child: const Text('عرض الوظائف'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
