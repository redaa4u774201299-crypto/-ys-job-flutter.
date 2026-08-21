import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/home/presentation/home_search.dart';

void main() {
  group('HomeSearchCriteria', () {
    test('لا ينتج مسارًا عند خلو المسمى والمدينة', () {
      const criteria = HomeSearchCriteria(query: '  ', city: ' ');

      expect(criteria.isEmpty, isTrue);
      expect(criteria.jobsPath, isNull);
    });

    test('يمرر المسمى والمدينة بعد تنقية الفراغات إلى مسار الوظائف', () {
      const criteria = HomeSearchCriteria(
        query: '  مطور Flutter  ',
        city: '  صنعاء  ',
      );

      final path = criteria.jobsPath;

      expect(path, isNotNull);
      final uri = Uri.parse(path!);
      expect(uri.path, '/jobs');
      expect(uri.queryParameters, {'q': 'مطور Flutter', 'city': 'صنعاء'});
    });

    test('يسمح بالبحث بالمدينة فقط دون إرسال معيار نصي فارغ', () {
      const criteria = HomeSearchCriteria(query: '', city: 'عدن');

      final uri = Uri.parse(criteria.jobsPath!);

      expect(uri.queryParameters, {'city': 'عدن'});
    });
  });
}
