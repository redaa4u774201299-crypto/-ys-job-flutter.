import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  const JobModel({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.location,
    required this.jobType,
    required this.salaryRange,
    required this.isFeatured,
    required this.postedAt,
  });

  final String id;
  final String employerId;
  final String title;
  final String description;
  final String location;
  final String jobType;
  final String salaryRange;
  final bool isFeatured;
  final DateTime postedAt;

  JobModel copyWith({
    String? id,
    String? employerId,
    String? title,
    String? description,
    String? location,
    String? jobType,
    String? salaryRange,
    bool? isFeatured,
    DateTime? postedAt,
  }) => JobModel(
    id: id ?? this.id,
    employerId: employerId ?? this.employerId,
    title: title ?? this.title,
    description: description ?? this.description,
    location: location ?? this.location,
    jobType: jobType ?? this.jobType,
    salaryRange: salaryRange ?? this.salaryRange,
    isFeatured: isFeatured ?? this.isFeatured,
    postedAt: postedAt ?? this.postedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'employerId': employerId,
    'title': title,
    'description': description,
    'location': location,
    'jobType': jobType,
    'salaryRange': salaryRange,
    'isFeatured': isFeatured,
    'postedAt': postedAt.toUtc().toIso8601String(),
  };

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
    id: _asText(json['id']),
    employerId: _asText(json['employerId']),
    title: _asText(json['title']),
    description: _asText(json['description']),
    location: _asText(json['location']),
    jobType: _asText(json['jobType']),
    salaryRange: _asText(json['salaryRange']),
    isFeatured: json['isFeatured'] == true,
    postedAt:
        _asDate(json['postedAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'employerId': employerId,
    'title': title,
    'description': description,
    'location': location,
    'jobType': jobType,
    'salaryRange': salaryRange,
    'isFeatured': isFeatured,
    'postedAt': Timestamp.fromDate(postedAt.toUtc()),
  };

  factory JobModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return JobModel.fromJson({...data, 'id': snapshot.id});
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
