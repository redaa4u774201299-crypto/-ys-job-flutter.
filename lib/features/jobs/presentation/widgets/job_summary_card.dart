import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/job_model.dart';
import '../../../../shared/widgets/base64_thumbnail_avatar.dart';

class JobSummaryCard extends StatelessWidget {
  const JobSummaryCard({super.key, required this.job, this.onTap});

  final JobModel job;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: 'عرض تفاصيل وظيفة ${job.title} لدى ${job.employerName}',
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Base64ThumbnailAvatar(
                  encoded: job.employerLogoThumbBase64,
                  fallbackLabel: job.employerName,
                  fallbackIcon: Icons.business_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      job.employerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: AppColors.navySoft),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: AppColors.navySoft,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'نُشرت في ${_formatPostedAt(job.postedAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(job.location)),
                        Chip(label: Text(job.jobType)),
                        if (job.salaryRange.isNotEmpty)
                          Chip(label: Text(job.salaryRange)),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const ExcludeSemantics(
                  child: Icon(Icons.chevron_left, color: AppColors.navySoft),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  String _formatPostedAt(DateTime postedAt) {
    final day = postedAt.day.toString().padLeft(2, '0');
    final month = postedAt.month.toString().padLeft(2, '0');
    return '$day/$month/${postedAt.year}';
  }
}
