import '../../../shared/models/user_model.dart';

/// فلتر محلي لنتائج الشركات الحية بعد استلامها من Firestore.
/// لا ينشئ بيانات جديدة، ويجعل البحث يعمل عبر الاسم ومجال العمل والوصف.
bool matchesCompanyDirectoryQuery(UserModel company, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return true;
  final searchable = <String>[
    company.companyName,
    company.name,
    company.industry,
    company.bio,
  ].join(' ').toLowerCase();
  return searchable.contains(query);
}
