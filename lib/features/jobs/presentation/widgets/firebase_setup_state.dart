import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class FirebaseSetupState extends StatelessWidget {
  const FirebaseSetupState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.settings_suggest_outlined,
            color: AppColors.gold,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            'إعداد Firebase مطلوب',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'أضف إعدادات مشروع Firebase الحقيقي لعرض بيانات الوظائف والمصادقة.',
          ),
        ],
      ),
    ),
  );
}
