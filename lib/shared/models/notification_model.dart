import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.applicationId,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  /// رابط داخلي لطلب التوظيف الذي سبب الإشعار؛ لا يعرض للمستخدم مباشرة.
  final String applicationId;

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    userId: userId,
    title: title,
    message: message,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    applicationId: applicationId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'isRead': isRead,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'applicationId': applicationId,
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: _text(json['id']),
        userId: _text(json['userId']),
        title: _text(json['title']),
        message: _text(json['message']),
        isRead: json['isRead'] == true,
        createdAt:
            _date(json['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        applicationId: _text(json['applicationId']),
      );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    'applicationId': applicationId,
  };

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return NotificationModel.fromJson({...data, 'id': snapshot.id});
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
