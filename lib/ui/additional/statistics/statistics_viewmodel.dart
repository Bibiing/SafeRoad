import 'package:flutter/foundation.dart';

import '../../../core/state/view_status.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';

/// ViewModel statistik laporan — ringkasan jumlah per status & kategori.
///
/// Menghitung agregat dari data [ReportRepository] (SSOT). Tidak mengakses
/// Firestore langsung (kepatuhan MVVM).
class StatisticsViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;

  StatisticsViewModel({required this._reportRepository});

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  bool get isLoading => _status == ViewStatus.loading;

  String? _error;
  String? get error => _error;

  List<Report> _reports = [];

  int get total => _reports.length;

  /// Jumlah laporan per status (semua status selalu ada, default 0).
  Map<ReportStatus, int> get countByStatus {
    final counts = {for (final s in ReportStatus.values) s: 0};
    for (final report in _reports) {
      counts[report.status] = (counts[report.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Jumlah laporan per kategori (semua kategori selalu ada, default 0).
  Map<ReportCategory, int> get countByCategory {
    final counts = {for (final c in ReportCategory.values) c: 0};
    for (final report in _reports) {
      counts[report.category] = (counts[report.category] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> load() async {
    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _reports = await _reportRepository.getAllReports();
      _status = ViewStatus.success;
    } catch (e) {
      _error = mapErrorToMessage(e);
      _status = ViewStatus.failure;
    }
    notifyListeners();
  }
}
