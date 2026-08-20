import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/companies/presentation/company_directory_filters.dart';
import 'package:ys_job/shared/models/user_model.dart';

void main() {
  final company = UserModel(
    id: 'company-1',
    name: 'شركة الأفق',
    companyName: 'الأفق للتقنية',
    email: 'company@example.com',
    role: UserRole.employer,
    createdAt: DateTime.utc(2026),
    industry: 'تقنية المعلومات',
    bio: 'تطوّر حلولًا رقمية للشركات.',
  );

  group('فلتر دليل الشركات', () {
    test('يعرض كل الشركات عند ترك الاستعلام فارغًا', () {
      expect(matchesCompanyDirectoryQuery(company, '   '), isTrue);
    });

    test('يبحث في اسم الشركة واسم الحساب ومجال العمل والوصف', () {
      expect(matchesCompanyDirectoryQuery(company, 'الأفق'), isTrue);
      expect(matchesCompanyDirectoryQuery(company, 'تقنية'), isTrue);
      expect(matchesCompanyDirectoryQuery(company, 'رقمية'), isTrue);
      expect(matchesCompanyDirectoryQuery(company, 'محاسبة'), isFalse);
    });
  });
}
