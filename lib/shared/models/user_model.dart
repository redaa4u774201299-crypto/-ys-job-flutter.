import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  seeker,
  employer;

  String get value => name;

  static UserRole fromValue(String? value) => switch (value) {
    'employer' => UserRole.employer,
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
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    DateTime? createdAt,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.value,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: _asText(json['id']),
    name: _asText(json['name']),
    email: _asText(json['email']),
    role: UserRole.fromValue(_asText(json['role'])),
    createdAt:
        _asDate(json['createdAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.value,
    'createdAt': Timestamp.fromDate(createdAt.toUtc()),
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
  if (text == 'null') {
    return '';
  }
  return text;
}

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toUtc();
  }
  if (value is DateTime) {
    return value.toUtc();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}
