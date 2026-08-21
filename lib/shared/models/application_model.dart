import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  pending,
  viewed,
  interview,
  accepted,
  rejected;

  String get value => name;

  static ApplicationStatus fromValue(String? value) => switch (value) {
    'viewed' => ApplicationStatus.viewed,
    'interview' => ApplicationStatus.interview,
    'accepted' => ApplicationStatus.accepted,
    'rejected' => ApplicationStatus.rejected,
    _ => ApplicationStatus.pending,
  };

  String get arabicLabel => switch (this) {
    ApplicationStatus.pending => 'قيد المراجعة',
    ApplicationStatus.viewed => 'تمت المراجعة',
    ApplicationStatus.interview => 'مقبول لمقابلة',
    ApplicationStatus.accepted => 'تم القبول',
    ApplicationStatus.rejected => 'لم يتم القبول',
  };
}

class ApplicationModel {
  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.seekerId,
    required this.employerId,
    required this.status,
    required this.appliedAt,
  });

  final String id;
  final String jobId;
  final String seekerId;
  final String employerId;
  final ApplicationStatus status;
  final DateTime appliedAt;

  /// اسم أوضح لهوية مقدم الطلب في وثائق Firestore الجديدة.
  ///
  /// يبقى [seekerId] متاحًا لتوافق الشاشات والسجلات الأقدم، وتُكتب القيمتان
  /// متماثلتين لحماية سلامة هوية مقدم الطلب.
  String get applicantId => seekerId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'jobId': jobId,
    'seekerId': seekerId,
    'applicantId': applicantId,
    'employerId': employerId,
    'status': status.value,
    'appliedAt': appliedAt.toUtc().toIso8601String(),
  };

  factory ApplicationModel.fromJson(Map<String, dynamic> json) =>
      ApplicationModel(
        id: _text(json['id']),
        jobId: _text(json['jobId']),
        seekerId: _firstText(json['applicantId'], json['seekerId']),
        employerId: _text(json['employerId']),
        status: ApplicationStatus.fromValue(_text(json['status'])),
        appliedAt:
            _date(json['appliedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'jobId': jobId,
    'seekerId': seekerId,
    'applicantId': applicantId,
    'employerId': employerId,
    'status': status.value,
    'appliedAt': Timestamp.fromDate(appliedAt.toUtc()),
  };

  factory ApplicationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return ApplicationModel.fromJson({...data, 'id': snapshot.id});
  }
}

String _text(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text == 'null' ? '' : text;
}

String _firstText(dynamic primary, dynamic fallback) {
  final primaryText = _text(primary);
  return primaryText.isEmpty ? _text(fallback) : primaryText;
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is int)
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}
