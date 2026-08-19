import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/shared/models/feature_request_model.dart';
import 'package:ys_job/shared/models/job_model.dart';
import 'package:ys_job/shared/models/notification_model.dart';
import 'package:ys_job/shared/models/user_model.dart';

void main() {
  test('UserModel يحافظ على الدور والوقت في تحويل JSON', () {
    final createdAt = DateTime.utc(2026, 8, 20, 12);
    final model = UserModel(
      id: 'user-id',
      name: 'مستخدم',
      email: 'user@example.test',
      role: UserRole.employer,
      createdAt: createdAt,
    );

    final restored = UserModel.fromJson(model.toJson());

    expect(restored.id, model.id);
    expect(restored.role, UserRole.employer);
    expect(restored.createdAt, createdAt);
  });

  test('JobModel يحافظ على الحقول المطلوبة في تحويل JSON', () {
    final postedAt = DateTime.utc(2026, 8, 20, 12);
    final model = JobModel(
      id: 'job-id',
      employerId: 'employer-id',
      title: 'عنوان وظيفة',
      description: 'وصف وظيفة',
      location: 'صنعاء',
      jobType: 'inside_yemen',
      salaryRange: 'غير محدد',
      isFeatured: true,
      postedAt: postedAt,
    );

    final restored = JobModel.fromJson(model.toJson());

    expect(restored.id, model.id);
    expect(restored.employerId, model.employerId);
    expect(restored.isFeatured, isTrue);
    expect(restored.postedAt, postedAt);
  });

  test('NotificationModel يحافظ على المستلم وحالة القراءة ومرجع الطلب', () {
    final createdAt = DateTime.utc(2026, 8, 20, 12);
    final model = NotificationModel(
      id: 'notification-id',
      userId: 'seeker-id',
      title: 'تحديث حالة الطلب',
      message: 'تم قبولك لمقابلة.',
      isRead: false,
      createdAt: createdAt,
      applicationId: 'application-id',
    );

    final restored = NotificationModel.fromJson(model.toJson());

    expect(restored.userId, 'seeker-id');
    expect(restored.isRead, isFalse);
    expect(restored.applicationId, 'application-id');
    expect(restored.createdAt, createdAt);
  });

  test('NotificationModel يدعم إشعار اعتماد تمييز وظيفة دون مرجع تقديم', () {
    final createdAt = DateTime.utc(2026, 8, 20, 12);
    final model = NotificationModel(
      id: 'feature-notification-id',
      userId: 'employer-id',
      title: 'تم تمييز وظيفتك',
      message: 'تم استلام الدفعة وتم تمييز وظيفتك بنجاح.',
      isRead: false,
      createdAt: createdAt,
      applicationId: '',
    );

    final restored = NotificationModel.fromJson(model.toJson());

    expect(restored.userId, 'employer-id');
    expect(restored.applicationId, isEmpty);
    expect(restored.title, 'تم تمييز وظيفتك');
  });

  test('FeatureRequestModel يحافظ على حالة المراجعة ووقت الطلب', () {
    final requestedAt = DateTime.utc(2026, 8, 20, 12);
    final model = FeatureRequestModel(
      id: 'job-id',
      jobId: 'job-id',
      employerId: 'employer-id',
      status: FeatureRequestStatus.pending,
      requestedAt: requestedAt,
    );

    final restored = FeatureRequestModel.fromJson(model.toJson());

    expect(restored.id, model.id);
    expect(restored.status, FeatureRequestStatus.pending);
    expect(restored.requestedAt, requestedAt);
  });

  test('FeatureRequestStatus يتعرف على حالة الاعتماد', () {
    expect(
      FeatureRequestStatus.fromValue('approved'),
      FeatureRequestStatus.approved,
    );
  });
}
