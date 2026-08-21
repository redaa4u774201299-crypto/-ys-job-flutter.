import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/seeker/presentation/pages/job_details_page.dart';
import 'package:ys_job/shared/models/job_model.dart';

void main() {
  final job = JobModel(
    id: 'job-42',
    employerId: 'employer-1',
    employerName: 'شركة يمنية',
    title: 'محلل بيانات',
    description: 'وصف اختبار لتدفق التأكيد.',
    location: 'صنعاء',
    jobType: 'دوام كامل',
    salaryRange: 'حسب الاتفاق',
    isFeatured: false,
    postedAt: DateTime.utc(2026, 8, 21),
  );

  Future<bool?> openDialog(WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showApplyConfirmationDialog(context, job);
            },
            child: const Text('افتح التأكيد'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('افتح التأكيد'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('يعرض الحوار بيانات الوظيفة ويلغي التقديم صراحة', (tester) async {
    final result = await openDialog(tester);

    expect(result, isNull);
    expect(find.text('تأكيد التقديم'), findsNWidgets(2));
    expect(find.textContaining('محلل بيانات'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
  });

  testWidgets('يعيد true عند تأكيد المستخدم لطلب التقديم', (tester) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              confirmed = await showApplyConfirmationDialog(context, job);
            },
            child: const Text('افتح التأكيد'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('افتح التأكيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد التقديم').last);
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });
}
