import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/enums.dart';

/// Badge status laporan. Pemetaan warna status ditaruh di layer View.
class StatusBadge extends StatelessWidget {
  final ReportStatus status;

  const StatusBadge({super.key, required this.status});

  static Color colorOf(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return AppColors.statusPending;
      case ReportStatus.diverifikasi:
        return AppColors.statusVerified;
      case ReportStatus.diproses:
        return AppColors.statusInProgress;
      case ReportStatus.selesai:
        return AppColors.statusDone;
      case ReportStatus.ditolak:
        return AppColors.statusRejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorOf(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.label, style: AppTextStyles.badge),
    );
  }
}
