import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../../../core/monitoring/app_performance_monitor.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/search/job_search_index.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  final runtime = ref.watch(firebaseRuntimeProvider);
  if (!runtime.isReady) {
    throw StateError('Firebase غير مهيأ لهذا المشروع.');
  }
  return JobsRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    performanceMonitor: ref.watch(appPerformanceMonitorProvider),
  );
});

class JobFilters {
  const JobFilters({this.query = '', this.jobType = '', this.location = ''});

  final String query;
  final String jobType;
  final String location;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobFilters &&
          other.query == query &&
          other.jobType == jobType &&
          other.location == location;

  @override
  int get hashCode => Object.hash(query, jobType, location);
}

class JobsRepository {
  JobsRepository(
    this._firestore,
    this._auth, {
    AppPerformanceMonitor? performanceMonitor,
  }) : _performanceMonitor =
           performanceMonitor ?? const NoopAppPerformanceMonitor();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AppPerformanceMonitor _performanceMonitor;

  Stream<List<JobModel>> watchAvailableJobs(JobFilters filters) =>
      searchJobs(filters);

  /// يستعلم Firestore باستخدام مفاتيح عامة قابلة للفهرسة، بدل تحميل الوظائف
  /// ثم البحث داخل الوصف محليًا. تُبقي واجهة المستخدم البحث الفارغ خارج هذا
  /// المسار، بينما يظل الاستعراض العام متاحًا عندما تكون الفلاتر فارغة.
  Stream<List<JobModel>> searchJobs(JobFilters filters) {
    final normalizedQuery = JobSearchIndex.normalize(filters.query);
    final normalizedLocation = JobSearchIndex.normalize(filters.location);
    Query<Map<String, dynamic>> query = _firestore
        .collection('jobs')
        .where('status', isEqualTo: JobStatus.active.value);

    if (normalizedLocation.isNotEmpty) {
      query = query.where('locationKey', isEqualTo: normalizedLocation);
    }
    if (normalizedQuery.isNotEmpty) {
      query = query.where('searchTerms', arrayContains: normalizedQuery);
    }

    final stream = query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(JobModel.fromFirestore)
              .where((job) => _matches(job, filters))
              .toList(growable: false)
            ..sort((a, b) => b.postedAt.compareTo(a.postedAt)),
    );
    return _performanceMonitor.measureFirstStream(
      'jobs_initial_load',
      stream,
      resultCount: (jobs) => jobs.length,
    );
  }

  Stream<List<JobModel>> watchEmployerJobs(String employerId) => _firestore
      .collection('jobs')
      .where('employerId', isEqualTo: employerId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(JobModel.fromFirestore).toList(growable: false)
              ..sort((a, b) => b.postedAt.compareTo(a.postedAt)),
      );

  Stream<JobModel?> watchJob(String id) => _firestore
      .collection('jobs')
      .doc(id)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists ? JobModel.fromFirestore(snapshot) : null,
      );

  Future<void> postJob({
    required String title,
    required String description,
    required String requirements,
    required String jobType,
    required String salaryRange,
    required String location,
  }) async {
    final user = _requireUser();
    final profile = await _firestore.collection('users').doc(user.uid).get();
    final employerName = (profile.data()?['name']?.toString().trim() ?? '');
    final employerLogoThumbBase64 =
        profile.data()?['logoThumbBase64']?.toString().trim() ?? '';
    if (employerName.isEmpty) {
      throw StateError('تعذر استعادة ملف الشركة أو صاحب الحساب.');
    }
    final document = _firestore.collection('jobs').doc();
    final job = JobModel(
      id: document.id,
      employerId: user.uid,
      employerName: employerName,
      employerLogoThumbBase64: employerLogoThumbBase64,
      title: title.trim(),
      description: description.trim(),
      requirements: requirements.trim(),
      jobType: jobType.trim(),
      salaryRange: salaryRange.trim(),
      location: location.trim(),
      isFeatured: false,
      postedAt: DateTime.now().toUtc(),
    );
    await document.set({
      ...job.toFirestore(),
      'postedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateJobStatus({
    required String jobId,
    required JobStatus status,
  }) async {
    final user = _requireUser();
    final reference = _firestore.collection('jobs').doc(jobId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists || snapshot.data()?['employerId'] != user.uid) {
        throw StateError('لا تملك صلاحية تعديل هذه الوظيفة.');
      }
      transaction.update(reference, {'status': status.value});
    });
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('سجل الدخول أولًا لإكمال هذه العملية.');
    return user;
  }

  bool _matches(JobModel job, JobFilters filters) {
    final type = filters.jobType.trim().toLowerCase();
    return type.isEmpty || job.jobType.toLowerCase() == type;
  }
}
