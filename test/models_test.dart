import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/shared/models/job_model.dart';
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
}
