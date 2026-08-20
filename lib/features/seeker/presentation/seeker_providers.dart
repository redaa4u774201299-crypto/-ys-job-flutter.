import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/applications_repository.dart';

final seekerApplicationsProvider =
    StreamProvider.autoDispose<List<SeekerApplicationRecord>>((ref) {
      return ref
          .watch(applicationsRepositoryProvider)
          .watchCurrentSeekerApplications();
    });
