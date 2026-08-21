import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/shared/models/application_model.dart';

void main() {
  final application = ApplicationModel(
    id: 'job-1_seeker-1',
    jobId: 'job-1',
    seekerId: 'seeker-1',
    employerId: 'employer-1',
    status: ApplicationStatus.pending,
    appliedAt: DateTime.utc(2026, 8, 21, 9),
  );

  test(
    'يكتب مستند التقديم بالهوية الحالية والحالة pending وتاريخ Firestore',
    () {
      final data = application.toFirestore();

      expect(data['jobId'], 'job-1');
      expect(data['applicantId'], 'seeker-1');
      expect(data['seekerId'], 'seeker-1');
      expect(data['employerId'], 'employer-1');
      expect(data['status'], 'pending');
      expect(data['appliedAt'], isA<Timestamp>());
    },
  );

  test('يقرأ السجلات الأقدم التي تحتوي seekerId فقط', () {
    final restored = ApplicationModel.fromJson({
      'id': 'legacy-application',
      'jobId': 'job-legacy',
      'seekerId': 'seeker-legacy',
      'employerId': 'employer-legacy',
      'status': 'pending',
      'appliedAt': '2026-08-21T09:00:00.000Z',
    });

    expect(restored.applicantId, 'seeker-legacy');
    expect(restored.seekerId, 'seeker-legacy');
  });

  test('يعطي applicantId أولوية القراءة في سجلات التقديم الجديدة', () {
    final restored = ApplicationModel.fromJson({
      'id': 'application-current',
      'jobId': 'job-current',
      'applicantId': 'applicant-current',
      'seekerId': 'seeker-legacy-value',
      'employerId': 'employer-current',
      'status': 'accepted',
      'appliedAt': '2026-08-21T09:00:00.000Z',
    });

    expect(restored.applicantId, 'applicant-current');
    expect(restored.seekerId, 'applicant-current');
    expect(restored.status, ApplicationStatus.accepted);
  });
}
