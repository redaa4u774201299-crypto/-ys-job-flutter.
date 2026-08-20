import '../../../shared/models/company_directory_entry.dart';

/// فلتر محلي لنتائج الشركات الحية بعد استلامها من Firestore.
/// لا ينشئ بيانات جديدة، ويجعل البحث يعمل عبر الاسم ومجال العمل والوصف.
bool matchesCompanyDirectoryQuery(
  CompanyDirectoryEntry company,
  String rawQuery,
) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return true;
  final searchable = <String>[
    company.name,
    company.industry,
    company.description,
    company.city,
  ].join(' ').toLowerCase();
  return searchable.contains(query);
}
