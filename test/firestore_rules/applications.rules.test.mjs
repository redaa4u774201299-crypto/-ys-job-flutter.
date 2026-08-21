import { readFileSync } from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, setDoc } from 'firebase/firestore';
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
});
