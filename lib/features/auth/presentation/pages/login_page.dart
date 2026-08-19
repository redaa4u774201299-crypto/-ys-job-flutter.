import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppColors.gold,
                    size: 44,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'تسجيل الدخول',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'سيُفعّل تسجيل الدخول بعد ربط Firebase Authentication وتهيئة إعدادات المشروع الحقيقية.',
                  ),
                  const SizedBox(height: 20),
                  const TextField(
                    decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(labelText: 'كلمة المرور'),
                    enabled: false,
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null,
                      child: Text('يتطلب إعداد Firebase'),
                    ),
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
