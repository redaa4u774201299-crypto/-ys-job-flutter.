import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/core/router/app_routes.dart';
import 'package:ys_job/features/seeker/presentation/seeker_layout.dart';
import 'package:ys_job/features/seeker/presentation/widgets/seeker_access_gate.dart';
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

  group('hasSeekerAccess', () {
    test('يرفض الجلسة عندما لا يوجد ملف مستخدم في Firestore', () {
      expect(hasSeekerAccess(null), isFalse);
    });

    test('يسمح للباحث النشط فقط', () {
      expect(hasSeekerAccess(profile(UserRole.seeker)), isTrue);
      expect(
        hasSeekerAccess(profile(UserRole.seeker, isActive: false)),
        isFalse,
      );
    });

    test('يرفض صاحب العمل والمشرف حتى عندما تكون حساباتهما نشطة', () {
      expect(hasSeekerAccess(profile(UserRole.employer)), isFalse);
      expect(hasSeekerAccess(profile(UserRole.admin)), isFalse);
    });
  });

  group('مسارات مساحة الباحث', () {
    test('تفصل البحث والطلبات والملف الشخصي تحت نطاق الباحث المحمي', () {
      expect(AppRoutes.seekerDashboard, '/seeker-dashboard');
      expect(AppRoutes.seekerSearch, '/seeker-dashboard/search');
      expect(AppRoutes.seekerApplications, '/seeker-dashboard/applications');
      expect(AppRoutes.seekerProfile, '/seeker-dashboard/profile');
    });

    test('لا تتداخل وجهات شريط الباحث مع بعضها', () {
      expect({
        AppRoutes.seekerSearch,
        AppRoutes.seekerApplications,
        AppRoutes.seekerProfile,
      }, hasLength(3));
    });

    test('تستخدم قائمة Sidebar وDrawer الموحدة عناصر التنقل المطلوبة', () {
      final destinations = SeekerLayout.navigationDestinations;

      expect(destinations, hasLength(3));
      expect(destinations.map((destination) => destination.label), [
        'البحث عن وظائف',
        'طلباتي',
        'ملفي الشخصي',
      ]);
      expect(destinations.map((destination) => destination.path), [
        AppRoutes.seekerSearch,
        AppRoutes.seekerApplications,
        AppRoutes.seekerProfile,
      ]);
    });
  });
}
