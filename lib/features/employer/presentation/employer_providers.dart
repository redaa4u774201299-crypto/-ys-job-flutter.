import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../jobs/data/jobs_repository.dart';
import '../../seeker/data/applications_repository.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/job_model.dart';

final employerJobsProvider = StreamProvider.autoDispose
    .family<List<JobModel>, String>((ref, employerId) {
      return ref.watch(jobsRepositoryProvider).watchEmployerJobs(employerId);
    });

final employerApplicantCountProvider = StreamProvider.autoDispose
    .family<int, String>((ref, employerId) {
      return ref
          .watch(applicationsRepositoryProvider)
          .watchEmployerApplicantCount(employerId);
    });

final employerApplicationsProvider = StreamProvider.autoDispose
    .family<List<ApplicationModel>, String>((ref, employerId) {
      return ref
          .watch(applicationsRepositoryProvider)
          .watchEmployerApplications(employerId);
    });

class EmployerJobsOverview {
  const EmployerJobsOverview({
    required this.totalJobs,
    required this.activeJobs,
  });

  final int totalJobs;
  final int activeJobs;

  factory EmployerJobsOverview.fromJobs(List<JobModel> jobs) {
    return EmployerJobsOverview(
      totalJobs: jobs.length,
      activeJobs: jobs.where((job) => job.isActive).length,
    );
  }
}
