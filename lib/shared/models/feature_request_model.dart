import 'package:cloud_firestore/cloud_firestore.dart';

enum FeatureRequestStatus {
  pending,
  approved,
  rejected;

  String get value => name;

  static FeatureRequestStatus fromValue(String? value) => switch (value) {
    'approved' => FeatureRequestStatus.approved,
    'rejected' => FeatureRequestStatus.rejected,
    _ => FeatureRequestStatus.pending,
  };

  String get arabicLabel => switch (this) {
    FeatureRequestStatus.pending => 'قيد المراجعة',
    FeatureRequestStatus.approved => 'تمت الموافقة',
    FeatureRequestStatus.rejected => 'تم الرفض',
  };
}

class FeatureRequestModel {
  const FeatureRequestModel({
    required this.id,
    required this.jobId,
    required this.employerId,
    required this.status,
    required this.requestedAt,
  });

  final String id;
  final String jobId;
  final String employerId;
  final FeatureRequestStatus status;
  final DateTime requestedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'jobId': jobId,
    'employerId': employerId,
    'status': status.value,
    'requestedAt': requestedAt.toUtc().toIso8601String(),
  };

  factory FeatureRequestModel.fromJson(Map<String, dynamic> json) =>
      FeatureRequestModel(
        id: _text(json['id']),
        jobId: _text(json['jobId']),
        employerId: _text(json['employerId']),
        status: FeatureRequestStatus.fromValue(_text(json['status'])),
        requestedAt:
            _date(json['requestedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'jobId': jobId,
    'employerId': employerId,
    'status': status.value,
    'requestedAt': Timestamp.fromDate(requestedAt.toUtc()),
  };

  factory FeatureRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return FeatureRequestModel.fromJson({...data, 'id': snapshot.id});
  }
}

String _text(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text == 'null' ? '' : text;
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}
