import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/monitoring/app_performance_monitor.dart';
import '../data/profile_repository.dart';

final profileControllerProvider =
    StateNotifierProvider.autoDispose<ProfileController, ProfileActionState>(
      (ref) => ProfileController(
        ref.watch(profileRepositoryProvider),
        performanceMonitor: ref.watch(appPerformanceMonitorProvider),
      ),
    );

enum ProfileSyncState { idle, saving, synced, pending, retrying, failed }

class ProfileActionState {
  const ProfileActionState({
    this.isSaving = false,
    this.isProcessingImage = false,
    this.syncState = ProfileSyncState.idle,
    this.syncMessage = '',
  });

  final bool isSaving;
  final bool isProcessingImage;
  final ProfileSyncState syncState;
  final String syncMessage;

  bool get isRetryingSync => syncState == ProfileSyncState.retrying;
  bool get hasPendingSync => syncState == ProfileSyncState.pending;
  bool get hasSyncFailure => syncState == ProfileSyncState.failed;
  bool get needsSyncAttention => hasPendingSync || hasSyncFailure;
  bool get isBusy => isSaving || isProcessingImage || isRetryingSync;

  ProfileActionState copyWith({
    bool? isSaving,
    bool? isProcessingImage,
    ProfileSyncState? syncState,
    String? syncMessage,
  }) => ProfileActionState(
    isSaving: isSaving ?? this.isSaving,
    isProcessingImage: isProcessingImage ?? this.isProcessingImage,
    syncState: syncState ?? this.syncState,
    syncMessage: syncMessage ?? this.syncMessage,
  );
}

class ProfileController extends StateNotifier<ProfileActionState> {
  ProfileController(
    this._repository, {
    AppPerformanceMonitor? performanceMonitor,
  }) : _performanceMonitor =
           performanceMonitor ?? const NoopAppPerformanceMonitor(),
       super(const ProfileActionState());

  final ProfileRepository _repository;
  final AppPerformanceMonitor _performanceMonitor;
  Future<ProfileSyncOutcome> Function()? _retryOperation;

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

  Future<void> saveSeekerImageBytes(Uint8List bytes) =>
      _runImageProcessing(() => _repository.saveSeekerImageBytes(bytes));

  Future<void> saveCompanyLogo(PlatformFile file) =>
      _runImageProcessing(() => _repository.saveCompanyLogo(file));

  Future<void> saveCompanyLogoBytes(Uint8List bytes) =>
      _runImageProcessing(() => _repository.saveCompanyLogoBytes(bytes));

  Future<void> retryPendingSync() async {
    final retryOperation = _retryOperation;
    state = state.copyWith(
      syncState: ProfileSyncState.retrying,
      syncMessage: '',
    );
    try {
      final outcome = retryOperation == null
          ? await _repository.retryPendingSync()
          : await retryOperation();
      _applySyncOutcome(outcome);
    } catch (error) {
      _recordSyncFailure(error);
      rethrow;
    }
  }

  Future<void> _runSaving(Future<ProfileSyncOutcome> Function() operation) =>
      _runProfileWrite(operation);

  Future<void> _runImageProcessing(
    Future<ProfileSyncOutcome> Function() operation,
  ) => _runProfileWrite(operation, isImage: true);

  Future<void> _runProfileWrite(
    Future<ProfileSyncOutcome> Function() operation, {
    bool isImage = false,
  }) async {
    _retryOperation = operation;
    state = state.copyWith(
      isSaving: !isImage,
      isProcessingImage: isImage,
      syncState: ProfileSyncState.saving,
      syncMessage: '',
    );
    try {
      final outcome = await _performanceMonitor.measure(
        'profile_save',
        operation,
      );
      _applySyncOutcome(outcome);
    } catch (error) {
      _recordSyncFailure(error);
      rethrow;
    } finally {
      state = state.copyWith(isSaving: false, isProcessingImage: false);
    }
  }

  void _applySyncOutcome(ProfileSyncOutcome outcome) {
    if (outcome == ProfileSyncOutcome.synced) {
      _retryOperation = null;
      state = state.copyWith(
        syncState: ProfileSyncState.synced,
        syncMessage: '',
      );
      return;
    }
    state = state.copyWith(
      syncState: ProfileSyncState.pending,
      syncMessage:
          'حُفظت التغييرات محليًا وستتزامن تلقائيًا عند عودة الإنترنت.',
    );
  }

  void _recordSyncFailure(Object error) {
    state = state.copyWith(
      syncState: ProfileSyncState.failed,
      syncMessage:
          'تعذر حفظ التغييرات الآن. تحقق من الاتصال ثم أعد المحاولة. (${error.toString().replaceFirst('Bad state: ', '')})',
    );
  }
}
