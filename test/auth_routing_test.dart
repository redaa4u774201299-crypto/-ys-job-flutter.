import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/auth/data/auth_service.dart';
import 'package:ys_job/shared/models/user_model.dart';

void main() {
  group('destinationForRole', () {
    test('يوجّه الباحث إلى قائمة الوظائف', () {
      expect(destinationForRole(UserRole.seeker), '/jobs');
    });

    test('يوجّه صاحب الشركة إلى لوحة التحكم الخاصة به', () {
      expect(destinationForRole(UserRole.employer), '/employer-dashboard');
    });

    test('يوجّه المشرف إلى لوحة الإدارة', () {
      expect(destinationForRole(UserRole.admin), '/admin-dashboard');
    });
  });
}
