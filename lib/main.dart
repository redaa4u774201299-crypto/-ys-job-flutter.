import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/firebase/firebase_runtime.dart';
import 'core/monitoring/app_performance_monitor.dart';
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
  AppPerformanceMonitor performanceMonitor = const NoopAppPerformanceMonitor();
  PerformanceTraceHandle? appBootTrace;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: _firebaseWebOptions);
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 20 * 1024 * 1024,
      webPersistentTabManager: WebPersistentMultipleTabManager(),
    );
    await AuthService(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
    ).configureWebPersistence();
    runtime = const FirebaseRuntime.ready();
    try {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        kReleaseMode,
      );
      performanceMonitor = FirebaseAppPerformanceMonitor(
        traceFactory: FirebasePerformanceTraceFactory(
          FirebasePerformance.instance,
        ),
        isEnabled: kReleaseMode,
      );
      appBootTrace = await performanceMonitor.startTrace('app_boot');
    } catch (_) {
      // يبقى التطبيق متاحًا حتى إذا كانت خدمة مراقبة الأداء غير متاحة.
    }
  } catch (_) {
    runtime = const FirebaseRuntime.unavailable(
      'تعذر تهيئة Firebase. أضف إعدادات مشروع YS.JOB الصحيحة ثم أعد بناء نسخة الويب.',
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        firebaseRuntimeProvider.overrideWithValue(runtime),
        appPerformanceMonitorProvider.overrideWithValue(performanceMonitor),
      ],
      child: const YSJobApp(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      appBootTrace?.finish(PerformanceTraceOutcome.success) ?? Future.value(),
    );
  });
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
