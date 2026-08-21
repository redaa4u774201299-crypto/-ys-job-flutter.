import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_runtime.dart';
import '../../../core/monitoring/app_performance_monitor.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/search/job_search_index.dart';
import 'job_details_cache.dart';

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

/// نتيجة دفعة واحدة من بحث الوظائف. يُحتفظ بآخر مستند فقط في الذاكرة
/// لاستخدامه كمؤشر استئناف، ولا يُخزن أو يُعرض للمستخدم.
class JobsSearchPage {
  const JobsSearchPage({
    required this.jobs,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<JobModel> jobs;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

class JobsRepository {
  static const searchPageSize = 20;

  JobsRepository(
    this._firestore,
    this._auth, {
    AppPerformanceMonitor? performanceMonitor,
    JobDetailsCache? detailsCache,
  }) : _performanceMonitor =
           performanceMonitor ?? const NoopAppPerformanceMonitor(),
       _detailsCache = detailsCache ?? JobDetailsCache();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AppPerformanceMonitor _performanceMonitor;
  final JobDetailsCache _detailsCache;

  /// يستعلم Firestore باستخدام مفاتيح عامة قابلة للفهرسة، بدل تحميل الوظائف
  /// ثم البحث داخل الوصف محليًا. يعيد 20 مستندًا كحد أقصى في كل دفعة.
  /// مرر [startAfterDocument] كما أُعيد في الدفعة السابقة لاستكمال التمرير
  /// من الموضع نفسه مع ثبات الفلاتر والترتيب.
  Future<JobsSearchPage> searchJobs(
    JobFilters filters, {
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) {
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

    query = query.orderBy('createdAt', descending: true).limit(searchPageSize);
    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    Future<JobsSearchPage> fetchPage() async {
      final snapshot = await query.get();
      final jobs = snapshot.docs
          .map(JobModel.fromFirestore)
          .where((job) => _matches(job, filters))
          .toList(growable: false);
      _detailsCache.putAll(jobs);
      return JobsSearchPage(
        jobs: jobs,
        lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
        hasMore: snapshot.docs.length == searchPageSize,
      );
    }

    if (startAfterDocument != null) return fetchPage();
    return _performanceMonitor.measure(
      'jobs_initial_load',
      fetchPage,
      resultCount: (page) => page.jobs.length,
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

  /// يعيد نتيجة قائمة محمّلة في جلسة التطبيق الحالية إن وُجدت.
  ///
  /// يستعمله موفر التفاصيل قبل أي قراءة منفردة من Firestore، بينما يظل
  /// [getJob] هو البديل الآمن للرابط العميق أو عند إعادة تحميل المتصفح.
  JobModel? findCachedJob(String jobId) => _detailsCache.read(jobId);

  /// يجلب وظيفة مفردة للرابط المباشر ويحدث ذاكرة الجلسة للزيارات اللاحقة.
  Future<JobModel?> getJob(String id) async {
    final snapshot = await _firestore.collection('jobs').doc(id).get();
    if (!snapshot.exists) {
      _detailsCache.remove(id);
      return null;
    }
    final job = JobModel.fromFirestore(snapshot);
    _detailsCache.put(job);
    return job;
  }

  Stream<JobModel?> watchJob(String id) =>
      _firestore.collection('jobs').doc(id).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          _detailsCache.remove(id);
          return null;
        }
        final job = JobModel.fromFirestore(snapshot);
        _detailsCache.put(job);
        return job;
      });

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
      'createdAt': FieldValue.serverTimestamp(),
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
