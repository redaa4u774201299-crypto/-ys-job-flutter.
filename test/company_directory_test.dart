import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/companies/presentation/company_directory_filters.dart';
import 'package:ys_job/shared/models/company_directory_entry.dart';
import 'package:ys_job/shared/models/user_model.dart';

void main() {
  group('CompanyDirectoryEntry', () {
    final employer = UserModel(
      id: 'employer-1',
      name: 'اسم جهة الاتصال',
      email: 'private@example.com',
      role: UserRole.employer,
      createdAt: DateTime.utc(2026, 8, 21),
      companyName: 'شركة أفق للتقنية',
      industry: 'تقنية المعلومات',
      bio: 'حلول برمجية للشركات',
      phone: '777000222',
      logoBase64: 'large-private-image',
      logoThumbBase64: 'public-thumbnail',
      cvUrl: 'https://drive.google.com/private-cv',
    );

    test('ينتج وثيقة عامة بالحقول المسموح بها فقط', () {
      final entry = CompanyDirectoryEntry.fromEmployerProfile(
        employer,
        city: 'صنعاء',
      );

      expect(entry.toFirestore(), {
        'id': 'employer-1',
        'name': 'شركة أفق للتقنية',
        'industry': 'تقنية المعلومات',
        'description': 'حلول برمجية للشركات',
        'logoThumbBase64': 'public-thumbnail',
        'city': 'صنعاء',
      });
      expect(entry.toFirestore().containsKey('email'), isFalse);
      expect(entry.toFirestore().containsKey('phone'), isFalse);
      expect(entry.toFirestore().containsKey('logoBase64'), isFalse);
      expect(entry.toFirestore().containsKey('cvUrl'), isFalse);
    });

    test('تبحث الفلترة المحلية عبر الاسم والمجال والوصف والمدينة', () {
      final entry = CompanyDirectoryEntry.fromEmployerProfile(
        employer,
        city: 'صنعاء',
      );

      expect(matchesCompanyDirectoryQuery(entry, 'أفق'), isTrue);
      expect(matchesCompanyDirectoryQuery(entry, 'المعلومات'), isTrue);
      expect(matchesCompanyDirectoryQuery(entry, 'برمجية'), isTrue);
      expect(matchesCompanyDirectoryQuery(entry, 'صنعاء'), isTrue);
      expect(matchesCompanyDirectoryQuery(entry, 'لا تطابق'), isFalse);
    });
  });
}
