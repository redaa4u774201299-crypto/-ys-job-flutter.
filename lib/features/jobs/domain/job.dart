import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.companyName,
    required this.city,
    required this.workType,
    required this.salary,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String companyName;
  final String city;
  final String workType;
  final String salary;
  final DateTime? createdAt;

  bool get isDisplayable => title.isNotEmpty && companyName.isNotEmpty;

  bool matchesSearch(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    final searchableText = '$title $companyName $city $workType'.toLowerCase();
    return searchableText.contains(normalizedQuery);
  }

  factory Job.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final company = data['company'];
    final companyFromObject = company is Map ? _asText(company['name']) : '';
    final companyFromText = _firstText(data, const ['companyName', 'company']);

    return Job(
      id: snapshot.id,
      title: _firstText(data, const ['title', 'jobTitle']),
      companyName: companyFromText.isNotEmpty
          ? companyFromText
          : companyFromObject,
      city: _firstText(data, const ['city', 'location']),
      workType: _firstText(data, const ['workType', 'type']),
      salary: _asText(data['salary']),
      createdAt: _asDate(data['createdAt']),
    );
  }
}

String _firstText(Map<String, dynamic> data, Iterable<String> keys) {
  for (final key in keys) {
    final text = _asText(data[key]);
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _asText(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text == 'null' ? '' : text;
}

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
