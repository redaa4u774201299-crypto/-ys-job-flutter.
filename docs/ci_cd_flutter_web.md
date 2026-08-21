# التكامل المستمر والنشر الآلي لـ Flutter Web

أُضيف ملف سير العمل `.github/workflows/flutter-web-ci.yml` ليجعل تحقق Flutter Web جزءًا تلقائيًا من دورة التطوير. عند ربط هذا المستودع بـ GitHub، يبدأ سير العمل عند فتح أو تحديث طلب دمج موجّه إلى الفرع `main`، وعند الدفع إلى `main`، أو يدويًا من تبويب **Actions**. تعتمد هذه المشغلات على أحداث المستودع القياسية في GitHub Actions.[1]

## ما الذي يتحقق منه المسار؟

| المرحلة            | الغرض                                                                            | يمنع دمج                                             |
| ------------------ | -------------------------------------------------------------------------------- | ---------------------------------------------------- |
| اختبارات قواعد Firestore | تثبيت اعتماديات Node وتشغيل Firebase Emulator مع اختبارات `company_directory` | توسيع الصلاحيات أو تسريب الحقول الخاصة أو كسر الذرية |
| استعادة الاعتمادات | تنفيذ `flutter pub get` من ملف القفل                                             | اختلاف الاعتمادات بين الجهاز والخادم                 |
| تنسيق Dart         | تنفيذ `dart format --set-exit-if-changed lib test`                               | إدخال كود غير منسق                                   |
| التحليل الساكن     | تنفيذ `flutter analyze`                                                          | أخطاء النوع والاستيراد والتحذيرات التحليلية          |
| اختبارات Dart      | تنفيذ `flutter test`                                                             | كسر منطق النماذج والمعالجة والتدفقات المختبرة        |
| اختبارات المتصفح   | تنفيذ `flutter test --platform chrome` مع اختيار تلقائي لمسار Chrome أو Chromium | اختلافات سلوك الويب عن بيئة Dart الافتراضية          |
| بناء الإنتاج       | تنفيذ `flutter build web --no-tree-shake-icons --base-href=/-ys-job-flutter./`   | فشل تجميع نسخة الويب أو تحميل أصوله من المسار الخاطئ |
| أثر البناء         | حفظ مجلد `build/web` لمدة سبعة أيام                                              | الحاجة إلى تنزيل ناتج بناء ناجح للفحص اليدوي         |
| حزمة Pages         | تغليف `build/web` كأثر خاص بـ GitHub Pages عند الدفع إلى `main`                  | نشر ملفات ليست ناتج البناء المتحقق منه               |
| نشر Pages          | نشر الحزمة بعد اكتمال وظيفة التحقق بنجاح                                         | نشر نسخة لم تجتز التحليل والاختبارات                 |

حُدّد إصدار Flutter في المسار عند `3.47.1`، وهو الإصدار المستخدم عند إضافة المسار. يستعمل الاختبار المتصفحي متغير `CHROME_EXECUTABLE` لاختيار اسم المتصفح الفعلي تلقائيًا، لذلك لا يعتمد على وجود اسم ثنائي محدد فقط. ناتج البناء يُرفع كأثر قابل للتحميل باستعمال آلية الآثار الرسمية في GitHub Actions.[2]

تبدأ الوظيفة الآن بإعداد Node.js 22 وتنفيذ `npm ci` من `package-lock.json`، ثم تنزيل Cloud Firestore Emulator وتشغيل `npm run test:firestore-rules`. يستخدم هذا الأمر مشروعًا تجريبيًا باسم `demo-ysjob`، ولذلك لا يحتاج بيانات اعتماد Firebase ولا يستطيع الوصول إلى خدمات المشروع الحقيقي غير المحاكية. لا ينتقل المسار إلى Flutter أو إلى بناء Pages إلا بعد اجتياز اختبارات القواعد بنجاح. [4]

## الخيارات المتاحة

