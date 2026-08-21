# YS.JOB — منصة الوظائف اليمنية

تطبيق Flutter Web عربي من اليمين إلى اليسار يربط الباحثين عن عمل بأصحاب الشركات، مع واجهات منفصلة للباحث وصاحب العمل ومدير النظام.

## المزايا

- مصادقة Firebase بالبريد الإلكتروني، جلسة ويب محلية، واستعادة كلمة المرور.
- أدوار `seeker` و`employer` و`admin` مع حراسة مسارات وقواعد وصول مبنية على Firestore.
- وظائف، طلبات تقديم، حالات متابعة، لوحات تحكم، وإشعارات داخلية حية.
- ملفات شخصية للشركات والباحثين؛ تحفظ الصور المقصوصة والمضغوطة في Firestore بصيغة Base64، وتستخدم رابطًا خارجيًا للسيرة الذاتية.
- دليل شركات عام وآمن في مجموعة `company_directory` مستقلة عن مستندات المستخدمين الخاصة.
- واجهة Material Design 3 متجاوبة للجوال أولًا، وخط Cairo، وألوان المنصة: Navy `#061A33` وGold `#D9A441` وBeige `#F5EFE6`.

## المتطلبات المحلية

| الأداة | الاستخدام |
| --- | --- |
| Flutter SDK | تحليل وبناء واختبار التطبيق. |
| Node.js وnpm | تشغيل اختبارات Firebase Emulator وقواعد Firestore. |
| Firebase CLI عبر الاعتمادات المحلية | تشغيل Firestore Emulator محليًا فقط. |

لا تُحفظ مفاتيح إضافية في هذا المستودع. تهيئة Firebase Web موجودة في الملفات المولدة الخاصة بالمشروع، ولا يستخدم التطبيق Firebase Storage.

## التحقق المحلي

```bash
cd /home/ubuntu/ys-job-flutter
npm run test:firestore-rules
/home/ubuntu/flutter-sdk/bin/flutter analyze
/home/ubuntu/flutter-sdk/bin/flutter test
/home/ubuntu/flutter-sdk/bin/flutter build web --release --no-tree-shake-icons --base-href=/-ys-job-flutter./
```

تجري اختبارات القواعد على مشروع المحاكي المعزول `demo-ysjob` ولا تتصل ببيانات Firestore الإنتاجية.

## النشر إلى GitHub Pages

يدير `.github/workflows/flutter-web-ci.yml` التسلسل التالي عند الدفع إلى `main`:

1. تثبيت Node وFlutter.
2. تشغيل اختبارات Firestore Emulator.
3. تنفيذ `flutter analyze` واختبارات Flutter.
4. بناء Web بقيمة `base href` المطابقة لاسم المستودع.
5. رفع ناتج `build/web` ونشره عبر GitHub Pages.

بعد أول دفع ناجح، فعّل **GitHub Actions** كمصدر في **Settings → Pages → Build and deployment**. التفاصيل العملية الكاملة موجودة في [دليل إصدار الإنتاج](docs/production_release_runbook.md).

## قواعد Firestore

ملف القواعد المصدرية هو [`firebase/firestore.rules`](firebase/firestore.rules). يجب اختبار القواعد محليًا قبل النشر، ثم نشرها يدويًا إلى مشروع Firebase الإنتاجي `ysjob-web` وفق الدليل المذكور. لا ينشر مسار GitHub Pages قواعد الإنتاج تلقائيًا.

## ملاحظات أمنية

- لا تضع رموز GitHub أو مفاتيح Firebase الحساسة في Git أو GitHub Actions أو رابط `origin`.
- لا تنسخ مستندات `users` إلى واجهة عامة؛ استخدم `company_directory` المحدود الحقول فقط.
- لا ترفع صورًا أو ملفات مستخدمين إلى Firebase Storage ضمن هذا المشروع.
- لا تُنشئ حسابات `admin` من واجهة التسجيل العامة.
