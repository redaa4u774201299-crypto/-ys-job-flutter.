import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../shared/models/user_model.dart';
import '../profile_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _skillController = TextEditingController();
  String? _loadedProfileId;
  String? _industry;
  List<String> _skills = const [];

  static const _industries = <String>[
    'تقنية المعلومات',
    'التعليم والتدريب',
    'الصحة',
    'المال والمصارف',
    'التجارة والتجزئة',
    'البناء والهندسة',
    'التسويق والإعلام',
    'الخدمات والاستشارات',
    'أخرى',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _loadProfile(UserModel profile) {
    if (_loadedProfileId == profile.id) return;
    _loadedProfileId = profile.id;
    _nameController.text = profile.role == UserRole.employer
        ? (profile.companyName.isNotEmpty ? profile.companyName : profile.name)
        : profile.name;
    _bioController.text = profile.bio;
    _phoneController.text = profile.phone;
    _jobTitleController.text = profile.jobTitle;
    _industry = profile.industry.isEmpty ? null : profile.industry;
    _skills = List<String>.from(profile.skills);
  }

  Future<void> _save(UserModel profile) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final controller = ref.read(profileControllerProvider.notifier);
      if (profile.role == UserRole.employer) {
        await controller.saveEmployerProfile(
          companyName: _nameController.text,
          industry: _industry ?? '',
          bio: _bioController.text,
          phone: _phoneController.text,
        );
      } else {
        await controller.saveSeekerProfile(
          name: _nameController.text,
          bio: _bioController.text,
          skills: _skills,
          phone: _phoneController.text,
          jobTitle: _jobTitleController.text,
        );
      }
      if (mounted) _showSuccess('تم حفظ بيانات الملف الشخصي.');
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _pickAndUploadPhoto(UserModel profile) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null) return;
    try {
      final controller = ref.read(profileControllerProvider.notifier);
      if (profile.role == UserRole.employer) {
        await controller.uploadCompanyLogo(file);
      } else {
        await controller.uploadSeekerPhoto(file);
      }
      if (mounted) {
        _showSuccess(
          profile.role == UserRole.employer
              ? 'تم رفع شعار الشركة بنجاح.'
              : 'تم رفع الصورة الشخصية بنجاح.',
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
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
    try {
      await ref.read(profileControllerProvider.notifier).uploadResume(file);
      if (mounted) _showSuccess('تم رفع السيرة الذاتية بنجاح.');
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isEmpty) return;
    if (_skills.contains(skill)) {
      _showError(const FormatException('هذه المهارة مضافة بالفعل.'));
      return;
    }
    setState(() {
      _skills = [..._skills, skill];
      _skillController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() => _skills = _skills.where((item) => item != skill).toList());
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    final actions = ref.watch(profileControllerProvider);
    return ref
        .watch(authStateProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _ProfileNotice('تعذر التحقق من جلسة الحساب.'),
          data: (user) {
            if (user == null) {
              return const _ProfileNotice('سجل الدخول لإدارة ملفك الشخصي.');
            }
            return StreamBuilder<UserModel?>(
              stream: ref.read(authServiceProvider).watchProfile(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final profile = snapshot.data;
                if (profile == null) {
                  return const _ProfileNotice(
                    'تعذر العثور على ملف المستخدم في Firestore.',
                  );
                }
                if (profile.role == UserRole.admin) {
                  return const _ProfileNotice(
                    'يُدار ملف المشرف من خلال إعدادات النظام.',
                  );
                }
                _loadProfile(profile);
                return _ProfileForm(
                  formKey: _formKey,
                  profile: profile,
                  nameController: _nameController,
                  bioController: _bioController,
                  phoneController: _phoneController,
                  jobTitleController: _jobTitleController,
                  skillController: _skillController,
                  skills: _skills,
                  industries: _industries,
                  industry: _industry,
                  actions: actions,
                  onIndustryChanged: (value) =>
                      setState(() => _industry = value),
                  onAddSkill: _addSkill,
                  onRemoveSkill: _removeSkill,
                  onSave: () => _save(profile),
                  onUploadPhoto: () => _pickAndUploadPhoto(profile),
                  onUploadResume: _pickAndUploadResume,
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
    required this.phoneController,
    required this.jobTitleController,
    required this.skillController,
    required this.skills,
    required this.industries,
    required this.industry,
    required this.actions,
    required this.onIndustryChanged,
    required this.onAddSkill,
    required this.onRemoveSkill,
    required this.onSave,
    required this.onUploadPhoto,
    required this.onUploadResume,
  });

  final GlobalKey<FormState> formKey;
  final UserModel profile;
  final TextEditingController nameController;
  final TextEditingController bioController;
  final TextEditingController phoneController;
  final TextEditingController jobTitleController;
  final TextEditingController skillController;
  final List<String> skills;
  final List<String> industries;
  final String? industry;
  final ProfileActionState actions;
  final ValueChanged<String?> onIndustryChanged;
  final VoidCallback onAddSkill;
  final ValueChanged<String> onRemoveSkill;
  final VoidCallback onSave;
  final VoidCallback onUploadPhoto;
  final VoidCallback onUploadResume;

  bool get _isEmployer => profile.role == UserRole.employer;

  @override
  Widget build(BuildContext context) {
    final image = profile.photoUrl.trim();
    final photoLabel = _isEmployer ? 'شعار الشركة' : 'الصورة الشخصية';
    final imageProvider = image.isNotEmpty ? NetworkImage(image) : null;
    final selectedIndustries = {
      ...industries,
      if (industry != null && !industries.contains(industry)) industry!,
    }.toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEmployer ? 'ملف الشركة' : 'ملفي الشخصي',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isEmployer
                          ? 'حدّث المعلومات التي تظهر للباحثين عن عمل.'
                          : 'حدّث بياناتك المهنية وسيرتك الذاتية.',
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundImage: imageProvider,
                            child: imageProvider == null
                                ? Icon(
                                    _isEmployer
                                        ? Icons.business_rounded
                                        : Icons.person_rounded,
                                    size: 42,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: actions.isUploadingPhoto
                                ? null
                                : onUploadPhoto,
                            icon: actions.isUploadingPhoto
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_outlined),
                            label: Text(
                              actions.isUploadingPhoto
                                  ? 'جارٍ الرفع…'
                                  : 'رفع $photoLabel',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG أو PNG بحد أقصى 2 ميغابايت',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isEmployer) ...[
                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'اسم الشركة',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: industry,
                        decoration: const InputDecoration(
                          labelText: 'مجال العمل',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: selectedIndustries
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: actions.isBusy ? null : onIndustryChanged,
                        validator: (value) => value == null || value.isEmpty
                            ? 'اختر مجال العمل'
                            : null,
                      ),
                    ] else ...[
                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: jobTitleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'المسمى الوظيفي الحالي',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: profile.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: bioController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: _isEmployer
                            ? 'وصف الشركة'
                            : 'النبذة المهنية',
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.notes_outlined),
                      ),
                    ),
                    if (!_isEmployer) ...[
                      const SizedBox(height: 22),
                      Text(
                        'المهارات',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: skillController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onAddSkill(),
                        decoration: InputDecoration(
                          labelText: 'أضف مهارة',
                          hintText: 'مثال: Flutter',
                          prefixIcon: const Icon(Icons.psychology_outlined),
                          suffixIcon: IconButton(
                            tooltip: 'إضافة مهارة',
                            onPressed: actions.isBusy ? null : onAddSkill,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (skills.isEmpty)
                        Text(
                          'أضف المهارات التي تريد إبرازها لأصحاب العمل.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills
                              .map(
                                (skill) => InputChip(
                                  label: Text(skill),
                                  onDeleted: actions.isBusy
                                      ? null
                                      : () => onRemoveSkill(skill),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      const SizedBox(height: 24),
                      _ResumeSection(
                        resumeUrl: profile.resumeUrl,
                        uploading: actions.isUploadingResume,
                        onUpload: onUploadResume,
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: actions.isSaving ? null : onSave,
                      icon: actions.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        actions.isSaving ? 'جارٍ الحفظ…' : 'حفظ التغييرات',
                      ),
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

  static String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null;
}

class _ResumeSection extends StatelessWidget {
  const _ResumeSection({
    required this.resumeUrl,
    required this.uploading,
    required this.onUpload,
  });

  final String resumeUrl;
  final bool uploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السيرة الذاتية',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            resumeUrl.isEmpty
                ? 'لم تُرفع سيرة ذاتية بعد.'
                : 'تم رفع السيرة الذاتية. يمكنك استبدالها بملف PDF أحدث.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: uploading ? null : onUpload,
            icon: uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: Text(
              uploading ? 'جارٍ رفع الملف…' : 'رفع السيرة الذاتية (PDF)',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الحد الأقصى لحجم الملف 5 ميغابايت.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
