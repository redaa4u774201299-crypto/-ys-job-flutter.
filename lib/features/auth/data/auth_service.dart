import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/models/user_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) {
    throw StateError('Firebase Auth غير مهيأ لهذا المشروع.');
  }
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) {
    throw StateError('Cloud Firestore غير مهيأ لهذا المشروع.');
  }
  return FirebaseFirestore.instance;
});

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseFirestoreProvider),
  ),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

final userProfileProvider = StreamProvider.family<UserModel?, String>(
  (ref, userId) => ref.watch(authServiceProvider).watchProfile(userId),
);

class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// يعتمد Firebase Auth على تخزين المتصفح محليًا عند ضبط Persistence.LOCAL.
  Future<void> configureWebPersistence() async {
    if (kIsWeb) await _auth.setPersistence(Persistence.LOCAL);
  }

  Stream<UserModel?> watchProfile(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.exists ? UserModel.fromFirestore(snapshot) : null,
      );

  Future<AuthSession> loginUser({
    required String email,
    required String password,
  }) async {
    _validateCredentials(email: email, password: password);
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _loadSession(credential.user);
  }

  Future<AuthSession> registerUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _validateRegistration(name: name, email: email, password: password);
    if (role == UserRole.admin) {
      throw StateError('لا يمكن إنشاء حساب إدارة من واجهة التسجيل العامة.');
    }
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('تعذر إنشاء حساب Firebase. حاول مجددًا.');
    }

    final profile = UserModel(
      id: firebaseUser.uid,
      name: name.trim(),
      email: firebaseUser.email ?? email.trim(),
      role: role,
      createdAt: DateTime.now().toUtc(),
    );
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .set(profile.toFirestore());
      return AuthSession(firebaseUser: firebaseUser, profile: profile);
    } catch (_) {
      // يمنع بقاء حساب Firebase جديد بلا ملف مستخدم في Firestore عند فشل الحفظ.
      try {
        await firebaseUser.delete();
      } catch (_) {
        // يبقى الخطأ الأصلي هو الأكثر فائدة للمستخدم؛ يمكن للإدارة معالجة
        // أي حساب يتعذر حذفه من Firebase Console بصورة آمنة.
      }
      rethrow;
    }
  }

  Future<AuthSession> signInWithGoogle() async {
    if (!kIsWeb) {
      throw UnsupportedError('تسجيل Google المدمج في هذه المرحلة مخصص للويب.');
    }
    final credential = await _auth.signInWithPopup(GoogleAuthProvider());
    return _loadSession(credential.user);
  }

  Future<void> signOut() => _auth.signOut();

  Future<AuthSession> _loadSession(User? firebaseUser) async {
    if (firebaseUser == null) {
      throw StateError('تعذر استعادة جلسة المستخدم. سجل الدخول مجددًا.');
    }
    final snapshot = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    if (!snapshot.exists) {
      throw StateError(
        'لا يوجد ملف مستخدم مرتبط بهذا الحساب. أنشئ حسابًا جديدًا أو تواصل مع الإدارة.',
      );
    }
    final profile = UserModel.fromFirestore(snapshot);
    if (!profile.isActive) {
      await _auth.signOut();
      throw StateError('هذا الحساب موقوف. تواصل مع إدارة المنصة.');
    }
    return AuthSession(firebaseUser: firebaseUser, profile: profile);
  }

  void _validateCredentials({required String email, required String password}) {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw const FormatException('أدخل بريدًا إلكترونيًا صحيحًا.');
    }
    if (password.length < 8) {
      throw const FormatException(
        'كلمة المرور يجب أن تتكون من 8 أحرف على الأقل.',
      );
    }
  }

  void _validateRegistration({
    required String name,
    required String email,
    required String password,
  }) {
    if (name.trim().isEmpty) throw const FormatException('الاسم مطلوب.');
    _validateCredentials(email: email, password: password);
  }
}

class AuthSession {
  const AuthSession({required this.firebaseUser, required this.profile});

  final User firebaseUser;
  final UserModel profile;

  String get destination => destinationForRole(profile.role);
}

String destinationForRole(UserRole role) => switch (role) {
  UserRole.admin => '/admin-dashboard',
  UserRole.employer => '/employer-dashboard',
  UserRole.seeker => AppRoutes.seekerDashboard,
};

String authFailureMessage(Object error) {
  if (error is FormatException) return error.message;
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'بيانات الدخول غير صحيحة.',
      'email-already-in-use' => 'هذا البريد مستخدم بالفعل.',
      'weak-password' => 'كلمة المرور ضعيفة. اختر كلمة أقوى.',
      'network-request-failed' => 'تعذر الاتصال بالشبكة. حاول مجددًا.',
      'operation-not-allowed' =>
        'طريقة تسجيل الدخول هذه غير مفعلة في Firebase.',
      'popup-closed-by-user' => 'أُغلقت نافذة تسجيل Google قبل اكتمال العملية.',
      _ => 'تعذر إكمال المصادقة الآن. حاول لاحقًا.',
    };
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'لا تملك صلاحية الوصول إلى ملف المستخدم في Firestore.';
  }
  return 'تعذر إكمال المصادقة الآن. حاول لاحقًا.';
}
