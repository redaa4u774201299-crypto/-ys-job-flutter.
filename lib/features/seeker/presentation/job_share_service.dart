import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/models/job_model.dart';

enum JobShareResult { copiedToClipboard, openedNativeShareSheet }

/// يشارك الوظيفة دون تمرير أي بيانات تعريفية للباحث أو لصاحب العمل.
///
/// على الويب ننسخ الرابط الحالي كاملًا لتفادي اختلاف دعم واجهة المشاركة بين
/// المتصفحات. أما على الهاتف فتُفتح واجهة المشاركة الأصلية للنظام.
class JobShareService {
  const JobShareService();

  Future<JobShareResult> share(JobModel job) async {
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: Uri.base.toString()));
      return JobShareResult.copiedToClipboard;
    }

    await SharePlus.instance.share(
      ShareParams(
        title: 'فرصة وظيفية عبر YS.JOB',
        subject: 'فرصة ${job.title} عبر YS.JOB',
        text: nativeJobShareText(job),
      ),
    );
    return JobShareResult.openedNativeShareSheet;
  }
}

String nativeJobShareText(JobModel job) {
  final employer = job.employerName.trim().isEmpty
      ? 'جهة عمل على منصة YS.JOB'
      : job.employerName.trim();
  return 'فرصة وظيفية: ${job.title}\n'
      'جهة العمل: $employer\n'
      'اكتشف الفرصة عبر منصة YS.JOB.';
}
