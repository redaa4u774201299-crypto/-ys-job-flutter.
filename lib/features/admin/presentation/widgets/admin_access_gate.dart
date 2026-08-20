import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../shared/models/user_model.dart';
import '../admin_access_policy.dart';

class AdminAccessGate extends ConsumerWidget {
  const AdminAccessGate({super.key, required this.builder});

  final Widget Function(BuildContext context, UserModel admin) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(firebaseRuntimeProvider);
    if (!runtime.isReady) return const FirebaseSetupState();

    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const _AccessDenied(
            message: 'سجل الدخول بحساب إداري للوصول إلى هذه الصفحة.',
          );
        }
        final profile = ref.watch(userProfileProvider(firebaseUser.uid));
        return profile.when(
          data: (user) {
            if (!hasAdminAccess(user)) {
              return const _AccessDenied(
                message: 'لا تملك صلاحية الوصول إلى لوحة الإدارة.',
              );
            }
            return builder(context, user!);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _AccessDenied(
            message: 'تعذر التحقق من صلاحيات الحساب. حاول تسجيل الدخول مجددًا.',
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const _AccessDenied(message: 'تعذر استعادة جلسة المستخدم.'),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 42,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 16),
                Text(
                  'وصول مقيّد',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('تسجيل الدخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
