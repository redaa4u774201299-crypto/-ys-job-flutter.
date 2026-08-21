import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/auth/data/auth_service.dart';
import 'package:ys_job/shared/models/user_model.dart';

void main() {
  group('destinationForRole', () {
    test('يوجّه الباحث إلى لوحته الشخصية', () {
      expect(destinationForRole(UserRole.seeker), '/seeker-dashboard');
    });

    test('يوجّه صاحب الشركة إلى لوحة التحكم الخاصة به', () {
      expect(destinationForRole(UserRole.employer), '/employer-dashboard');
    });

    test('يوجّه المشرف إلى لوحة الإدارة', () {
      expect(destinationForRole(UserRole.admin), '/admin-dashboard');
    });
  });

  group('العودة الآمنة بعد تسجيل الدخول', () {
    test('تقبل رابط تفاصيل الوظيفة الداخلي فقط', () {
      expect(
        safeJobDetailsReturnTo('/job-details/firestore-job-42'),
        '/job-details/firestore-job-42',
      );
    });

    test('ترفض رابطًا خارجيًا أو صفحة إدارية كوجهة عودة', () {
      expect(safeJobDetailsReturnTo('https://example.com'), isNull);
      expect(safeJobDetailsReturnTo('/admin-dashboard'), isNull);
    });

    test('تعيد الباحث إلى تفاصيل الوظيفة عند وجود رابط عودة صالح', () {
      expect(
        destinationAfterLogin(
          UserRole.seeker,
          returnTo: '/job-details/firestore-job-42',
        ),
        '/job-details/firestore-job-42',
      );
    });
  });
}
