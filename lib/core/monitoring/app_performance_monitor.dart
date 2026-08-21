import 'dart:math' as math;

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// أسماء ثابتة وآمنة فقط لقياسات الأداء؛ لا تقبل أسماءً مبنية من مدخلات المستخدم.
const performanceTraceNames = <String>{
  'app_boot',
  'auth_sign_in',
  'jobs_initial_load',
  'company_directory_load',
  'profile_save',
};

/// يوفّر غلافًا قابلًا للاختبار حول Firebase Performance ويمنع تعطل تدفق
/// الأعمال إذا تعذّر إرسال قياس الأداء.
abstract interface class AppPerformanceMonitor {
  Future<PerformanceTraceHandle> startTrace(String name);

  Future<T> measure<T>(
    String name,
    Future<T> Function() operation, {
    int Function(T value)? resultCount,
  });

  Stream<T> measureFirstStream<T>(
    String name,
    Stream<T> stream, {
    int Function(T value)? resultCount,
  });
}

final appPerformanceMonitorProvider = Provider<AppPerformanceMonitor>(
  (_) => const NoopAppPerformanceMonitor(),
);

enum PerformanceTraceOutcome { success, failure, empty, cancelled }

abstract interface class PerformanceTraceHandle {
  Future<void> finish(PerformanceTraceOutcome outcome, {int? resultCount});
}

abstract interface class PerformanceTraceFactory {
  PerformanceTraceAdapter newTrace(String name);
}

abstract interface class PerformanceTraceAdapter {
  Future<void> start();
  Future<void> stop();
  void putAttribute(String name, String value);
  void setMetric(String name, int value);
}

class FirebasePerformanceTraceFactory implements PerformanceTraceFactory {
  FirebasePerformanceTraceFactory(this._performance);

  final FirebasePerformance _performance;

  @override
  PerformanceTraceAdapter newTrace(String name) =>
      FirebasePerformanceTraceAdapter(_performance.newTrace(name));
}

class FirebasePerformanceTraceAdapter implements PerformanceTraceAdapter {
  FirebasePerformanceTraceAdapter(this._trace);

  final Trace _trace;

  @override
  Future<void> start() => _trace.start();

  @override
  Future<void> stop() => _trace.stop();

  @override
  void putAttribute(String name, String value) =>
      _trace.putAttribute(name, value);

  @override
  void setMetric(String name, int value) => _trace.setMetric(name, value);
}

class FirebaseAppPerformanceMonitor implements AppPerformanceMonitor {
  FirebaseAppPerformanceMonitor({
    required this.traceFactory,
    required this.isEnabled,
  });

  final PerformanceTraceFactory traceFactory;
  final bool isEnabled;

  @override
  Future<PerformanceTraceHandle> startTrace(String name) async {
    _validateName(name);
    if (!isEnabled) return const _NoopPerformanceTraceHandle();

    try {
      final trace = _FirebasePerformanceTraceHandle(
        traceFactory.newTrace(name),
      );
      await trace.start();
      return trace;
    } catch (_) {
      // المراقبة اختيارية ويجب ألا توقف مسار المستخدم عند تعذرها.
      return const _NoopPerformanceTraceHandle();
    }
  }

  @override
  Future<T> measure<T>(
    String name,
    Future<T> Function() operation, {
    int Function(T value)? resultCount,
  }) async {
    final trace = await startTrace(name);
    try {
      final value = await operation();
      await trace.finish(
        PerformanceTraceOutcome.success,
        resultCount: resultCount?.call(value),
      );
      return value;
    } catch (_) {
      await trace.finish(PerformanceTraceOutcome.failure);
      rethrow;
    }
  }

  @override
  Stream<T> measureFirstStream<T>(
    String name,
    Stream<T> stream, {
    int Function(T value)? resultCount,
  }) async* {
    final trace = await startTrace(name);
    var resolved = false;
    var completed = false;

    try {
      await for (final value in stream) {
        if (!resolved) {
          resolved = true;
          await trace.finish(
            PerformanceTraceOutcome.success,
            resultCount: resultCount?.call(value),
          );
        }
        yield value;
      }
      completed = true;
    } catch (_) {
      if (!resolved) await trace.finish(PerformanceTraceOutcome.failure);
      rethrow;
    } finally {
      if (!resolved) {
        await trace.finish(
          completed
              ? PerformanceTraceOutcome.empty
              : PerformanceTraceOutcome.cancelled,
        );
      }
    }
  }

  void _validateName(String name) {
    if (!performanceTraceNames.contains(name)) {
      throw ArgumentError.value(name, 'name', 'اسم قياس أداء غير مسموح.');
    }
  }
}

class _FirebasePerformanceTraceHandle implements PerformanceTraceHandle {
  _FirebasePerformanceTraceHandle(this._trace);

  final PerformanceTraceAdapter _trace;
  var _finished = false;

  Future<void> start() => _trace.start();

  @override
  Future<void> finish(
    PerformanceTraceOutcome outcome, {
    int? resultCount,
  }) async {
    if (_finished) return;
    _finished = true;
    try {
      _trace.putAttribute('outcome', outcome.name);
      if (resultCount != null) {
        _trace.setMetric(
          'result_count',
          math.max(0, math.min(resultCount, 9999)),
        );
      }
      await _trace.stop();
    } catch (_) {
      // لا يؤثر تعذر تسجيل القياس في تجربة المستخدم أو نتائج Firestore.
    }
  }
}

class NoopAppPerformanceMonitor implements AppPerformanceMonitor {
  const NoopAppPerformanceMonitor();

  @override
  Future<PerformanceTraceHandle> startTrace(String name) async =>
      const _NoopPerformanceTraceHandle();

  @override
  Future<T> measure<T>(
    String name,
    Future<T> Function() operation, {
    int Function(T value)? resultCount,
  }) => operation();

  @override
  Stream<T> measureFirstStream<T>(
    String name,
    Stream<T> stream, {
    int Function(T value)? resultCount,
  }) => stream;
}

class _NoopPerformanceTraceHandle implements PerformanceTraceHandle {
  const _NoopPerformanceTraceHandle();

  @override
  Future<void> finish(
    PerformanceTraceOutcome outcome, {
    int? resultCount,
  }) async {}
}
