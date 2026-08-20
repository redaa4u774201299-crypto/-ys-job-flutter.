import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_model.dart';

/// تمثيل عام محدود لشركة في الدليل. لا يحتوي على بريد أو هاتف أو صور كاملة
/// أو أي بيانات خاصة من مستند المستخدم.
class CompanyDirectoryEntry {
  const CompanyDirectoryEntry({
    required this.id,
    required this.name,
    required this.industry,
    required this.description,
    required this.logoThumbBase64,
    required this.city,
  });

  final String id;
  final String name;
  final String industry;
  final String description;
  final String logoThumbBase64;
  final String city;

  factory CompanyDirectoryEntry.fromEmployerProfile(
    UserModel profile, {
    String city = '',
  }) {
    final companyName = profile.companyName.trim();
    return CompanyDirectoryEntry(
      id: profile.id,
      name: companyName.isEmpty ? profile.name.trim() : companyName,
      industry: profile.industry.trim(),
      description: profile.bio.trim(),
      logoThumbBase64: profile.logoThumbBase64,
      city: city.trim(),
    );
  }

  factory CompanyDirectoryEntry.fromJson(Map<String, dynamic> json) =>
      CompanyDirectoryEntry(
        id: _asText(json['id']),
        name: _asText(json['name']),
        industry: _asText(json['industry']),
        description: _asText(json['description']),
        logoThumbBase64: _asText(json['logoThumbBase64']),
        city: _asText(json['city']),
      );

  factory CompanyDirectoryEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return CompanyDirectoryEntry.fromJson({...data, 'id': snapshot.id});
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'industry': industry,
    'description': description,
    'logoThumbBase64': logoThumbBase64,
    'city': city,
  };
}

String _asText(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text == 'null' ? '' : text;
}
