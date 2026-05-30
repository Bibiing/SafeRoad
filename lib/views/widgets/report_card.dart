import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/report_model.dart';
import 'status_badge.dart';

/// Kartu ringkasan laporan untuk daftar. Flat: border tipis, tanpa shadow.
class ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onTap;

  const ReportCard({super.key, required this.report, this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = report.createdAt;
    final dateText = date != null
        ? DateFormat('d MMM yyyy, HH:mm', 'id').format(date)
        : '-';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumb(photoUrl: report.photoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            style: AppTextStyles.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(report.category.label, style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(dateText, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? photoUrl;

  const _Thumb({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 56,
        width: 56,
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ThumbPlaceholder(),
              )
            : const _ThumbPlaceholder(),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceAlt,
      child: const Icon(Icons.photo_outlined, color: AppColors.textHint),
    );
  }
}
