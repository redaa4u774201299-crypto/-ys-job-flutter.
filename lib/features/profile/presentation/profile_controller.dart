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
    this.isUploadingPhoto = false,
    this.isUploadingResume = false,
  });

  final bool isSaving;
  final bool isUploadingPhoto;
  final bool isUploadingResume;

  bool get isBusy => isSaving || isUploadingPhoto || isUploadingResume;

  ProfileActionState copyWith({
    bool? isSaving,
    bool? isUploadingPhoto,
    bool? isUploadingResume,
  }) => ProfileActionState(
    isSaving: isSaving ?? this.isSaving,
    isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
    isUploadingResume: isUploadingResume ?? this.isUploadingResume,
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
  }) => _runSaving(
    () => _repository.updateSeekerProfile(
      name: name,
      bio: bio,
      skills: skills,
      phone: phone,
      jobTitle: jobTitle,
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

  Future<void> uploadSeekerPhoto(PlatformFile file) =>
      _runPhoto(() => _repository.uploadPhoto(file));

  Future<void> uploadCompanyLogo(PlatformFile file) =>
      _runPhoto(() => _repository.uploadCompanyLogo(file));

  Future<void> uploadResume(PlatformFile file) =>
      _runResume(() => _repository.uploadResume(file));

  Future<void> _runSaving(Future<void> Function() operation) async {
    state = state.copyWith(isSaving: true);
    try {
      await operation();
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> _runPhoto(Future<void> Function() operation) async {
    state = state.copyWith(isUploadingPhoto: true);
    try {
      await operation();
    } finally {
      state = state.copyWith(isUploadingPhoto: false);
    }
  }

  Future<void> _runResume(Future<void> Function() operation) async {
    state = state.copyWith(isUploadingResume: true);
    try {
      await operation();
    } finally {
      state = state.copyWith(isUploadingResume: false);
    }
  }
}
