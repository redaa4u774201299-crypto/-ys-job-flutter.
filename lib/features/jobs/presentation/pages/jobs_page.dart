import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_runtime.dart';
import '../../data/jobs_repository.dart';
import '../widgets/firebase_setup_state.dart';
import '../widgets/job_summary_card.dart';

class JobsPage extends ConsumerWidget {
  const JobsPage({super.key, this.query});

  final String? query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasQuery = query?.isNotEmpty == true;
    final runtime = ref.watch(firebaseRuntimeProvider);
    final jobs = ref.watch(publicJobsProvider(query ?? ''));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasQuery ? 'نتائج البحث عن «$query»' : 'الوظائف',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              if (!runtime.isReady)
                FirebaseSetupState(message: runtime.message)
              else
                jobs.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => const _JobsErrorState(),
                  data: (items) => items.isEmpty
                      ? const _EmptyJobsState()
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) =>
                              JobSummaryCard(job: items[index]),
                        ),
                ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyJobsState extends StatelessWidget {
  const _EmptyJobsState();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        'لا توجد وظائف منشورة مطابقة حاليًا. لا يعرض YS.JOB وظائف تجريبية.',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _JobsErrorState extends StatelessWidget {
  const _JobsErrorState();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Text(
        'تعذر تحميل الوظائف الآن. تحقق من اتصال Firestore وصلاحيات القراءة ثم حاول مجددًا.',
      ),
    ),
  );
}
