# تأمين Firestore واختبار تزامن `company_directory` محليًا

## الهدف والنطاق

يفصل المشروع بالفعل بين بيانات الملف الخاص في `users` والبيانات العامة في `company_directory`. هذا الفصل ليس تحسينًا شكليًا؛ فقراءات Firestore تكون للمستند كاملاً أو لا تكون، ولا تستطيع القواعد إخفاء حقل واحد من مستند تمت إتاحة قراءته. لذلك يجب أن تظل `company_directory` **إسقاطًا عامًا محدودًا**، لا نسخة من ملف المستخدم. [1]

تكتب الدالة `ProfileRepository._writeEmployerPayload` وثيقتَي `users/{uid}` و`company_directory/{uid}` ضمن `WriteBatch` واحد. وهذا يعني أن Firestore يطبّق العمليتين معًا أو يرفضهما معًا؛ أما مزامنة الصورة المصغرة للوظائف فهي عملية لاحقة منفصلة، وليست جزءًا من هذا الضمان الذري. [2]

## 1. تضييق قاعدة `company_directory`

القاعدة الحالية تسمح لأي مستخدم مسجّل بكتابة أي حقول في وثيقة دليله الخاصة. رغم أن المعرّف مقيد بمالكه، قد يضيف العميل حقولًا حساسة مثل `email` أو `phone` إلى مستند متاح للعامة. يجب استبدالها بقائمة حقول مسموحة وقائمة حقول مطلوبة والتحقق من أنواع النصوص وأطوالها. توصي Firebase باستخدام `hasOnly()` و`hasAll()` للإنشاء و`diff().affectedKeys()` للتحديث المقيد. [1]

ضع هذه الدالة داخل كتلة `match /databases/{database}/documents` ثم استبدل قاعدة `company_directory` الحالية. اخترت الحدود التالية كحدود دفاعية؛ عدّلها فقط إذا تغيرت سياسة محتوى المنتج أو خوارزمية الصور المصغرة.

```rules
function isSafeCompanyDirectoryEntry(companyId) {
  return request.resource.data.keys().hasAll([
           'id', 'name', 'industry', 'description',
           'logoThumbBase64', 'city'
         ]) &&
         request.resource.data.keys().hasOnly([
           'id', 'name', 'industry', 'description',
           'logoThumbBase64', 'city'
         ]) &&
         request.resource.data.id == companyId &&
         request.resource.data.name is string &&
         request.resource.data.name.size() <= 120 &&
         request.resource.data.industry is string &&
         request.resource.data.industry.size() <= 100 &&
         request.resource.data.description is string &&
         request.resource.data.description.size() <= 2000 &&
         request.resource.data.city is string &&
         request.resource.data.city.size() <= 80 &&
         request.resource.data.logoThumbBase64 is string &&
        request.resource.data.logoThumbBase64.size() <= 16384;
}

match /company_directory/{companyId} {
  allow read: if true;

  allow create, update: if
    isSafeCompanyDirectoryEntry(companyId) &&
    (
      isAdmin() ||
      (isEmployer() && request.auth.uid == companyId)
    );

  allow delete: if isAdmin() ||
    (isEmployer() && request.auth.uid == companyId);
}
```

هذا التغيير يجعل أي محاولة لإضافة `email` أو `phone` أو `logoBase64` أو أي مفتاح جديد مرفوضة بالكامل، حتى لو صدرت من صاحب وثيقة الدليل. كما ينبغي إزالة `email` من قائمة الحقول القابلة للتعديل ذاتيًا في قاعدة `users` ما لم تكن واجهة التطبيق تغيّر بريد Firebase Authentication نفسه ضمن تدفق موثوق؛ وجود بريد في Firestore قابل للتحرير من العميل قد يسبب اختلافًا عن هوية Firebase Auth.

إذا كانت سياسات المنصة تقتضي إخفاء الشركات غير النشطة، فاحرص على حذف وثيقة الدليل أو تحديث حالة عامة مخصصة عند تعطيل صاحب العمل بواسطة الإدارة. لا تعتمد على إخفاء الشركة في الواجهة فقط. وتأكد قبل جعل حقل الحالة عامًا أنه ليس حساسًا ولا يمكن للعميل تغييره ذاتيًا.

## 2. طبقات دفاع مكملة

