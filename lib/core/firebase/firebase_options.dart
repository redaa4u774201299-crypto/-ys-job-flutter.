import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// تُمرَّر هذه القيم وقت البناء أو التشغيل عبر --dart-define.
/// لا تُضمَّن بيانات Firebase مفترضة أو تخص مشروعًا آخر في المستودع.
abstract final class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );

  static bool get isConfigured => [
    _apiKey,
    _appId,
    _messagingSenderId,
    _projectId,
    _authDomain,
  ].every((value) => value.trim().isNotEmpty);

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('إعدادات Firebase الحالية مهيأة لنسخة الويب فقط.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _storageBucket,
    measurementId: _measurementId,
  );
}
