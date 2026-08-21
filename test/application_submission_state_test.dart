import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/seeker/presentation/application_submission_state.dart';

void main() {
  group('ApplicationSubmissionState', () {
    test('يعطّل الزر ويعرض حالة تحميل أثناء إرسال الطلب', () {
      const state = ApplicationSubmissionState(
        isSubmitting: true,
        isApplied: false,
      );

      expect(state.isDisabled, isTrue);
      expect(state.label, 'جارٍ إرسال الطلب...');
    });

    test('يعطّل الزر بعد نجاح التقديم حتى قبل وصول تحديث Firestore', () {
      const state = ApplicationSubmissionState(
        isSubmitting: false,
        isApplied: true,
      );

      expect(state.isDisabled, isTrue);
      expect(state.label, 'تم التقديم');
    });

    test('يبقي زر التقديم متاحًا للوظيفة التي لم يُقدّم عليها المستخدم', () {
      const state = ApplicationSubmissionState(
        isSubmitting: false,
        isApplied: false,
      );

      expect(state.isDisabled, isFalse);
      expect(state.label, 'تقديم الآن');
    });
  });
}
