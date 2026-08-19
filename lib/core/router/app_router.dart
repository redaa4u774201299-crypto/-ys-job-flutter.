import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/companies/presentation/pages/companies_page.dart';
import '../../features/home/presentation/pages/landing_page.dart';
import '../../features/jobs/presentation/pages/jobs_page.dart';
import '../../shared/layout/main_layout.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const LandingPage()),
          GoRoute(
            path: '/jobs',
            builder: (context, state) =>
                JobsPage(query: state.uri.queryParameters['q']),
          ),
          GoRoute(
            path: '/companies',
            builder: (context, state) => const CompaniesPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginPage(),
          ),
        ],
      ),
    ],
  ),
);
