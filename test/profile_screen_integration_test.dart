import 'dart:async';

import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:ys_job/core/firebase/firebase_runtime.dart';
import 'package:ys_job/features/auth/data/auth_service.dart';
import 'package:ys_job/features/profile/data/profile_repository.dart';
import 'package:ys_job/features/profile/presentation/pages/profile_page.dart';
import 'package:ys_job/features/profile/presentation/widgets/image_crop_dialog.dart';
import 'package:ys_job/shared/models/user_model.dart';

void main() {
  const profileId = 'profile-integration-seeker';
  final profile = UserModel(
    id: profileId,
    name: 'باحث اختبار',
    email: 'profile.integration@example.com',
    role: UserRole.seeker,
    createdAt: DateTime.utc(2026, 8, 20),
    bio: 'نبذة مهنية',
    phone: '777000000',
    jobTitle: 'مطور تطبيقات',
    skills: const ['Flutter'],
  );

  Future<FakeFirebaseFirestore> seededFirestore() async {
    final firestore = FakeFirebaseFirestore();
    await firestore
        .collection('users')
        .doc(profileId)
        .set(profile.toFirestore());
    return firestore;
  }

  MockFirebaseAuth signedInAuth() => MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: profileId, email: profile.email),
  );

  Widget buildProfileHarness({
    required FakeFirebaseFirestore firestore,
    required MockFirebaseAuth auth,
    required ProfileRepository repository,
  }) => ProviderScope(
    overrides: [
      firebaseRuntimeProvider.overrideWithValue(const FirebaseRuntime.ready()),
      authServiceProvider.overrideWithValue(AuthService(auth, firestore)),
      authStateProvider.overrideWith((_) => Stream.value(auth.currentUser)),
      profileRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: ProfilePage()),
      ),
    ),
  );

  testWidgets(
    'تكامل شاشة الملف الشخصي: يحفظ نموذج الباحث في Firestore ويؤكد المزامنة',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final firestore = await seededFirestore();
      final auth = signedInAuth();
      final repository = ProfileRepository(
        firestore,
        auth,
        waitForPendingWrites: () async {},
      );

      await tester.pumpWidget(
        buildProfileHarness(
          firestore: firestore,
          auth: auth,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ملفي الشخصي'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'باحث محدث');
      await tester.enterText(
        find.byType(TextFormField).at(5),
        'https://drive.google.com/file/d/profile-cv',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ التغييرات'));
      await tester.pumpAndSettle();

      final saved = await firestore.collection('users').doc(profileId).get();
      expect(saved.data()?['name'], 'باحث محدث');
      expect(
        saved.data()?['cvUrl'],
        'https://drive.google.com/file/d/profile-cv',
      );
      expect(find.text('تم حفظ بيانات الملف الشخصي.'), findsOneWidget);
    },
  );

  testWidgets(
    'تكامل شاشة الملف الشخصي: يوضح الحفظ المحلي ويعيد محاولة مزامنة Firestore',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final firestore = await seededFirestore();
      final auth = signedInAuth();
      final pendingWrite = Completer<void>();
      var syncChecks = 0;
      final repository = ProfileRepository(
        firestore,
        auth,
        syncConfirmationTimeout: Duration.zero,
        waitForPendingWrites: () {
          syncChecks += 1;
          return pendingWrite.future;
        },
      );

      await tester.pumpWidget(
        buildProfileHarness(
          firestore: firestore,
          auth: auth,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'باحث محفوظ محليًا',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ التغييرات'));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      final saved = await firestore.collection('users').doc(profileId).get();
      expect(saved.data()?['name'], 'باحث محفوظ محليًا');
      expect(find.textContaining('حُفظت التغييرات محليًا'), findsWidgets);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      expect(syncChecks, 2);
      expect(find.textContaining('حُفظت التغييرات محليًا'), findsWidgets);
    },
  );

  testWidgets('إلغاء القص يعيد نتيجة فارغة ولا يعدّل ملف Firestore', (
    tester,
  ) async {
    final firestore = await seededFirestore();
    final before = await firestore.collection('users').doc(profileId).get();
    final source = img.Image(width: 120, height: 120);
    img.fill(source, color: img.ColorRgb8(217, 164, 65));
    final sourceBytes = Uint8List.fromList(img.encodePng(source));
    Uint8List? cropResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => FilledButton(
                  onPressed: () async {
                    cropResult = await showDialog<Uint8List>(
                      context: context,
                      builder: (_) => ImageCropDialog(
                        imageBytes: sourceBytes,
                        imageLabel: 'الصورة الشخصية',
                      ),
                    );
                  },
                  child: const Text('فتح القص'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('فتح القص'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('قص الصورة الشخصية'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pump(const Duration(milliseconds: 300));

    final after = await firestore.collection('users').doc(profileId).get();
    expect(cropResult, isNull);
    expect(after.data(), equals(before.data()));
  });

  testWidgets('يعرض الملف الشخصي خروجًا مؤكدًا وينهي جلسة الباحث', (
    tester,
  ) async {
    final firestore = await seededFirestore();
    final auth = signedInAuth();
    final repository = ProfileRepository(
      firestore,
      auth,
      waitForPendingWrites: () async {},
    );

    await tester.pumpWidget(
      buildProfileHarness(
        firestore: firestore,
        auth: auth,
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    final signOutButton = find.widgetWithText(OutlinedButton, 'تسجيل الخروج');
    await tester.ensureVisible(signOutButton);
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();
    expect(find.text('هل تريد تسجيل الخروج من حسابك الآن؟'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'تسجيل الخروج'),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
  });
}