| الإجراء | الغرض العملي |
|---|---|
| قائمة حقول عامة صارمة | تمنع إنشاء حقل خاص جديد في مستند يمكن قراءته دون تسجيل دخول. |
| فصل المستندات العامة والخاصة | يمنع تسريب حقول `users` لأن القواعد لا تستطيع منح قراءة جزئية للمستند. [1] |
| قيود الأنواع والأحجام | تمنع حقن أنواع غير متوقعة أو صور مصغرة متضخمة تستهلك الحصة أو تتجاوز حد المستند. |
| منع تعديل `role` و`isActive` و`id` و`createdAt` ذاتيًا | يحافظ على RBAC؛ هذه الحقول يجب أن تتغير من مسار إداري موثوق فقط. |
| اختبارات رفض صريحة | تتحقق من أن المستخدم المجهول، والباحث، وصاحب شركة آخر، ومحاولة إضافة `email` إلى الدليل تُرفض جميعًا. |
| الحساب التجريبي `demo-ysjob` | يمنع اختبارات القواعد من مخاطبة مشروع Firebase الإنتاجي بالخطأ. [3] |

أضف أيضًا في نهاية مجموعة القواعد مطابقة افتراضية دفاعية مثل `match /{document=**} { allow read, write: if false; }`. لا تلغي هذه المطابقة أذونات المطابقات الأخرى لأن الأذونات المتطابقة تجمع منطقيًا، لكنها تجعل كل مسار جديد غير مغطى مرفوضًا صراحةً.

## 3. تجهيز Firebase Emulator

يستخدم المشروع تهيئة `firebase.json` في الجذر. استُخدم المنفذ `8181` بدل `8080` و`8081` لأنهما قد يكونان مشغولين بخادم Flutter Web أو بخدمة محلية أخرى.

أنشئ `firebase.json` في جذر المشروع:

```json
{
  "firestore": {
    "rules": "firebase/firestore.rules"
  },
  "emulators": {
    "firestore": { "port": 8181 },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```

ثم أنشئ ملف `.firebaserc` منفصلاً للاختبارات فقط:

```json
{
  "projects": {
    "default": "demo-ysjob"
  }
}
```

ثبّت أدوات الاختبار محليًا في جذر المشروع أو في مجلد Node مستقل للاختبارات، ثم شغّلها مع Emulator. تشغّل `emulators:exec` المحاكي، تنفذ الاختبار، ثم توقفه تلقائيًا. تحمل المحاكيات القواعد من المسار المحدد في `firebase.json`، ولذلك لا تستخدم قواعد مفتوحة بالخطأ. [3] [4]

```bash
npm install --save-dev firebase-tools @firebase/rules-unit-testing firebase vitest
npx firebase emulators:exec --project demo-ysjob --only firestore \
  "npx vitest run test/firestore_rules/company_directory.rules.test.mjs"
```

لفحص عمليات القواعد بصريًا، شغّل `npx firebase emulators:start --project demo-ysjob --only firestore` ثم افتح واجهة Emulator على `http://127.0.0.1:4000`. تعرض صفحة **Firestore > Requests** نتيجة كل شرط من شروط القاعدة. توفر Firebase كذلك تقرير تغطية للقواعد أثناء تشغيل المحاكي. [3]

## 4. اختبار الذرية وقواعد الوصول

ابدأ باختبارات قواعد JavaScript مستقلة. هذا هو المستوى الأنسب لأن مكتبة `@firebase/rules-unit-testing` تنشئ سياقات مصادقة وهمية وتضمن أن الاختبارات لا تلمس Firebase الإنتاجي. استخدم `withSecurityRulesDisabled` لزرع ملف صاحب العمل الابتدائي فقط، ثم استخدم سياق صاحب العمل لاختبار ما يسمح به العميل فعليًا. امسح بيانات Firestore بين الاختبارات حتى لا تعتمد النتيجة على تشغيل سابق. [3] [4]

ضع المثال التالي في `test/firestore_rules/company_directory.rules.test.mjs` بعد تطبيق القاعدة المشددة أعلاه:

