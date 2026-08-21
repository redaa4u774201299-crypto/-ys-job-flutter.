/// دوال نقية لتوحيد مفاتيح بحث الوظائف العامة وبناء بادئات قابلة للفهرسة.
/// لا تستقبل هذه الدوال بيانات الحساب أو التواصل أو الملفات المرفوعة.
abstract final class JobSearchIndex {
  static const int maxPrefixLength = 64;
  static const int maxTerms = 160;

  static String normalize(String value) {
    final compact = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return compact
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ة', 'ه')
        .toLowerCase();
  }

  /// يبني بادئات للاسم الكامل والكلمات المنفردة من العنوان واسم الشركة.
  /// يحتفظ بالعدد والحجم ضمن سقف صغير لتجنب تضخيم فهرس Firestore.
  static List<String> buildTerms({
    required String title,
    required String employerName,
  }) {
    final terms = <String>{};

    void addPrefixes(String source) {
      final normalized = normalize(source);
      if (normalized.isEmpty) return;

      void addPrefixSeries(String value) {
        final end = value.length < maxPrefixLength
            ? value.length
            : maxPrefixLength;
        for (var index = 1; index <= end && terms.length < maxTerms; index++) {
          terms.add(value.substring(0, index));
        }
      }

      addPrefixSeries(normalized);
      for (final token in normalized.split(' ')) {
        if (terms.length >= maxTerms) break;
        if (token.isNotEmpty) addPrefixSeries(token);
      }
    }

    addPrefixes(title);
    addPrefixes(employerName);
    return List<String>.unmodifiable(terms);
  }
}
