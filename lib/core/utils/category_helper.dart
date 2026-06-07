import 'package:flutter/material.dart';

import '../../domain/model/enums.dart';

/// Helper pemetaan [ReportCategory] → ikon. Dipakai chip kategori (Beranda)
/// dan grid kategori (Buat Laporan).
class CategoryHelper {
  CategoryHelper._();

  static IconData iconOf(ReportCategory category) {
    switch (category) {
      case ReportCategory.pothole:
        return Icons.warning_amber_rounded;
      case ReportCategory.streetLight:
        return Icons.lightbulb_outline;
      case ReportCategory.trafficSign:
        return Icons.signpost_outlined;
      case ReportCategory.roadMarking:
        return Icons.add_road;
      case ReportCategory.other:
        return Icons.more_horiz;
    }
  }
}