```js
import { readFileSync } from 'node:fs';
import { beforeAll, beforeEach, afterAll, describe, it, expect } from 'vitest';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, writeBatch } from 'firebase/firestore';

const projectId = 'demo-ysjob';
const ownerId = 'employer-1';
let testEnv;

const publicEntry = {
  id: ownerId,
  name: 'شركة مثال',
  industry: 'تقنية',
  description: 'وصف عام قصير',
  logoThumbBase64: '',
  city: 'صنعاء',
};

async function seedEmployer() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users', ownerId), {
      id: ownerId,
      role: 'employer',
      isActive: true,
      name: 'المالك',
      companyName: 'شركة سابقة',
      industry: 'تقنية',
      bio: 'وصف سابق',
      phone: '',
    });
  });
}

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8181,
      rules: readFileSync('firebase/firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedEmployer();
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('company_directory', () => {
  it('يلتزم بكتابة الملف والدليل معًا في دفعة ناجحة', async () => {
    const db = testEnv.authenticatedContext(ownerId).firestore();
    const batch = writeBatch(db);

    batch.set(doc(db, 'users', ownerId), {
      companyName: 'شركة مثال',
      industry: 'تقنية',
      bio: 'وصف عام قصير',
    }, { merge: true });
    batch.set(doc(db, 'company_directory', ownerId), publicEntry);

    await assertSucceeds(batch.commit());

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      expect((await getDoc(doc(adminDb, 'users', ownerId))).data().companyName)
        .toBe('شركة مثال');
      expect((await getDoc(doc(adminDb, 'company_directory', ownerId))).data())
        .toEqual(publicEntry);
    });
  });

  it('يرفض الدفعة بالكامل إذا احتوت وثيقة الدليل على حقل حساس', async () => {
    const db = testEnv.authenticatedContext(ownerId).firestore();
    const batch = writeBatch(db);

    batch.set(doc(db, 'users', ownerId), {
      companyName: 'يجب ألا تُحفظ',
    }, { merge: true });
    batch.set(doc(db, 'company_directory', ownerId), {
      ...publicEntry,
      email: 'private@example.com',
    });

    await assertFails(batch.commit());

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      expect((await getDoc(doc(adminDb, 'users', ownerId))).data().companyName)
        .toBe('شركة سابقة');
      expect((await getDoc(doc(adminDb, 'company_directory', ownerId))).exists())
        .toBe(false);
    });
  });
});
```

الاختبار الثاني هو برهان الذرية المطلوب: عندما ترفض القواعد عملية كتابة `company_directory` بسبب `email`، يجب ألا يتغير `companyName` في `users` أيضًا. تؤكد Firebase أن الكتابات المجمعة إما تنجح كاملة أو لا يُطبق منها شيء. [2]

أضف بعد ذلك حالات رفض منفصلة: قراءة `users/{uid}` من مستخدم مجهول، قراءة ملف مستخدم آخر من باحث، كتابة `company_directory/{otherUid}` من صاحب شركة مختلف، وكتابة حقل `logoBase64` الكامل في الدليل. لا يكفي اختبار النجاح؛ اختبارات الرفض هي التي تحمي من توسع صلاحيات غير مقصود عند تعديل القواعد لاحقًا.

## 5. اختبار التطبيق Flutter نفسه

اختبارات القواعد السابقة تتحقق من الأمان والذرية على مستوى Firestore. لتجربة تدفق الشاشة الفعلي، أضف مفتاح بناء للتطوير فقط يوجه Flutter إلى Firestore Emulator قبل أي قراءة أو كتابة، ولا تفعله في البناء الإنتاجي. عند اختبار تسجيل الدخول أيضًا، شغّل Auth Emulator على منفذ منفصل، واستخدم حسابات تجريبية محلية فقط. لا توجّه نسخة الإنتاج أو حسابات Firebase الحقيقية إلى Emulator.

ابدأ بجلسة Flutter Web محلية بالمفتاح `--dart-define=USE_FIREBASE_EMULATORS=true`. في تهيئة Firebase، افحص هذا المفتاح ثم استدعِ `FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8181)` قبل إنشاء أي stream أو repository. تتطلب بيئات جهاز مختلفة اسم مضيف مختلفًا؛ فمتصفح محلي على الحاسوب يستخدم `localhost`، بينما محاكي Android يحتاج غالبًا إلى `10.0.2.2` للوصول إلى مضيف الجهاز. احتفظ بهذا الربط خلف مفتاح بناء حتى لا يصل إصدار النشر إلى Emulator.

## المراجع

[1]: https://firebase.google.com/docs/firestore/security/rules-fields "Firebase: Control access to specific fields"
[2]: https://firebase.google.com/docs/firestore/manage-data/transactions "Firebase: Transactions and batched writes"
[3]: https://firebase.google.com/docs/firestore/security/test-rules-emulator "Firebase: Test your Cloud Firestore Security Rules"
[4]: https://firebase.google.com/docs/rules/unit-tests "Firebase: Build unit tests for Security Rules"
