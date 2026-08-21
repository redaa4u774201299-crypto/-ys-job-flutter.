import { readFileSync } from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// تستخدم مجموعة مستقلة كي لا تتداخل clearFirestore في هذا الملف مع اختبارات
// company_directory التي تعمل بالتوازي داخل المحاكي نفسه.
const projectId = 'demo-ysjob-applications';
const seekerId = 'seeker-application-1';
const employerId = 'employer-application-1';
const jobId = 'job-application-1';
const applicationId = `${jobId}_${seekerId}`;

let testEnvironment;

async function seedApplicationPrerequisites() {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await setDoc(doc(firestore, 'users', seekerId), {
      id: seekerId,
      role: 'seeker',
      isActive: true,
    });
    await setDoc(doc(firestore, 'users', employerId), {
      id: employerId,
      role: 'employer',
      isActive: true,
    });
    await setDoc(doc(firestore, 'jobs', jobId), {
      id: jobId,
      employerId,
      status: 'active',
    });
  });
}

function applicationPayload(overrides = {}) {
  return {
    id: applicationId,
    jobId,
    seekerId,
    applicantId: seekerId,
    employerId,
    status: 'pending',
    appliedAt: serverTimestamp(),
    ...overrides,
  };
}

function employerNotificationPayload(overrides = {}) {
  return {
    id: 'notification-application-1',
    userId: employerId,
    title: 'طلب تقديم جديد',
    message: 'تلقى إعلان طلب تقديم جديدًا.',
    isRead: false,
    createdAt: serverTimestamp(),
    applicationId,
    ...overrides,
  };
}

beforeAll(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync('firebase/firestore.rules', 'utf8') },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
  await seedApplicationPrerequisites();
});

afterAll(async () => {
  await testEnvironment.cleanup();
});

describe('Firestore application creation rules', () => {
  it('يسمح للباحث النشط بقراءة طلباته عبر applicantId', async () => {
    await testEnvironment.withSecurityRulesDisabled(async (context) => {
      const currentApplication = applicationPayload();
      delete currentApplication.seekerId;
      await setDoc(
        doc(context.firestore(), 'applications', applicationId),
        currentApplication,
      );
    });
    const seeker = testEnvironment.authenticatedContext(seekerId).firestore();

    await assertSucceeds(
      getDocs(
        query(
          collection(seeker, 'applications'),
          where('applicantId', '==', seekerId),
        ),
      ),
    );
  });

  it('يسمح للباحث النشط بإنشاء طلب pending بهوية مقدم وتاريخ خادم صحيحين', async () => {
    const seeker = testEnvironment.authenticatedContext(seekerId).firestore();

    await assertSucceeds(
      setDoc(
        doc(seeker, 'applications', applicationId),
        applicationPayload(),
      ),
    );
  });

  it('يرفض تغيير applicantId إلى مستخدم آخر', async () => {
    const seeker = testEnvironment.authenticatedContext(seekerId).firestore();

    await assertFails(
      setDoc(
        doc(seeker, 'applications', applicationId),
        applicationPayload({ applicantId: 'another-seeker' }),
      ),
    );
  });

  it('يرفض إنشاء طلب ثانٍ للوظيفة نفسها من الباحث نفسه', async () => {
    const seeker = testEnvironment.authenticatedContext(seekerId).firestore();
    const reference = doc(seeker, 'applications', applicationId);

    await assertSucceeds(setDoc(reference, applicationPayload()));
    await assertFails(setDoc(reference, applicationPayload()));
  });

  it('يسمح بإنشاء الطلب وتنبيه الناشر معًا في معاملة واحدة', async () => {
    const seeker = testEnvironment.authenticatedContext(seekerId).firestore();
    const batch = writeBatch(seeker);
    batch.set(doc(seeker, 'applications', applicationId), applicationPayload());
    batch.set(
      doc(seeker, 'notifications', 'notification-application-1'),
      employerNotificationPayload(),
    );

    await assertSucceeds(batch.commit());
  });

  it('يرفض إنشاء تنبيه ناشر منفردًا دون إنشاء طلب جديد في المعاملة نفسها', async () => {
    const seeker = testEnvironment.authenticatedContext(seekerId).firestore();

    await assertFails(
      setDoc(
        doc(seeker, 'notifications', 'notification-application-1'),
        employerNotificationPayload(),
      ),
    );
  });

  it('يرفض تنبيه الطلب الجديد إذا وُجّه إلى مستخدم غير ناشر الوظيفة', async () => {
    const seeker = testEnvironment.authenticatedContext(seekerId).firestore();
    const batch = writeBatch(seeker);
    batch.set(doc(seeker, 'applications', applicationId), applicationPayload());
    batch.set(
      doc(seeker, 'notifications', 'notification-application-1'),
      employerNotificationPayload({ userId: 'another-employer' }),
    );

    await assertFails(batch.commit());
  });
});
