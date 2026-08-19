import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/main.dart';

void main() {
  testWidgets('يعرض تطبيق YS.JOB صفحة البداية العربية', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: YSJobApp()));
    await tester.pump();

    expect(find.text('ابحث عن فرصتك القادمة'), findsOneWidget);
    expect(find.text('أحدث الوظائف'), findsOneWidget);
  });
}
