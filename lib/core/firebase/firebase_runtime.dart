import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class FirebaseRuntime {
  const FirebaseRuntime._({required this.isReady, this.message});

  const FirebaseRuntime.ready() : this._(isReady: true);

  const FirebaseRuntime.unavailable(String message)
    : this._(isReady: false, message: message);

  final bool isReady;
  final String? message;
}

/// تُستبدل هذه القيمة عند تشغيل التطبيق بعد نجاح Firebase.initializeApp().
final firebaseRuntimeProvider = Provider<FirebaseRuntime>(
  (ref) => const FirebaseRuntime.unavailable(
    'لم تُضف إعدادات Firebase الخاصة بالمشروع بعد.',
  ),
);
