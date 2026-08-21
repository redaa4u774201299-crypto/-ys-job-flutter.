import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/home/presentation/home_search.dart';

void main() {
  group('HomeSearchCriteria', () {
    test('لا ينتج مسارًا عند خلو المسمى أو اسم الشركة', () {
      const criteria = HomeSearchCriteria(query: '  ');

      expect(criteria.isEmpty, isTrue);
      expect(criteria.jobsPath, isNull);
    });

    test('يمرر المسمى بعد تنقية الفراغات إلى مسار الوظائف', () {
      const criteria = HomeSearchCriteria(query: '  مطور Flutter  ');

      final path = criteria.jobsPath;

      expect(path, isNotNull);
      final uri = Uri.parse(path!);
      expect(uri.path, '/jobs');
      expect(uri.queryParameters, {'q': 'مطور Flutter'});
    });

    test('يرفض إدخالًا مكوّنًا من مسافات وعلامات تبويب وأسطر فقط', () {
      const criteria = HomeSearchCriteria(query: ' \t\n  ');

      expect(criteria.normalizedQuery, isEmpty);
      expect(criteria.isEmpty, isTrue);
      expect(criteria.jobsPath, isNull);
    });

    test('يحافظ على الرموز الخاصة عند ترميز رابط البحث وفكّه', () {
      const query = '  C++ & QA/اختبار #1؟  ';
      const criteria = HomeSearchCriteria(query: query);

      final path = criteria.jobsPath;

      expect(path, isNotNull);
      expect(path, contains('%2B%2B'));
      expect(path, contains('%26'));
      final uri = Uri.parse(path!);
      expect(uri.path, '/jobs');
      expect(uri.queryParameters, {'q': 'C++ & QA/اختبار #1؟'});
    });
  });
}
