import '../../../shared/models/application_model.dart';

class SeekerDashboardStats {
  const SeekerDashboardStats({
    required this.total,
    required this.inProgress,
    required this.accepted,
  });

  final int total;
  final int inProgress;
  final int accepted;

  factory SeekerDashboardStats.fromApplications(
    Iterable<ApplicationModel> applications,
  ) {
    final items = applications.toList(growable: false);
    return SeekerDashboardStats(
      total: items.length,
      inProgress: items
          .where(
            (application) =>
                application.status == ApplicationStatus.pending ||
                application.status == ApplicationStatus.viewed ||
                application.status == ApplicationStatus.interview,
          )
          .length,
      accepted: items
          .where(
            (application) => application.status == ApplicationStatus.accepted,
          )
          .length,
    );
  }
}
