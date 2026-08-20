import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/admin/presentation/admin_access_policy.dart';
import 'package:ys_job/shared/models/user_model.dart';

void main() {
  UserModel profile(UserRole role, {bool isActive = true}) => UserModel(
    id: 'user-1',
    name: 'مستخدم اختبار',
    email: 'user@example.com',
    role: role,
    isActive: isActive,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  group('hasAdminAccess', () {
    test('يرفض الجلسة عندما لا يوجد ملف مستخدم في Firestore', () {
      expect(hasAdminAccess(null), isFalse);
    });

    test('يسمح فقط للمدير النشط', () {
      expect(hasAdminAccess(profile(UserRole.admin)), isTrue);
      expect(hasAdminAccess(profile(UserRole.admin, isActive: false)), isFalse);
    });

    test('يرفض الباحث وصاحب العمل حتى عند نشاط الحساب', () {
      expect(hasAdminAccess(profile(UserRole.seeker)), isFalse);
      expect(hasAdminAccess(profile(UserRole.employer)), isFalse);
    });
  });
}
