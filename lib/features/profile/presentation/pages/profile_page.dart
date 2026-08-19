import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/profile_repository.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  String? _loadedProfileId;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _loadProfile(UserModel profile) {
    if (_loadedProfileId == profile.id) return;
    _loadedProfileId = profile.id;
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _skillsController.text = profile.skills.join(', ');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final skills = _skillsController.text.split(',');
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            name: _nameController.text,
            bio: _bioController.text,
            skills: skills,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بيانات الملف الشخصي.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(profileRepositoryProvider).uploadResume(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع السيرة الذاتية بنجاح.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(firebaseRuntimeProvider).isReady) {
      return const Center(child: FirebaseSetupState());
    }
    return ref
        .watch(authStateProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _ProfileNotice('تعذر التحقق من جلسة الحساب.'),
          data: (user) {
            if (user == null)
              return const _ProfileNotice('سجل الدخول لإدارة ملفك الشخصي.');
            return StreamBuilder<UserModel?>(
              stream: ref.read(authServiceProvider).watchProfile(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final profile = snapshot.data;
                if (profile == null)
                  return const _ProfileNotice(
                    'تعذر العثور على ملف المستخدم في Firestore.',
                  );
                _loadProfile(profile);
                return _ProfileForm(
                  formKey: _formKey,
                  profile: profile,
                  nameController: _nameController,
                  bioController: _bioController,
                  skillsController: _skillsController,
                  saving: _saving,
                  uploading: _uploading,
                  onSave: _save,
                  onUpload: _pickAndUploadResume,
                );
              },
            );
          },
        );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.formKey,
    required this.profile,
    required this.nameController,
    required this.bioController,
    required this.skillsController,
    required this.saving,
    required this.uploading,
    required this.onSave,
    required this.onUpload,
  });
  final GlobalKey<FormState> formKey;
  final UserModel profile;
  final TextEditingController nameController;
  final TextEditingController bioController;
  final TextEditingController skillsController;
  final bool saving;
  final bool uploading;
  final VoidCallback onSave;
  final VoidCallback onUpload;

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
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ملفي الشخصي',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.role == UserRole.employer
                        ? 'حساب صاحب شركة'
                        : 'حساب باحث عن عمل',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'الاسم مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: profile.email,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: bioController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'نبذة مهنية'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: skillsController,
                    decoration: const InputDecoration(
                      labelText: 'المهارات',
                      hintText: 'مثال: Flutter، إدارة مشاريع',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أضف مهارة واحدة على الأقل'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  if (profile.role == UserRole.seeker) ...[
                    Text(
                      'السيرة الذاتية',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.resumeUrl.isEmpty ? 'لم تُرفع سيرة ذاتية بعد.' : 'تم رفع السيرة الذاتية. يمكنك استبدالها بملف PDF جديد.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: uploading ? null : onUpload,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        uploading
                            ? 'جارٍ رفع الملف…'
                            : 'رفع السيرة الذاتية (PDF)',
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  ElevatedButton(
                    onPressed: saving ? null : onSave,
                    child: Text(saving ? 'جارٍ الحفظ…' : 'حفظ التغييرات'),
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

class _ProfileNotice extends StatelessWidget {
  const _ProfileNotice(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
