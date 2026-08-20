import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/jobs/data/jobs_repository.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../shared/models/user_model.dart';

class PostJobPage extends ConsumerWidget {
  const PostJobPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(firebaseRuntimeProvider).isReady)
      return const Center(child: FirebaseSetupState());
    return ref
        .watch(authStateProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _PostJobNotice('تعذر التحقق من جلسة الحساب.'),
          data: (user) {
            if (user == null)
              return const _PostJobNotice(
                'سجل الدخول بحساب صاحب شركة لنشر وظيفة.',
              );
            return StreamBuilder<UserModel?>(
              stream: ref.read(authServiceProvider).watchProfile(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final profile = snapshot.data;
                if (profile == null ||
                    profile.role != UserRole.employer ||
                    !profile.isActive) {
                  return const _PostJobNotice(
                    'نشر الوظائف متاح لحسابات أصحاب الشركات فقط.',
                  );
                }
                return const _PostJobForm();
              },
            );
          },
        );
  }
}

class _PostJobForm extends ConsumerStatefulWidget {
  const _PostJobForm();
  @override
  ConsumerState<_PostJobForm> createState() => _PostJobFormState();
}

class _PostJobFormState extends ConsumerState<_PostJobForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _requirements = TextEditingController();
  final _salary = TextEditingController();
  final _location = TextEditingController();
  String _jobType = 'كامل';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _requirements.dispose();
    _salary.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(jobsRepositoryProvider)
          .postJob(
            title: _title.text,
            description: _description.text,
            requirements: _requirements.text,
            jobType: _jobType,
            salaryRange: _salary.text,
            location: _location.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'نُشرت الوظيفة بنجاح، ويمكنك الآن إدارة طلبات التقديم.',
              ),
            ),
          );
        context.go(AppRoutes.employerDashboard);
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'نشر وظيفة جديدة',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 22),
                  _Input(controller: _title, label: 'المسمى الوظيفي'),
                  const SizedBox(height: 14),
                  _Input(controller: _description, label: 'الوصف', maxLines: 5),
                  const SizedBox(height: 14),
                  _Input(
                    controller: _requirements,
                    label: 'المتطلبات',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _jobType,
                    decoration: const InputDecoration(labelText: 'نوع العمل'),
                    items: const [
                      DropdownMenuItem(value: 'كامل', child: Text('دوام كامل')),
                      DropdownMenuItem(value: 'جزئي', child: Text('دوام جزئي')),
                      DropdownMenuItem(
                        value: 'عن بُعد',
                        child: Text('عن بُعد'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _jobType = value ?? _jobType),
                  ),
                  const SizedBox(height: 14),
                  _Input(
                    controller: _salary,
                    label: 'نطاق الراتب (اختياري)',
                    required: false,
                  ),
                  const SizedBox(height: 14),
                  _Input(controller: _location, label: 'الموقع'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: Text(_saving ? 'جارٍ النشر…' : 'نشر الوظيفة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.required = true,
  });
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool required;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label),
    validator: (value) => required && (value == null || value.trim().isEmpty)
        ? '$label مطلوب'
        : null,
  );
}

class _PostJobNotice extends StatelessWidget {
  const _PostJobNotice(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
