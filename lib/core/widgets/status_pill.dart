import 'package:flutter/material.dart';

import '../../domain/model/enums.dart';
import '../theme/app_text_styles.dart';
import '../utils/status_helper.dart';

/// Pill status berwarna dengan dot kecil — widget reusable.
///
/// Menampilkan label status dalam Bahasa Indonesia dengan latar belakang
/// berwarna sesuai status laporan.
class StatusPill extends StatelessWidget {
  /// Status laporan yang ditampilkan.
  final ReportStatus status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = StatusHelper.colorOf(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: AppTextStyles.badge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
