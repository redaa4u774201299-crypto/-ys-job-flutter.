import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';

final profileControllerProvider =
    StateNotifierProvider.autoDispose<ProfileController, ProfileActionState>(
      (ref) => ProfileController(ref.watch(profileRepositoryProvider)),
    );

class ProfileActionState {
  const ProfileActionState({
    this.isSaving = false,
    this.isProcessingImage = false,
  });

  final bool isSaving;
  final bool isProcessingImage;

  bool get isBusy => isSaving || isProcessingImage;

  ProfileActionState copyWith({bool? isSaving, bool? isProcessingImage}) =>
      ProfileActionState(
        isSaving: isSaving ?? this.isSaving,
        isProcessingImage: isProcessingImage ?? this.isProcessingImage,
      );
}

class ProfileController extends StateNotifier<ProfileActionState> {
  ProfileController(this._repository) : super(const ProfileActionState());

  final ProfileRepository _repository;

  Future<void> saveSeekerProfile({
    required String name,
    required String bio,
    required List<String> skills,
    required String phone,
    required String jobTitle,
    required String cvUrl,
  }) => _runSaving(
    () => _repository.updateSeekerProfile(
      name: name,
      bio: bio,
      skills: skills,
      phone: phone,
      jobTitle: jobTitle,
      cvUrl: cvUrl,
    ),
  );

  Future<void> saveEmployerProfile({
    required String companyName,
    required String industry,
    required String bio,
    required String phone,
  }) => _runSaving(
    () => _repository.updateEmployerProfile(
      name: companyName,
      companyName: companyName,
      industry: industry,
      bio: bio,
      phone: phone,
    ),
  );

  Future<void> saveSeekerImage(PlatformFile file) =>
      _runImageProcessing(() => _repository.saveSeekerImage(file));

  Future<void> saveCompanyLogo(PlatformFile file) =>
      _runImageProcessing(() => _repository.saveCompanyLogo(file));

  Future<void> _runSaving(Future<void> Function() operation) async {
    state = state.copyWith(isSaving: true);
    try {
      await operation();
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> _runImageProcessing(Future<void> Function() operation) async {
    state = state.copyWith(isProcessingImage: true);
    try {
      await operation();
    } finally {
      state = state.copyWith(isProcessingImage: false);
    }
  }
}
