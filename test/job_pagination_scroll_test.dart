import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/jobs/presentation/job_pagination_scroll.dart';

void main() {
  group('shouldLoadNextJobsPage', () {
    test('لا يبدأ تحميل صفحة جديدة قبل عتبة 80% من التمرير', () {
      expect(
        shouldLoadNextJobsPage(pixels: 799, maxScrollExtent: 1000),
        isFalse,
      );
    });

    test('يبدأ التحميل عند عتبة 80% أو بعدها', () {
      expect(
        shouldLoadNextJobsPage(pixels: 800, maxScrollExtent: 1000),
        isTrue,
      );
      expect(
        shouldLoadNextJobsPage(pixels: 920, maxScrollExtent: 1000),
        isTrue,
      );
    });

    test('لا يطلب صفحة تالية إذا لم تكن القائمة قابلة للتمرير', () {
      expect(shouldLoadNextJobsPage(pixels: 0, maxScrollExtent: 0), isFalse);
    });
  });
}
