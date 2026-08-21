# ربط Sentry مع Flutter Web بصورة آمنة

## النطاق

لا يدعم Firebase Crashlytics تطبيق Flutter Web في هذه النسخة؛ لذلك يستخدم Sentry فقط لتتبع أخطاء المتصفح غير المعالجة. لا يُربط Sentry قبل إنشاء مشروع Sentry مستقل وتحديد سياسة احتفاظ بالبيانات ومراجعة سياسة الخصوصية.

## الإعداد المقترح

1. أنشئ مشروعًا من نوع **Flutter** في Sentry وحدد بيئة منفصلة باسم `production`.
2. أضف الحزمة محليًا: `flutter pub add sentry_flutter`.
3. لا تضع DSN في ملفات Dart أو Git. مرره وقت البناء فقط عبر `--dart-define=SENTRY_DSN=...`، وخزّنه في GitHub Secret باسم `SENTRY_DSN`.
4. عدّل مسار GitHub Actions لتمرير قيمة السر في خطوة البناء فقط، وأعد بناء النشر.
5. فعّل Sentry في `main.dart` في إصدار الإنتاج فقط، باستخدام `SentryFlutter.init` و`SentryOptions.beforeSend` لتنقية البيانات.

## تنقية البيانات الإلزامية

يجب أن تزيل دالة `beforeSend` أي بريد إلكتروني أو رقم هاتف أو رابط سيرة ذاتية أو رمز وصول أو Base64 أو محتوى نموذج. لا تضف معرّف مستخدم Firebase إلى العلامات أو سياق التقرير. استخدم تصنيفًا عامًا للدور عند الحاجة، مثل `seeker` أو `employer`، بعد التأكد من أن ذلك لا يكشف هوية المستخدم.

```dart
final dsn = const String.fromEnvironment('SENTRY_DSN');

await SentryFlutter.init((options) {
  options.dsn = dsn;
  options.environment = 'production';
  options.sendDefaultPii = false;
  options.beforeSend = (event, hint) {
    return event.copyWith(
      user: null,
      request: null,
      breadcrumbs: const [],
    );
  };
}, appRunner: () => runApp(const YSJobApp()));
```

## اختبار آمن

ابدأ برسالة اختبار لا تتضمن بيانات مستخدم أو صفحات حقيقية، ثم تحقق في لوحة Sentry من البيئة وغياب بيانات PII. لا ترسل رسائل أخطاء المتصفح مباشرةً إلى Firestore، لأن ذلك يسمح بإساءة الاستخدام ورفع التكلفة وقد يكشف بيانات المستخدمين.
