# مراجع مراقبة YS.JOB Flutter Web

تاريخ التحقق: 2026-08-21.

## Firebase Performance Monitoring

- توثق Firebase إضافة حزمة `firebase_performance` وتهيئة Firebase ثم التحقق من البيانات في لوحة Performance. تجمع SDK تلقائيًا مؤشرات مرتبطة بدورة حياة التطبيق وطلبات HTTP/S، وتدعم traces مخصصة لقياس تدفقات محددة.
- توضح وثائق الويب أن SDK مراقبة الأداء للويب ما زالت Beta، وأن إرسال الأحداث يتم على دفعات وقد يتأخر ظهور البيانات الأولية لبضع دقائق.
- مرجع Flutter: <https://firebase.google.com/docs/perf-mon/flutter/get-started>
- مرجع Web: <https://firebase.google.com/docs/perf-mon/get-started-web>
- صفحة الحزمة: <https://pub.dev/packages/firebase_performance>

## Firebase Crashlytics

- حزمة `firebase_crashlytics` الرسمية تعلن منصات Android وiOS وmacOS، ولا تعرض دعم Flutter Web. لذلك لن تُضاف إلى نسخة YS.JOB المنشورة على GitHub Pages.
- مرجع: <https://pub.dev/packages/firebase_crashlytics>

## ضوابط الخصوصية

- لا تسجل traces أو attributes البريد الإلكتروني أو الهاتف أو UID أو نصوص رسائل الخطأ أو روابط السيرة الذاتية.
- تقتصر أسماء القياسات على تدفقات المنتج العامة، مثل `app_boot` و`jobs_initial_load` و`company_directory_load` و`auth_sign_in` و`profile_save`.
