import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/core/monitoring/app_performance_monitor.dart';

void main() {
  group('FirebaseAppPerformanceMonitor', () {
    test('يسجل نجاح العملية وعدد النتائج دون تجاوز الحد الآمن', () async {
      final factory = _FakeTraceFactory();
      final monitor = FirebaseAppPerformanceMonitor(
        traceFactory: factory,
        isEnabled: true,
      );

      final result = await monitor.measure(
        'jobs_initial_load',
        () async => List<int>.generate(12000, (index) => index),
        resultCount: (items) => items.length,
      );

      expect(result, hasLength(12000));
      expect(factory.trace.started, isTrue);
      expect(factory.trace.stopped, isTrue);
      expect(factory.trace.attributes, {'outcome': 'success'});
      expect(factory.trace.metrics, {'result_count': 9999});
    });

    test('يسجل فشل العملية ثم يعيد رمي الخطأ الأصلي', () async {
      final factory = _FakeTraceFactory();
      final monitor = FirebaseAppPerformanceMonitor(
        traceFactory: factory,
        isEnabled: true,
      );

      await expectLater(
        monitor.measure<void>(
          'auth_sign_in',
          () async => throw StateError('auth failed'),
        ),
        throwsStateError,
      );

      expect(factory.trace.attributes, {'outcome': 'failure'});
      expect(factory.trace.stopped, isTrue);
    });

    test('ينهي قياس أول استجابة من stream بعد وصول القائمة', () async {
      final factory = _FakeTraceFactory();
      final monitor = FirebaseAppPerformanceMonitor(
        traceFactory: factory,
        isEnabled: true,
      );

      final values = await monitor
          .measureFirstStream(
            'company_directory_load',
            Stream.value(<String>['company-a', 'company-b']),
            resultCount: (companies) => companies.length,
          )
          .toList();

      expect(values, [
        <String>['company-a', 'company-b'],
      ]);
      expect(factory.trace.attributes, {'outcome': 'success'});
      expect(factory.trace.metrics, {'result_count': 2});
      expect(factory.trace.stopped, isTrue);
    });

    test('يرفض اسم trace غير ثابت أو مبني من مدخلات المستخدم', () async {
      final monitor = FirebaseAppPerformanceMonitor(
        traceFactory: _FakeTraceFactory(),
        isEnabled: true,
      );

      await expectLater(
        monitor.startTrace('profile_ali@example.com'),
        throwsArgumentError,
      );
    });
  });
}

class _FakeTraceFactory implements PerformanceTraceFactory {
  final _FakeTrace trace = _FakeTrace();

  @override
  PerformanceTraceAdapter newTrace(String name) => trace;
}

class _FakeTrace implements PerformanceTraceAdapter {
  bool started = false;
  bool stopped = false;
  final Map<String, String> attributes = <String, String>{};
  final Map<String, int> metrics = <String, int>{};

  @override
  void putAttribute(String name, String value) => attributes[name] = value;

  @override
  void setMetric(String name, int value) => metrics[name] = value;

  @override
  Future<void> start() async => started = true;

  @override
  Future<void> stop() async => stopped = true;
}
