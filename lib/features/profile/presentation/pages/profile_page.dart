import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/jobs/presentation/widgets/firebase_setup_state.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/profile_repository.dart';
import '../profile_controller.dart';
import '../widgets/image_crop_dialog.dart';

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
  final _cvUrlController = TextEditingController();
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
    _cvUrlController.dispose();
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
    _cvUrlController.text = profile.cvUrl;
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
          cvUrl: _cvUrlController.text,
        );
      }
      if (mounted) {
        final hasPendingSync = ref
            .read(profileControllerProvider)
            .hasPendingSync;
        _showSuccess(
          hasPendingSync
              ? 'حُفظت التغييرات محليًا وستتزامن عند عودة الإنترنت.'
              : 'تم حفظ بيانات الملف الشخصي.',
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _pickAndSaveImage(UserModel profile) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null) return;
    try {
      ProfileRepository.validateImageFile(file);
      final sourceBytes = file.bytes;
      if (sourceBytes == null || sourceBytes.isEmpty) {
        throw const FormatException('تعذر قراءة الصورة المختارة.');
      }
      if (!mounted) return;
      final photoLabel = profile.role == UserRole.employer
          ? 'شعار الشركة'
          : 'الصورة الشخصية';
      final croppedBytes = await showDialog<Uint8List>(
        context: context,
        builder: (_) =>
            ImageCropDialog(imageBytes: sourceBytes, imageLabel: photoLabel),
      );
      if (croppedBytes == null || !mounted) return;
      final controller = ref.read(profileControllerProvider.notifier);
      if (profile.role == UserRole.employer) {
        await controller.saveCompanyLogoBytes(croppedBytes);
      } else {
        await controller.saveSeekerImageBytes(croppedBytes);
      }
      if (mounted) {
        final hasPendingSync = ref
            .read(profileControllerProvider)
            .hasPendingSync;
        _showSuccess(
          hasPendingSync
              ? 'حُفظت الصورة محليًا وستتزامن عند عودة الإنترنت.'
              : profile.role == UserRole.employer
              ? 'تم حفظ شعار الشركة بنجاح.'
              : 'تم حفظ الصورة الشخصية بنجاح.',
        );
      }
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

  Future<void> _retryPendingSync() async {
    try {
      await ref.read(profileControllerProvider.notifier).retryPendingSync();
      if (!mounted) return;
      final stillPending = ref.read(profileControllerProvider).hasPendingSync;
      _showSuccess(
        stillPending
            ? 'لا تزال التغييرات في انتظار الشبكة وستُرسل تلقائيًا عند عودتها.'
            : 'اكتملت مزامنة تغييرات الملف الشخصي.',
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك الآن؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authServiceProvider).signOut();
      if (mounted) context.go(AppRoutes.home);
    } catch (error) {
      if (mounted) _showError(error);
    }
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
                  cvUrlController: _cvUrlController,
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
                  onSaveImage: () => _pickAndSaveImage(profile),
                  onRetryPendingSync: _retryPendingSync,
                  onSignOut: _confirmSignOut,
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
    required this.cvUrlController,
    required this.skillController,
    required this.skills,
    required this.industries,
    required this.industry,
    required this.actions,
    required this.onIndustryChanged,
    required this.onAddSkill,
    required this.onRemoveSkill,
    required this.onSave,
    required this.onSaveImage,
    required this.onRetryPendingSync,
    required this.onSignOut,
  });

  final GlobalKey<FormState> formKey;
  final UserModel profile;
  final TextEditingController nameController;
  final TextEditingController bioController;
  final TextEditingController phoneController;
  final TextEditingController jobTitleController;
  final TextEditingController cvUrlController;
  final TextEditingController skillController;
  final List<String> skills;
  final List<String> industries;
  final String? industry;
  final ProfileActionState actions;
  final ValueChanged<String?> onIndustryChanged;
  final VoidCallback onAddSkill;
  final ValueChanged<String> onRemoveSkill;
  final VoidCallback onSave;
  final VoidCallback onSaveImage;
  final VoidCallback onRetryPendingSync;
  final VoidCallback onSignOut;

  bool get _isEmployer => profile.role == UserRole.employer;

  @override
  Widget build(BuildContext context) {
    final image = _isEmployer ? profile.logoBase64 : profile.imageBase64;
    final photoLabel = _isEmployer ? 'شعار الشركة' : 'الصورة الشخصية';
    final imageProvider = _base64ImageProvider(image);
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
                    if (actions.needsSyncAttention) ...[
                      const SizedBox(height: 16),
                      _ProfileSyncNotice(
                        actions: actions,
                        onRetry: onRetryPendingSync,
                      ),
                    ],
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
                            onPressed: actions.isBusy ? null : onSaveImage,
                            icon: actions.isProcessingImage
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_outlined),
                            label: Text(
                              actions.isProcessingImage
                                  ? 'جارٍ تجهيز الصورة…'
                                  : 'اختيار $photoLabel',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG أو PNG حتى 2 ميغابايت. تُصغّر إلى 512px وتُحفظ داخل Firestore.',
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
                      TextFormField(
                        controller: cvUrlController,
                        keyboardType: TextInputType.url,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'رابط خارجي للسيرة الذاتية',
                          hintText: 'https://drive.google.com/...',
                          prefixIcon: Icon(Icons.link_outlined),
                        ),
                        validator: _externalCvUrlValidator,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'أضف رابط Google Drive أو أي رابط HTTPS/HTTP متاح لصاحب الوظيفة.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: actions.isBusy ? null : onSave,
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
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: actions.isBusy ? null : onSignOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.logout_outlined),
                      label: const Text('تسجيل الخروج'),
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

  static String? _externalCvUrlValidator(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return 'أدخل رابطًا خارجيًا صالحًا يبدأ بـ https:// أو http://';
    }
    return null;
  }

  static ImageProvider<Object>? _base64ImageProvider(String encoded) {
    if (encoded.trim().isEmpty) return null;
    try {
      final bytes = base64Decode(encoded);
      return bytes.isEmpty ? null : MemoryImage(bytes);
    } on FormatException {
      return null;
    }
  }
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

class _ProfileSyncNotice extends StatelessWidget {
  const _ProfileSyncNotice({required this.actions, required this.onRetry});

  final ProfileActionState actions;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final pending = actions.hasPendingSync;
    final color = pending
        ? Theme.of(context).colorScheme.secondaryContainer
        : Theme.of(context).colorScheme.errorContainer;
    final foreground = pending
        ? Theme.of(context).colorScheme.onSecondaryContainer
        : Theme.of(context).colorScheme.onErrorContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              pending ? Icons.cloud_queue_outlined : Icons.cloud_off_outlined,
              color: foreground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                actions.syncMessage,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: foreground),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: actions.isRetryingSync ? null : onRetry,
              child: Text(
                actions.isRetryingSync ? 'جارٍ التحقق…' : 'إعادة المحاولة',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
