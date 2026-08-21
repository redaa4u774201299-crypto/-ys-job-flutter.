import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_service.dart';
import '../data/applications_repository.dart';

final seekerApplicationsProvider =
    StreamProvider.autoDispose<List<SeekerApplicationRecord>>((ref) {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null || userId.isEmpty) {
        return Stream.value(<SeekerApplicationRecord>[]);
      }
      return ref
          .watch(applicationsRepositoryProvider)
          .watchCurrentSeekerApplications();
    });
