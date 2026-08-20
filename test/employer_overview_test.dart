import 'package:flutter_test/flutter_test.dart';
import 'package:ys_job/features/employer/presentation/employer_providers.dart';
import 'package:ys_job/shared/models/job_model.dart';

void main() {
  test('EmployerJobsOverview يحسب الوظائف الإجمالية والنشطة فقط', () {
    final postedAt = DateTime.utc(2026, 8, 20, 12);
    final jobs = [
      JobModel(
        id: 'active-job',
        employerId: 'employer-id',
        title: 'وظيفة نشطة',
        description: 'وصف',
        location: 'صنعاء',
        jobType: 'inside_yemen',
        salaryRange: 'غير محدد',
        isFeatured: false,
        postedAt: postedAt,
      ),
      JobModel(
        id: 'closed-job',
        employerId: 'employer-id',
        title: 'وظيفة مغلقة',
        description: 'وصف',
        location: 'عدن',
        jobType: 'inside_yemen',
        salaryRange: 'غير محدد',
        isFeatured: false,
        postedAt: postedAt,
        status: JobStatus.closed,
      ),
    ];

    final overview = EmployerJobsOverview.fromJobs(jobs);

    expect(overview.totalJobs, 2);
    expect(overview.activeJobs, 1);
  });
}
