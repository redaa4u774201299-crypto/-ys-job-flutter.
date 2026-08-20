import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/base64_thumbnail_avatar.dart';
import '../company_directory_filters.dart';

final companiesDirectoryProvider = StreamProvider.autoDispose<List<UserModel>>((
  ref,
) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) return Stream.value(const <UserModel>[]);
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: UserRole.employer.value)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map(UserModel.fromFirestore)
                .where((company) => company.isActive)
                .toList(growable: false)
              ..sort(
                (first, second) =>
                    _companyLabel(first).compareTo(_companyLabel(second)),
              ),
      );
});

String _companyLabel(UserModel company) {
  final label = company.companyName.trim();
  return (label.isEmpty ? company.name : label).toLowerCase();
}

class CompaniesPage extends ConsumerStatefulWidget {
  const CompaniesPage({super.key});

  @override
  ConsumerState<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends ConsumerState<CompaniesPage> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ref.watch(firebaseRuntimeProvider);
    final companiesState = runtime.isReady
        ? ref.watch(companiesDirectoryProvider)
        : null;
    return Scaffold(
      appBar: AppBar(title: const Text('دليل الشركات')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'الشركات المسجلة',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'استكشف ملفات الشركات النشطة ومجالات عملها كما نُشرت في المنصة.',
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    textField: true,
                    label: 'البحث في دليل الشركات',
                    child: TextField(
                      controller: _queryController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'ابحث باسم الشركة أو مجالها',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: !runtime.isReady
                        ? const _CompaniesMessage(
                            icon: Icons.settings_outlined,
                            message:
                                'تحتاج Firebase إلى التهيئة لعرض دليل الشركات.',
                          )
                        : companiesState!.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) => const _CompaniesMessage(
                              icon: Icons.cloud_off_outlined,
                              message: 'تعذر تحميل دليل الشركات حاليًا.',
                            ),
                            data: (companies) {
                              final visibleCompanies = companies
                                  .where(
                                    (company) => matchesCompanyDirectoryQuery(
                                      company,
                                      _queryController.text,
                                    ),
                                  )
                                  .toList(growable: false);
                              if (visibleCompanies.isEmpty) {
                                return _CompaniesMessage(
                                  icon: Icons.business_outlined,
                                  message: _queryController.text.trim().isEmpty
                                      ? 'لا توجد شركات نشطة مسجلة حاليًا.'
                                      : 'لا توجد شركات تطابق عبارة البحث.',
                                );
                              }
                              return ListView.separated(
                                itemCount: visibleCompanies.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) => _CompanyCard(
                                  company: visibleCompanies[index],
                                ),
                              );
                            },
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

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.company});

  final UserModel company;

  @override
  Widget build(BuildContext context) {
    final name = company.companyName.trim().isEmpty
        ? company.name
        : company.companyName.trim();
    return Semantics(
      container: true,
      label:
          'شركة $name${company.industry.isEmpty ? '' : '، مجال ${company.industry}'}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Base64ThumbnailAvatar(
                  encoded: company.logoThumbBase64,
                  fallbackLabel: name,
                  fallbackIcon: Icons.business_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (company.industry.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Chip(label: Text(company.industry)),
                    ],
                    if (company.bio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        company.bio,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompaniesMessage extends StatelessWidget {
  const _CompaniesMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.gold),
            const SizedBox(width: 12),
            Flexible(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}
