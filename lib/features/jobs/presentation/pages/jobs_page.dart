import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key, this.query});

  final String? query;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query?.isNotEmpty == true;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.work_outline,
                    color: AppColors.gold,
                    size: 46,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasQuery ? 'نتائج البحث عن «$query»' : 'الوظائف',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ستظهر هنا الوظائف المنشورة فعلًا بعد ربط Firestore وإكمال إعداد Firebase. لا توجد بيانات تجريبية في هذا المشروع.',
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('العودة للرئيسية'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