| النهج                          | كيف يعمل                                                                                   |                                      الكلفة | تعقيد الإعداد                                 |
| ------------------------------ | ------------------------------------------------------------------------------------------ | ------------------------------------------: | --------------------------------------------- |
| **GitHub Actions — الموصى به** | تشغيل تلقائي لكل طلب دمج ودفع إلى `main`، مع عرض حالة النجاح أو الفشل داخل طلب الدمج       | عادةً ضمن حصة GitHub Actions الخاصة بالحساب | منخفض بعد ربط المستودع                        |
| فحص محلي قبل الدفع             | تشغيل أوامر `flutter analyze` و`flutter test` و`flutter build web` يدويًا أو عبر hook محلي |                   لا توجد كلفة تشغيل سحابية | منخفض، لكنه لا يحمي طلبات الدمج من أجهزة أخرى |

يوفر النهج الأول حارسًا مشتركًا للفريق: لا يعتمد نجاح الدمج على جهاز مطور واحد. أما النهج الثاني فهو بديل خفيف مفيد كتحقق سريع محلي، لكنه لا يحل محل التحقق المركزي.

## النشر التلقائي إلى GitHub Pages

يحتوي مسار العمل الآن على وظيفتين متتاليتين. تتحقق وظيفة **Analyze, test, and build Flutter Web** من الكود وتبني نسخة الويب، ثم ترفع مجلد `build/web` كحزمة GitHub Pages عند الدفع إلى `main` فقط. بعد نجاحها، تنشر وظيفة **Deploy Flutter Web to GitHub Pages** الحزمة نفسها. لا تنفذ وظيفة النشر عند طلبات الدمج أو عند التشغيل اليدوي، ولذلك تظل المراجعة والاختبارات آمنة من أي نشر عرضي.[3]

> يتطلب GitHub Pages وجود الصلاحيتين `pages: write` و`id-token: write` في وظيفة النشر، وربط وظيفة النشر بنتيجة البناء باستخدام `needs`، وبيئة نشر باسم `github-pages`.[3]

بعد رفع الفرع `main` إلى GitHub، افتح المستودع ثم انتقل إلى **Settings → Pages**. في قسم **Build and deployment** اختر **GitHub Actions** كمصدر. بعد أول دفع ناجح إلى `main`، يظهر رابط الموقع ضمن صفحة تشغيل النشر أو قسم Pages، والمتوقع لهذا المستودع هو:

```text
https://redaa4u774201299-crypto.github.io/-ys-job-flutter./
```

يتضمن أمر البناء `--base-href=/-ys-job-flutter./` لأن GitHub Pages ينشر مواقع المستودعات تحت مسار اسم المستودع، وليس تحت جذر النطاق. ويمنع ذلك ظهور صفحة فارغة أو تعذر تحميل JavaScript وملفات الأصول عند فتح التطبيق من الرابط المنشور.

## اختبار قواعد Firestore داخل CI

يحمل `firebase.json` القواعد من `firebase/firestore.rules` ويشغّل المحاكي على المنفذ `8181` محليًا. أما في GitHub Actions فلا يحتاج الاختبار إلى فتح هذا المنفذ أو إدارته يدويًا؛ إذ تتولى `firebase emulators:exec` بدء المحاكي، وحقن عنوانه إلى عملية Vitest، ثم إيقافه حتى عند انتهاء الاختبار بالفشل.

| ملف | مسؤوليته في التحقق المستمر |
|---|---|
| `package.json` و`package-lock.json` | يثبتان إصدارات Firebase Tools ومكتبة اختبار القواعد وVitest. |
| `.firebaserc` | يفرض مشروعًا تجريبيًا `demo-ysjob` لعزل الاختبارات عن الإنتاج. |
| `firebase.json` | يربط المحاكي بملف القواعد الحقيقي للمشروع. |
| `test/firestore_rules/company_directory.rules.test.mjs` | يختبر القراءة العامة المسموح بها، حظر الوصول إلى `users` الخاصة، حظر الكتابة المتقاطعة، وذرية الدفعات عند رفض حقل حساس. |

