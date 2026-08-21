# دليل الرفع والنشر الإنتاجي — YS.JOB

**المالك:** Hudifah  
**المشروع:** `ys-job-flutter`  
**المستودع:** `redaa4u774201299-crypto/-ys-job-flutter.`  
**تاريخ المراجعة:** 21 أغسطس 2026

> هذا الدليل يضبط الرفع النهائي للتطبيق دون تخزين رموز GitHub أو Firebase في المستودع أو في عنوان `origin`. كما يفصل عمدًا بين محاكي Firestore المحلي ومشروع Firebase الإنتاجي `ysjob-web`.

## حالة الجاهزية الحالية

| المجال | الحالة | التحقق المتاح |
|---|---|---|
| تطبيق Flutter Web | جاهز للبناء | تشغيل تحليل Flutter، الاختبارات، وبناء `build/web` محليًا وضمن CI. |
| النشر إلى GitHub Pages | مهيأ في المستودع | الملف `.github/workflows/flutter-web-ci.yml` يبني التطبيق بمسار المستودع ثم يرفع artifact وينشره بعد نجاح بوابة التحقق. |
| حماية قواعد Firestore | مهيأة ومختبرة محليًا | اختبارات Emulator تستخدم المشروع المعزول `demo-ysjob` ولا تتصل ببيانات الإنتاج. |
| دليل الشركات العام | مفصول عن الحسابات الخاصة | القراءة العامة تقع على `company_directory` فقط، بينما تبقى `users` محمية بالحساب أو الإدارة. |
| قواعد الإنتاج | **تحتاج نشرًا يدويًا** | لا ينشر أي مسار CI القواعد إلى Firebase الإنتاجي تلقائيًا. |
| الدفع إلى GitHub | يحتاج صلاحية كتابة صالحة | لا توجد بيانات اعتماد في رابط `origin` المحلي. |

## قبل الدفع إلى GitHub

نفّذ التحقق المحلي من جذر المشروع. لا تستخدم رمز وصول داخل عنوان المستودع، ولا تضفه إلى ملف أو سجل أو أمر محفوظ في التاريخ.

```bash
cd /home/ubuntu/ys-job-flutter
git status
npm run test:firestore-rules
/home/ubuntu/flutter-sdk/bin/flutter format --set-exit-if-changed lib test
/home/ubuntu/flutter-sdk/bin/flutter analyze
/home/ubuntu/flutter-sdk/bin/flutter test
/home/ubuntu/flutter-sdk/bin/flutter build web --release --no-tree-shake-icons --base-href=/-ys-job-flutter./
```

إذا ظهرت رموز وصول سابقة في عنوان `origin` أو في سجل طرفي مشترك، يجب إبطالها من GitHub وإنشاء رمز جديد بأقل نطاق لازم. تُستخدم مصادقة GitHub CLI أو مدير بيانات الاعتماد المحلي عند الدفع، مع إبقاء العنوان البعيد بالشكل التالي فقط:

```bash
git remote set-url origin https://github.com/redaa4u774201299-crypto/-ys-job-flutter..git
git push -u origin main
```

## كيفية عمل CI/CD الحالي

يعمل المسار `.github/workflows/flutter-web-ci.yml` عند كل `push` أو `pull_request` إلى `main`، ويدعم التشغيل اليدوي من صفحة Actions. يعمل النشر فقط بعد دفع ناجح إلى `main` وبعد اكتمال جميع بوابات التحقق.

| الترتيب | خطوة CI | الغرض | يمنع النشر عند الفشل |
|---|---|---|---|
| 1 | `npm ci` ثم تنزيل Emulator | تجهيز بيئة اختبار قواعد Firestore. | نعم |
| 2 | `npm run test:firestore-rules` | تشغيل اختبارات الصلاحيات على محاكي Firestore المعزول. | نعم |
| 3 | `flutter pub get` و`dart format` و`flutter analyze` | توحيد الصياغة والتحليل الساكن. | نعم |
| 4 | `flutter test` و`flutter test --platform chrome` | اختبار منطق Flutter وتدفقات المتصفح. | نعم |
| 5 | `flutter build web --base-href=/-ys-job-flutter./` | بناء نسخة Web الملائمة لمسار GitHub Pages الخاص بالمستودع. | نعم |
| 6 | `upload-pages-artifact` ثم `deploy-pages` | رفع البناء ونشره في بيئة `github-pages`. | لا يبدأ قبل نجاح كل ما سبق |

تنص GitHub على أن نشر Pages عبر مسار مخصص يحتاج artifact ومرحلة نشر تملك `pages: write` و`id-token: write` وتعتمد على مهمة البناء عبر `needs`؛ وهذه الشروط مطبقة في المسار الحالي.[1]

## تفعيل GitHub Pages بعد أول Push

بعد دفع `main` بنجاح، افتح المستودع في GitHub ثم انتقل إلى **Settings → Pages**. في قسم **Build and deployment** اختر **Source: GitHub Actions**. لا تختَر النشر من فرع، لأن التطبيق يحتاج عملية Flutter build وartifact مخصصين.[2]

بعد ظهور تشغيل ناجح باسم **Flutter Web CI**، افتح مهمة **Deploy Flutter Web to GitHub Pages** واقرأ رابط البيئة المنشور. العنوان المتوقع للمستودع الحالي هو:

```text
https://redaa4u774201299-crypto.github.io/-ys-job-flutter./
```

يجب الإبقاء على `--base-href=/-ys-job-flutter./` عند البناء؛ تغيير اسم المستودع أو تحويل النشر إلى نطاق مخصص يتطلب تعديل هذا المسار ثم التحقق من الروابط والتنقل.

