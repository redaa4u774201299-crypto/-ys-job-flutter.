import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../shared/models/user_model.dart';

/// يتحقق من أن المستخدم الحالي باحث نشط قبل عرض مساحة الباحث.
bool hasSeekerAccess(UserModel? profile) =>
    profile != null && profile.role == UserRole.seeker && profile.isActive;

class SeekerAccessGate extends ConsumerWidget {
  const SeekerAccessGate({super.key, required this.builder});

  final Widget Function(BuildContext context, UserModel seeker) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(firebaseRuntimeProvider);
    if (!runtime.isReady) return const Center(child: FirebaseSetupState());

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _SeekerAccessNotice(
        message: 'تعذر التحقق من جلسة الحساب حاليًا.',
      ),
      data: (user) {
        if (user == null) {
          return const _SeekerAccessNotice(
            message: 'سجّل الدخول بحساب باحث عن عمل لفتح هذه المساحة.',
            showLoginAction: true,
          );
        }
        final profileAsync = ref.watch(userProfileProvider(user.uid));
        return profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _SeekerAccessNotice(
            message: 'تعذر قراءة ملف الحساب حاليًا.',
          ),
          data: (profile) {
            if (!hasSeekerAccess(profile)) {
              return const _SeekerAccessNotice(
                message:
                    'هذه المساحة متاحة لحسابات الباحثين عن عمل النشطة فقط.',
              );
            }
            return builder(context, profile!);
          },
        );
      },
    );
  }
}

class _SeekerAccessNotice extends StatelessWidget {
  const _SeekerAccessNotice({
    required this.message,
    this.showLoginAction = false,
  });

  final String message;
  final bool showLoginAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_person_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (showLoginAction) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