قبل رفع أي تغيير على القواعد، شغّل محليًا الأمر `npm run test:firestore-rules`. عند فشله، أوقف التعديل بدل توسيع القاعدة لتجاوز الاختبار؛ يجب أن يعكس الاختبار سياسة الوصول المقصودة بدقة. تستخدم اختبارات القواعد مشروعًا تجريبيًا ولا تنشئ أو تغير بيانات Firebase الإنتاجية. [4] [5]

## مراقبة فشل بوابة الأمان

يستمع المسار المستقل `.github/workflows/security-ci-alert.yml` إلى اكتمال **Flutter Web CI**. لا ينشئ إشعارًا عند أي فشل عام؛ بل يستعلم عن مهام التشغيل ويتحقق صراحةً من أن خطوة **Run Firestore Security Rules tests** هي التي فشلت. عند ذلك ينشئ تذكرة GitHub بعلامة `security-ci` أو يضيف تعليقًا إلى التذكرة المفتوحة نفسها بدل تكرار التنبيهات. يؤدي ظهور التذكرة إلى تفعيل إشعارات GitHub المعتادة وفق تفضيلات مالك المستودع ومراقبيه.

لا يفحص مسار التنبيه كود طلب الدمج ولا ينزّل آثاره ولا يستعمل أسرارًا خارجية. يقتصر على بيانات تشغيل Actions وواجهة Issues، ويشترط أن يأتي الفرع من المستودع نفسه قبل منحه صلاحية إنشاء التذكرة. هذه العزلة مهمة لأن سير العمل الذي يبدأ بعد اكتمال سير آخر يحتاج صلاحيات قليلة جدًا ويجب ألا يعيد تنفيذ محتوى غير موثوق. [6] [7]

| أسلوب التنبيه | النتيجة | الإعداد | متى يُفضّل |
| --- | --- | --- | --- |
| **تذكرة GitHub المدمجة — مفعّل** | تذكرة واحدة قابلة للتتبع وتعليقات على الفشل المتكرر | لا أسرار؛ يتطلب السماح لـ`GITHUB_TOKEN` بكتابة Issues | المراقبة الأساسية ومتابعة العلاج داخل المستودع |
| قناة خارجية اختيارية | رسالة فورية إلى Slack أو Teams أو Telegram أو بريد مؤسسي | URL أو رمز قناة محفوظ كـGitHub Secret، مع إخفاء السجلات | عند الحاجة إلى إشعار خارج GitHub أو فريق مناوب |

> قبل إضافة قناة خارجية، احفظ عنوان الـWebhook أو الرمز داخل **Settings → Secrets and variables → Actions** فقط. لا تضعه في YAML أو في سجل Actions، ولا ترسل نصوصًا من سجلات الاختبارات لأنها قد تتضمن سياقًا لا يلزم كشفه. أضف الإرسال إلى مسار التنبيه المستقل فقط، بعد أن ينشئ أو يحدّث التذكرة الداخلية.

### Slack وTelegram كقنوات خارجية اختيارية

لا تتطلب القناتان أي سر لتشغيل بوابة الاختبار أو بناء Flutter. لتفعيلهما، أضف القيم التالية من **Settings → Secrets and variables → Actions** في GitHub؛ لا تضعها في متغير Actions عادي أو ملف `.env` أو أي ملف ضمن المستودع.

| القناة | أسرار GitHub المطلوبة | الاستخدام |
| --- | --- | --- |
| Slack | `SLACK_SECURITY_WEBHOOK_URL` | رابط Incoming Webhook لقناة التنبيهات الأمنية. |
| Telegram | `TELEGRAM_SECURITY_BOT_TOKEN` و`TELEGRAM_SECURITY_CHAT_ID` | روبوت مخصص للتنبيهات ومعرّف قناة أو محادثة التنبيهات. |

