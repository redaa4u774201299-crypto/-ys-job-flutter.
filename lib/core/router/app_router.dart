import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_feature_requests_page.dart';
import '../../features/admin/presentation/pages/admin_jobs_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/admin_layout.dart';
import '../../features/companies/presentation/pages/companies_page.dart';
import '../../features/employer/presentation/pages/employer_dashboard_page.dart';
import '../../features/employer/presentation/pages/employer_job_applications_page.dart';
import '../../features/employer/presentation/pages/post_job_page.dart';
import '../../features/employer/presentation/employer_layout.dart';
import '../../features/home/presentation/pages/landing_page.dart';
import '../../features/jobs/presentation/pages/jobs_page.dart';
import '../../features/seeker/presentation/pages/job_details_page.dart';
import '../../features/seeker/presentation/pages/seeker_dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../shared/layout/main_layout.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => EmployerLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.employerDashboard,
            builder: (context, state) => const EmployerDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.addJob,
            builder: (context, state) => const PostJobPage(),
          ),
          GoRoute(
            path: AppRoutes.legacyEmployerPostJob,
            redirect: (context, state) =>
                AppRoutes.redirectLegacyEmployerPostJob(state.uri.path),
          ),
          GoRoute(
            path: AppRoutes.employerApplicationsPattern,
            builder: (context, state) => EmployerJobApplicationsPage(
              jobId: state.pathParameters['jobId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.legacyEmployerApplicationsPattern,
            redirect: (context, state) =>
                AppRoutes.redirectLegacyEmployerApplications(
                  state.pathParameters['jobId']!,
                ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.adminDashboard,
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.adminUsers,
            builder: (context, state) => const AdminUsersPage(),
          ),
          GoRoute(
            path: AppRoutes.adminJobs,
            builder: (context, state) => const AdminJobsPage(),
          ),
          GoRoute(
            path: AppRoutes.adminFeatureRequests,
            builder: (context, state) => const AdminFeatureRequestsPage(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const LandingPage()),
          GoRoute(
            path: AppRoutes.jobs,
            builder: (context, state) =>
                JobsPage(query: state.uri.queryParameters['q']),
          ),
          GoRoute(
            path: '/companies',
            builder: (context, state) => const CompaniesPage(),
          ),
          GoRoute(
            path: AppRoutes.jobDetailsPattern,
            builder: (context, state) =>
                JobDetailsPage(jobId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.legacyJobDetailsPattern,
            redirect: (context, state) =>
                AppRoutes.redirectLegacyJobDetails(state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.seekerDashboard,
            builder: (context, state) => const SeekerDashboardPage(),
          ),
        ],
      ),
    ],
  ),
);
