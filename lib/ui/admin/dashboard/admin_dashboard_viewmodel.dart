import 'package:flutter/foundation.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';
import '../../auth/login/login_viewmodel.dart';

/// ViewModel untuk Dashboard Admin.
class AdminDashboardViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;

  AdminDashboardViewModel({required ReportRepository reportRepository})
      : _reportRepository = reportRepository;

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  List<Report> _reports = [];
  
  // ── Statistik ──
  int get totalReports => _reports.length;
  int get pendingReports => _reports.where((r) => r.status == ReportStatus.pending).length;
  int get verifiedReports => _reports.where((r) => r.status == ReportStatus.verified).length;
  int get inProgressReports => _reports.where((r) => r.status == ReportStatus.inProgress).length;
  int get completedReports => _reports.where((r) => r.status == ReportStatus.completed).length;

  String? _error;
  String? get error => _error;

  /// Load data statistik.
  Future<void> loadDashboard() async {
    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _reports = await _reportRepository.getAllReports();
      _status = ViewStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = ViewStatus.failure;
    } finally {
      notifyListeners();
    }
  }
}