لرفع مستوى الحماية، تُضبط قاعدة حماية للفرع `main` في **Settings → Branches** بحيث تتطلب نجاح مسار **Flutter Web CI** قبل الدمج. أما مفاتيح Slack وTelegram فهي اختيارية وتضاف فقط كـ GitHub Actions Secrets، ولا توضع داخل ملفات YAML أو كود Flutter.

## قواعد Firestore لدليل الشركات في الإنتاج

تطبق القواعد الحالية مبدأ **الفصل بين البيانات العامة والخاصة**. لا تستطيع قواعد Firestore إرجاع جزء من مستند وإخفاء الحقول الأخرى؛ فقراءة Firestore تعيد المستند كاملًا أو ترفضه. لذلك يحفظ التطبيق بطاقة الشركة العامة في مجموعة مستقلة هي `company_directory` بدل السماح بقراءة مستندات `users` الخاصة للزوار.[3]

| المجموعة | من يقرأها | من يكتبها | الحماية الفعلية |
|---|---|---|---|
| `users/{uid}` | المستخدم نفسه أو المدير النشط | مالك الحساب ضمن حقول ملفه المسموحة، أو المدير | يمنع كشف الهاتف والبريد والسيرة الذاتية وصورة الملف الكاملة للزوار. |
| `company_directory/{uid}` | الجميع | مدير نشط أو صاحب عمل نشط يملك نفس `uid` | قائمة حقول مغلقة: `id`, `name`, `industry`, `description`, `logoThumbBase64`, `city`، مع حدود للنوع والحجم. |
| `jobs/{jobId}` | زوار التطبيق | صاحب العمل المالك أو المدير وفق القاعدة | يظل المالك والتمييز محميين على مستوى الكتابة. |

القواعد الخاصة بالدليل تستخدم `hasAll()` و`hasOnly()` لتطلب الحقول العامة وتمنع أي حقل إضافي، وتستخدم `diff().affectedKeys().hasOnly()` لتقييد تغييرات المستند. هذا النمط هو أسلوب Firebase الموصى به للائحة حقول الإنشاء والتحديث.[4]

### اختبار القواعد قبل الإنتاج

شغّل هذا الأمر محليًا أولًا:

```bash
cd /home/ubuntu/ys-job-flutter
npm run test:firestore-rules
```

الاختبار يستخدم `firebase emulators:exec --project demo-ysjob --only firestore`، ولذلك لا يقرأ أو يكتب في مشروع `ysjob-web` الحقيقي. تغطي المجموعة الحالية على الأقل: قراءة الدليل للزائر، منع قراءة ملفات المستخدمين الخاصة، منع كتابة غير المالك، رفض الحقول الحساسة، والتزامن الذري بين الملف والدليل.

### نشر القواعد على مشروع Firebase الحقيقي

لا يُنفذ هذا الإجراء تلقائيًا. بعد نجاح الاختبارات ومراجعة الفرق في `firebase/firestore.rules`، توجد طريقتان فقط للنشر:

| الطريقة | الخطوات | متى تستخدم |
|---|---|---|
| Firebase Console | افتح مشروع `ysjob-web` → **Firestore Database → Rules** → انسخ محتوى `firebase/firestore.rules` → استخدم **Rules Playground** للسيناريوهات الحساسة → اضغط **Publish**. | الخيار الأنسب للمراجعة اليدوية الأولى. |
| Firebase CLI | بعد تسجيل الدخول بالحساب الذي يملك المشروع، نفّذ: `npx firebase-tools deploy --only firestore:rules --project ysjob-web`. | عند اعتماد إجراء إصدار موثق ومراجع. |

ينشر Firebase CLI محتوى ملف القواعد المحلي بدل القواعد الموجودة في Console، ولذلك يجب تجنب التحرير المتوازي أو تثبيت المصدر المعتمد في Git قبل النشر.[5]

> لا تغيّر ملف `.firebaserc` الحالي إلى مشروع الإنتاج بغرض الاختبار؛ فهو مضبوط عمدًا على `demo-ysjob` لحماية بيانات الإنتاج من الأوامر المحلية. استخدم الوسيط الصريح `--project ysjob-web` فقط في خطوة النشر التي تمت مراجعتها.

## قائمة قرار الإصدار

| بند القرار | المسؤول | معيار الاكتمال |
|---|---|---|
| مراجعة تغييرات Git | مالك المشروع | لا توجد مفاتيح أو ملفات سرية أو تغييرات غير مقصودة. |
| نجاح البوابة المحلية | المطور | تنجح أوامر اختبار القواعد وFlutter والبناء. |
| دفع `main` | مالك صلاحية المستودع | يظهر تشغيل CI في GitHub دون فشل. |
| تفعيل Pages | مدير المستودع | مصدر النشر هو GitHub Actions وتظهر بيئة `github-pages`. |
| اختبار الموقع المنشور | مالك المشروع | تعمل المصادقة العامة والوظائف والدليل ومسارات التنقل من رابط Pages. |
| مراجعة قواعد الإنتاج | مدير Firebase | تمر حالات Playground، ثم تُنشر القواعد يدويًا. |
| متابعة التنبيه | مدير المستودع | تُراجع تذكرة `security-ci` إن فشلت بوابة القواعد؛ ويبقى Slack/Telegram اختياريين. |

## مراجع

[1]: https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages "GitHub Docs — Using custom workflows with GitHub Pages"
[2]: https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site "GitHub Docs — Configuring a publishing source for your GitHub Pages site"
[3]: https://firebase.google.com/docs/firestore/security/rules-fields "Firebase — Control access to specific fields"
[4]: https://firebase.google.com/docs/firestore/security/rules-fields "Firebase — Field allowlists and update diffs"
[5]: https://firebase.google.com/docs/rules/manage-deploy "Firebase — Manage and deploy Security Rules"
