import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_model.dart';
import '../../../jobs/presentation/widgets/firebase_setup_state.dart';
import '../../domain/auth_service.dart';
import '../widgets/auth_layout.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _role = UserRole.seeker;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final session = await ref
          .read(authServiceProvider)
          .registerUser(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            role: _role,
          );
      if (mounted) context.go(session.destination);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = authFailureMessage(error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
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
                Icons.person_add_alt_1_outlined,
                color: AppColors.gold,
                size: 44,
              ),
              const SizedBox(height: 18),
              Text(
                'أنشئ حسابك',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (!runtime.isReady)
                FirebaseSetupState(message: runtime.message)
              else ...[
                const Text(
                  'اختر نوع الحساب ثم أدخل بياناتك. سيُحفظ الدور في ملفك داخل Firestore.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                      value: UserRole.seeker,
                      label: Text('باحث عن عمل'),
                      icon: Icon(Icons.person_search_outlined),
                    ),
                    ButtonSegment(
                      value: UserRole.employer,
                      label: Text('صاحب شركة'),
                      icon: Icon(Icons.business_outlined),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: _isBusy
                      ? null
                      : (roles) => setState(() => _role = roles.first),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isBusy,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true
                            ? 'الاسم مطلوب.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isBusy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                        ),
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isBusy,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور',
                        ),
                        validator: _passwordValidator,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        enabled: !_isBusy,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        onFieldSubmitted: (_) => _register(),
                        decoration: const InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                        ),
                        validator: (value) => value != _passwordController.text
                            ? 'كلمتا المرور غير متطابقتين.'
                            : null,
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _isBusy ? null : _register,
                  child: Text(
                    _isBusy ? 'جارٍ إنشاء الحساب...' : 'إنشاء الحساب',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isBusy ? null : () => context.go('/login'),
                  child: const Text('لديك حساب بالفعل؟ سجّل الدخول'),
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
