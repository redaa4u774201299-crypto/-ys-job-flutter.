import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/job.dart';

class JobSummaryCard extends StatelessWidget {
  const JobSummaryCard({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      if (job.city.isNotEmpty) job.city,
      if (job.workType.isNotEmpty) job.workType,
      if (job.salary.isNotEmpty) job.salary,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              job.companyName,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppColors.navySoft),
            ),
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metadata
                    .map((item) => Chip(label: Text(item)))
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
