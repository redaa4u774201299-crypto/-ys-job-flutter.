import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/auth/data/auth_service.dart';

void main() {
  group('استعادة كلمة المرور', () {
    test('تطبع البريد الإلكتروني الصحيح قبل إرساله إلى Firebase', () {
      expect(
        AuthService.normalizedRecoveryEmail('  user@example.com  '),
        'user@example.com',
      );
    });

    test('ترفض البريد الإلكتروني الفارغ أو غير الصالح', () {
      expect(
        () => AuthService.normalizedRecoveryEmail(''),
        throwsFormatException,
      );
      expect(
        () => AuthService.normalizedRecoveryEmail('user-at-example.com'),
        throwsFormatException,
      );
    });
  });
}
