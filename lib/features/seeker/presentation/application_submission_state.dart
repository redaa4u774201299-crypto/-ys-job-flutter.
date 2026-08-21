/// الحالة المحلية لزر التقديم أثناء جلسة عرض تفاصيل الوظيفة.
///
/// تبقى حالة التقديم الدائمة في Firestore، بينما تمنع هذه الحالة ضغط الزر
/// مرتين في الفترة بين تأكيد المستخدم ووصول تحديث الـ Stream.
class ApplicationSubmissionState {
  const ApplicationSubmissionState({
    required this.isSubmitting,
    required this.isApplied,
  });

  final bool isSubmitting;
  final bool isApplied;

  bool get isDisabled => isSubmitting || isApplied;

  String get label {
    if (isSubmitting) return 'جارٍ إرسال الطلب...';
    return isApplied ? 'تم التقديم' : 'تقديم الآن';
  }
}
