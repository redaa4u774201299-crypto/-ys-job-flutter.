import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../jobs/presentation/widgets/firebase_setup_state.dart';
import '../../domain/auth_service.dart';
import '../widgets/auth_layout.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBusy = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final session = await ref
          .read(authServiceProvider)
          .loginUser(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) {
        context.go(
          destinationAfterLogin(
            session.profile.role,
            returnTo: _returnToJobDetails(),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = authFailureMessage(error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final session = await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) {
        context.go(
          destinationAfterLogin(
            session.profile.role,
            returnTo: _returnToJobDetails(),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = authFailureMessage(error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String? _returnToJobDetails() =>
      GoRouterState.of(context).uri.queryParameters['returnTo'];

  Future<void> _showPasswordResetDialog() async {
    final resetFormKey = GlobalKey<FormState>();
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    var isSubmitting = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              icon: const Icon(Icons.mark_email_read_outlined),
              title: const Text('استعادة كلمة المرور'),
              content: Form(
                key: resetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'أدخل بريدك الإلكتروني وسنرسل لك رابطًا آمنًا لتعيين كلمة مرور جديدة.',
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: resetEmailController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.alternate_email_outlined),
                      ),
                      validator: _emailValidator,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!resetFormKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await ref
                                .read(authServiceProvider)
                                .sendPasswordResetEmail(
                                  resetEmailController.text,
                                );
                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'إذا كان البريد مرتبطًا بحساب، فستصل إليه رسالة الاستعادة قريبًا.',
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(authFailureMessage(error)),
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: const Text('إرسال الرابط'),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      resetEmailController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ref.watch(firebaseRuntimeProvider);
    return AuthLayout(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_outline,
                color: AppColors.gold,
                size: 44,
                semanticLabel: 'تسجيل الدخول الآمن',
              ),
              const SizedBox(height: 18),
              Text(
                'تسجيل الدخول',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (!runtime.isReady)
                FirebaseSetupState(message: runtime.message)
              else ...[
                const Text(
                  'سجّل دخولك للوصول إلى مزايا YS.JOB. تُحفظ الجلسة على هذا المتصفح عبر Firebase Auth.',
                ),
                const SizedBox(height: 20),
                AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isBusy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.alternate_email_outlined),
                          ),
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isBusy,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'إظهار كلمة المرور'
                                  : 'إخفاء كلمة المرور',
                              onPressed: _isBusy
                                  ? null
                                  : () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _passwordValidator,
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: _isBusy
                                ? null
                                : _showPasswordResetDialog,
                            child: const Text('نسيت كلمة المرور؟'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _submit,
                    child: _isBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('تسجيل الدخول'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isBusy ? null : () => context.go('/register'),
                  child: const Text('ليس لديك حساب؟ أنشئ حسابًا جديدًا'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _isBusy ? null : _signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text('المتابعة باستخدام Google'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'البريد الإلكتروني مطلوب.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'أدخل بريدًا إلكترونيًا صحيحًا.';
  }
  return null;
}

String? _passwordValidator(String? value) {
  if ((value ?? '').length < 8) {
    return 'كلمة المرور يجب أن تتكون من 8 أحرف على الأقل.';
  }
  return null;
}
