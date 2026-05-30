import 'package:flutter/material.dart';

import '../../domain/model/enums.dart';
import '../theme/app_colors.dart';

/// Helper pemetaan [ReportStatus] → warna dan ikon.
///
/// Digunakan oleh widget status_pill dan UI lainnya.
class StatusHelper {
  StatusHelper._();

  /// Warna latar belakang untuk status tertentu.
  static Color colorOf(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return AppColors.statusPending;
      case ReportStatus.verified:
        return AppColors.statusVerified;
      case ReportStatus.inProgress:
        return AppColors.statusInProgress;
      case ReportStatus.completed:
        return AppColors.statusCompleted;
      case ReportStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  /// Ikon untuk timeline status.
  static IconData iconOf(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.schedule;
      case ReportStatus.verified:
        return Icons.verified_outlined;
      case ReportStatus.inProgress:
        return Icons.build_outlined;
      case ReportStatus.completed:
        return Icons.check_circle_outline;
      case ReportStatus.rejected:
        return Icons.cancel_outlined;
    }
  }
}
