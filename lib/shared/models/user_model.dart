import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  seeker,
  employer,
  admin;

  String get value => name;

  String get label => switch (this) {
    UserRole.seeker => 'باحث عن عمل',
    UserRole.employer => 'صاحب شركة',
    UserRole.admin => 'مشرف',
  };

  static UserRole fromValue(String? value) => switch (value) {
    'employer' => UserRole.employer,
    'admin' => UserRole.admin,
    _ => UserRole.seeker,
  };
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.bio = '',
    this.skills = const [],
    this.phone = '',
    this.imageBase64 = '',
    this.imageThumbBase64 = '',
    this.logoBase64 = '',
    this.logoThumbBase64 = '',
    this.cvUrl = '',
    this.industry = '',
    this.companyName = '',
    this.jobTitle = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final String bio;
  final List<String> skills;
  final String phone;
  final String imageBase64;
  final String imageThumbBase64;
  final String logoBase64;
  final String logoThumbBase64;
  final String cvUrl;
  final String industry;
  final String companyName;
  final String jobTitle;
  final bool isActive;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    String? bio,
    List<String>? skills,
    String? phone,
    String? imageBase64,
    String? imageThumbBase64,
    String? logoBase64,
    String? logoThumbBase64,
    String? cvUrl,
    String? industry,
    String? companyName,
    String? jobTitle,
    bool? isActive,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
    bio: bio ?? this.bio,
    skills: skills ?? this.skills,
    phone: phone ?? this.phone,
    imageBase64: imageBase64 ?? this.imageBase64,
    imageThumbBase64: imageThumbBase64 ?? this.imageThumbBase64,
    logoBase64: logoBase64 ?? this.logoBase64,
    logoThumbBase64: logoThumbBase64 ?? this.logoThumbBase64,
    cvUrl: cvUrl ?? this.cvUrl,
    industry: industry ?? this.industry,
    companyName: companyName ?? this.companyName,
    jobTitle: jobTitle ?? this.jobTitle,
    isActive: isActive ?? this.isActive,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.value,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'bio': bio,
    'skills': skills,
    'phone': phone,
    'imageBase64': imageBase64,
    'imageThumbBase64': imageThumbBase64,
    'logoBase64': logoBase64,
    'logoThumbBase64': logoThumbBase64,
    'cvUrl': cvUrl,
    'industry': industry,
    'companyName': companyName,
    'jobTitle': jobTitle,
    'isActive': isActive,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: _asText(json['id']),
    name: _asText(json['name']),
    email: _asText(json['email']),
    role: UserRole.fromValue(_asText(json['role'])),
    createdAt:
        _asDate(json['createdAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    bio: _asText(json['bio']),
    skills: _asTextList(json['skills']),
    phone: _asText(json['phone']),
    imageBase64: _asText(json['imageBase64']),
    imageThumbBase64: _asText(json['imageThumbBase64']),
    logoBase64: _asText(json['logoBase64']),
    logoThumbBase64: _asText(json['logoThumbBase64']),
    cvUrl: _asText(json['cvUrl']),
    industry: _asText(json['industry']),
    companyName: _asText(json['companyName']),
    jobTitle: _asText(json['jobTitle']),
    isActive: json['isActive'] != false,
  );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.value,
    'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    'bio': bio,
    'skills': skills,
    'phone': phone,
    'imageBase64': imageBase64,
    'imageThumbBase64': imageThumbBase64,
    'logoBase64': logoBase64,
    'logoThumbBase64': logoThumbBase64,
    'cvUrl': cvUrl,
    'industry': industry,
    'companyName': companyName,
    'jobTitle': jobTitle,
    'isActive': isActive,
  };

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return UserModel.fromJson({...data, 'id': snapshot.id});
  }
}

String _asText(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text == 'null' ? '' : text;
}

List<String> _asTextList(dynamic value) {
  if (value is! Iterable) return const [];
  return value
      .map(_asText)
      .where((skill) => skill.isNotEmpty)
      .toList(growable: false);
}

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}
