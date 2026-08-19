import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class EmployerDashboardPage extends StatelessWidget {
  const EmployerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => Center(
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
                  Icons.business_center_outlined,
                  color: AppColors.gold,
                  size: 46,
                ),
                const SizedBox(height: 16),
                Text(
                  'لوحة صاحب الشركة',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const Text(
                  'سيظهر هنا نشر الوظائف وإدارة المتقدمين بعد ربط صلاحيات الشركة والبيانات الحقيقية في Firestore.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
