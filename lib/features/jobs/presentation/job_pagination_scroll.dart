/// النسبة التي تبدأ عندها واجهة الوظائف طلب الدفعة التالية.
const jobPaginationLoadThreshold = 0.8;

/// يعيد [true] عندما يصل المستخدم إلى 80% من مساحة التمرير القابلة للاستخدام.
///
/// لا تُطلق الدفعة التالية في قائمة لا تحتوي مساحة تمرير؛ فحالة الصفحات تتولى
/// منع الطلبات المكررة أو الطلب بعد الوصول إلى نهاية البيانات.
bool shouldLoadNextJobsPage({
  required double pixels,
  required double maxScrollExtent,
}) {
  if (maxScrollExtent <= 0) {
    return false;
  }

  return pixels >= maxScrollExtent * jobPaginationLoadThreshold;
}
