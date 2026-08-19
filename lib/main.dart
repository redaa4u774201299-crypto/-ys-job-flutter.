import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/firebase/firebase_options.dart';
import 'core/firebase/firebase_runtime.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  late final FirebaseRuntime runtime;
  try {
    if (!DefaultFirebaseOptions.isConfigured) {
      throw StateError('لم تُضف إعدادات Firebase الخاصة بمشروع YS.JOB بعد.');
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await AuthService(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
    ).configureWebPersistence();
    runtime = const FirebaseRuntime.ready();
  } catch (_) {
    runtime = const FirebaseRuntime.unavailable(
      'تعذر تهيئة Firebase. أضف إعدادات مشروع YS.JOB الصحيحة ثم أعد بناء نسخة الويب.',
    );
  }

  runApp(
    ProviderScope(
      overrides: [firebaseRuntimeProvider.overrideWithValue(runtime)],
      child: const YSJobApp(),
    ),
  );
}

class YSJobApp extends ConsumerWidget {
  const YSJobApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'YS.JOB',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
