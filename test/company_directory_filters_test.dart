import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/companies/presentation/company_directory_filters.dart';
import 'package:ys_job/shared/models/company_directory_entry.dart';

void main() {
  final company = CompanyDirectoryEntry(
    id: 'company-1',
    name: 'الأفق للتقنية',
    industry: 'تقنية المعلومات',
    description: 'تطوّر حلولًا رقمية للشركات.',
    logoThumbBase64: '',
    city: 'صنعاء',
  );

  group('فلتر دليل الشركات', () {
    test('يعرض كل الشركات عند ترك الاستعلام فارغًا', () {
      expect(matchesCompanyDirectoryQuery(company, '   '), isTrue);
    });

    test('يبحث في اسم الشركة ومجال العمل والوصف والمدينة', () {
      expect(matchesCompanyDirectoryQuery(company, 'الأفق'), isTrue);
      expect(matchesCompanyDirectoryQuery(company, 'تقنية'), isTrue);
      expect(matchesCompanyDirectoryQuery(company, 'رقمية'), isTrue);
      expect(matchesCompanyDirectoryQuery(company, 'صنعاء'), isTrue);
      expect(matchesCompanyDirectoryQuery(company, 'محاسبة'), isFalse);
    });
  });
}