يرسل `security-ci-alert.yml` رسالة خارجية فقط بعد تأكيد فشل خطوة **Run Firestore Security Rules tests**. تقتصر الرسالة على رقم التشغيل والفرع والـSHA ورابط التشغيل، وتتخطى GitHub الخطوة تلقائيًا إن غاب السر المطلوب. لا تُطبع قيمة السر أو الحمولة أو رابط Telegram في السجل؛ فإذا ظهر رابط Slack أو رمز Telegram في التزام أو سجل أو لقطة شاشة، ألغِه وأنشئ قيمة بديلة فورًا ثم حدّث GitHub Secret.

## الحارس المحلي قبل الالتزام عبر Husky

يشغّل `.husky/pre-commit` الأمر `npm run test:firestore-rules` تلقائيًا قبل كل `git commit`. وبعد استنساخ المشروع أو تغيّر اعتماديات Node، نفّذ:

```bash
npm ci
```

يفشل الالتزام المحلي إذا فشل المحاكي أو اختبارات القواعد. ولا يغني هذا الحارس عن GitHub Actions؛ إذ تظل بوابة CI هي الحارس الإلزامي قبل الدمج أو النشر.

لا تتجاوز الحارس إلا عند تعذّر المحاكي مؤقتًا وبسبب موثّق:

```bash
HUSKY_SKIP_FIRESTORE_RULES=1 git commit -m "وصف واضح للتجاوز"
```

لا تستخدم `--no-verify` كإجراء اعتيادي. سجّل سبب التجاوز في رسالة الالتزام أو تذكرة مرتبطة، ثم أصلح البيئة أو الاختبار فورًا؛ إذ يظل CI مانعًا للدمج والنشر متى فشلت قواعد Firestore.

## تفعيل مسار التحقق

أُعد رابط `origin` محليًا للمستودع، لكن لم يُرفع فرع `main` بنجاح بعد. بعد رفع الفرع مرة واحدة، سيظهر سير عمل **Flutter Web CI** في تبويب **Actions**. يمكن تشغيل فحوصات CI يدويًا من زر **Run workflow**، أما النشر فيحدث فقط مع دفع جديد إلى `main`.

لجعل نجاح التحقق شرطًا قبل الدمج، فعّل حماية الفرع `main` من إعدادات المستودع، ثم اختر **Require status checks to pass before merging** وحدد فحص **Analyze, test, and build Flutter Web**. لا يتطلب المسار مفاتيح Firebase أو أسرارًا؛ فهو يقتصر على التحليل واختبارات Flutter واختبارات القواعد داخل محاكي معزول والبناء ونشر الملفات الثابتة الناتجة، ولا يكتب في Firestore الإنتاجي.

## تحديث إصدار Flutter

عند ترقية Flutter محليًا، حدّث قيمة `flutter-version` في ملف المسار ليطابق الإصدار المتحقق منه محليًا، ثم شغّل الفحوصات نفسها. إبقاء الإصدار مثبتًا يجعل نتائج CI قابلة للتكرار بدل أن تتغير بسبب انتقال قناة `stable` إلى إصدار أحدث.

## المراجع

[1]: https://docs.github.com/actions/using-workflows/events-that-trigger-workflows "GitHub Docs — Events that trigger workflows"
[2]: https://docs.github.com/en/actions/tutorials/store-and-share-data "GitHub Docs — Store and share data with workflow artifacts"
[3]: https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages "GitHub Docs — Using custom workflows with GitHub Pages"
[4]: https://firebase.google.com/docs/firestore/security/test-rules-emulator "Firebase: Test your Cloud Firestore Security Rules"
[5]: https://firebase.google.com/docs/rules/unit-tests "Firebase: Build unit tests for Security Rules"
[6]: https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#workflow_run "GitHub Docs — workflow_run event"
[7]: https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#permissions "GitHub Docs — Workflow permissions"
[8]: https://docs.github.com/actions/security-guides/using-secrets-in-github-actions "GitHub Docs — Using secrets in GitHub Actions"
[9]: https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks "Slack Docs — Incoming Webhooks"
[10]: https://core.telegram.org/bots/api#sendmessage "Telegram Bot API — sendMessage"
