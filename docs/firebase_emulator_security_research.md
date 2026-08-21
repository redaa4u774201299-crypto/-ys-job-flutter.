# مرجع بحث: أمان Firestore وFirebase Emulator

## مصادر رسمية

1. [اختبار قواعد أمان Cloud Firestore](https://firebase.google.com/docs/firestore/security/test-rules-emulator)
   - يحمّل Emulator القواعد من المسار المعيّن في `firebase.json`.
   - يُشغّل عبر `firebase emulators:start --only firestore` أو يدمج مع الاختبارات عبر `firebase emulators:exec --only firestore "<command>"`.
   - توصي Firebase بمكتبة `@firebase/rules-unit-testing` لاختبار القواعد مع سياقات مصادقة وهمية دون لمس الإنتاج.
   - توفر المكتبة `authenticatedContext` و`unauthenticatedContext` و`assertSucceeds` و`assertFails` و`withSecurityRulesDisabled` و`clearFirestore`.

2. [اختبارات وحدة Firebase Security Rules](https://firebase.google.com/docs/rules/unit-tests)
   - يجب مسح بيانات Emulator بين الاختبارات لتجنب اعتماد النتائج على تشغيل سابق.
   - تحميل القواعد أو ضبط مسارها يمنع Emulator من البدء بقواعد مفتوحة.

3. [تقييد حقول مستند Firestore](https://firebase.google.com/docs/firestore/security/rules-fields)
   - قواعد Firestore لا تقرأ حقولًا جزئية؛ فصل البيانات العامة عن الخاصة في مستندات أو مجموعات مختلفة هو النهج الآمن.
   - يمكن استخدام `keys().hasOnly(...)` و`keys().hasAll(...)` لقائمة حقول مسموحة/مطلوبة عند الإنشاء، و`diff(...).affectedKeys().hasOnly(...)` لتقييد تعديلات الحقول.

4. [المعاملات والدفعات الذرية في Firestore](https://firebase.google.com/docs/firestore/manage-data/transactions)
   - الدفعات الذرية تطبق كل الكتابات أو لا تطبق أيًا منها؛ رفض قاعدة لمسار واحد يفشل العملية كاملة.
   - العمليات الذرية الخاضعة للقواعد تخضع لحد 20 استدعاء وصول إلى المستندات لكامل العملية، إضافة إلى حد 10 لكل عملية مفردة.

## ملاحظة للمشروع

في `ProfileRepository._writeEmployerPayload` تُكتب وثيقتا `users/{uid}` و`company_directory/{uid}` عبر `WriteBatch` واحد. أما تزامن الصور المصغرة للوظائف فيتم لاحقًا في دفعات مستقلة، ولا يدخل ضمن ذرية ملف الشركة ودليل الشركات.
