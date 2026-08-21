import { readFileSync } from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, writeBatch } from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

const projectId = 'demo-ysjob';
const employerId = 'employer-1';
const otherEmployerId = 'employer-2';

const publicEntry = {
  id: employerId,
  name: 'شركة الاختبار',
  industry: 'تقنية',
  description: 'وصف عام لا يتضمن معلومات اتصال خاصة.',
  logoThumbBase64: '',
  city: 'صنعاء',
};

let testEnvironment;

async function seedEmployer(id, { companyName = 'شركة سابقة' } = {}) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users', id), {
      id,
      name: id,
      email: '$id@example.test',
      role: 'employer',
      isActive: true,
      companyName,
      industry: 'تقنية',
      bio: 'وصف سابق',
      phone: '',
    });
  });
}

beforeAll(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync('firebase/firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
  await seedEmployer(employerId);
  await seedEmployer(otherEmployerId, { companyName: 'شركة أخرى' });
});

afterAll(async () => {
  await testEnvironment.cleanup();
});

describe('Firestore company_directory security rules', () => {
  it('يعرض الدليل العام فقط ولا يتيح ملف المستخدم الخاص لزائر مجهول', async () => {
    await testEnvironment.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'company_directory', employerId),
        publicEntry,
      );
    });

    const visitor = testEnvironment.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(visitor, 'company_directory', employerId)));
    await assertFails(getDoc(doc(visitor, 'users', employerId)));
  });

  it('يمنع صاحب شركة من كتابة وثيقة دليل شركة أخرى', async () => {
    const otherEmployer = testEnvironment
        .authenticatedContext(otherEmployerId)
        .firestore();

    await assertFails(
      setDoc(doc(otherEmployer, 'company_directory', employerId), publicEntry),
    );
  });

  it('يلتزم بحفظ ملف الشركة والدليل العام معًا في دفعة صحيحة', async () => {
    const employer = testEnvironment.authenticatedContext(employerId).firestore();
    const batch = writeBatch(employer);

    batch.set(
      doc(employer, 'users', employerId),
      {
        companyName: publicEntry.name,
        industry: publicEntry.industry,
        bio: publicEntry.description,
      },
      { merge: true },
    );
    batch.set(doc(employer, 'company_directory', employerId), publicEntry);

    await assertSucceeds(batch.commit());

    await testEnvironment.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      expect((await getDoc(doc(adminDb, 'users', employerId))).data().companyName)
          .toBe(publicEntry.name);
      expect(
        (await getDoc(doc(adminDb, 'company_directory', employerId))).data(),
      ).toEqual(publicEntry);
    });
  });

  it('يرفض الدفعة كاملة إذا تضمنت وثيقة الدليل حقلًا خاصًا', async () => {
    const employer = testEnvironment.authenticatedContext(employerId).firestore();
    const batch = writeBatch(employer);

    batch.set(
      doc(employer, 'users', employerId),
      { companyName: 'لا ينبغي حفظ هذا الاسم' },
      { merge: true },
    );
    batch.set(doc(employer, 'company_directory', employerId), {
      ...publicEntry,
      email: 'private@example.test',
    });

    await assertFails(batch.commit());

    await testEnvironment.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      expect((await getDoc(doc(adminDb, 'users', employerId))).data().companyName)
          .toBe('شركة سابقة');
      expect(
        (await getDoc(doc(adminDb, 'company_directory', employerId))).exists(),
      ).toBe(false);
    });
  });
});
