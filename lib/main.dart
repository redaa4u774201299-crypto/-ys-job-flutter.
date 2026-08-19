import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/firebase/firebase_runtime.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_service.dart';

const _firebaseWebOptions = FirebaseOptions(
  apiKey: 'AIzaSyCH8qgMdnPdIQ2PwDRcdQjCbkIS_X2dQPk',
  authDomain: 'ysjob-web.firebaseapp.com',
  projectId: 'ysjob-web',
  storageBucket: 'ysjob-web.firebasestorage.app',
  messagingSenderId: '164448620062',
  appId: '1:164448620062:web:9a3aa08670d9453eb8a80f',
  measurementId: 'G-V7002G6713',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  late final FirebaseRuntime runtime;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: _firebaseWebOptions);
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
