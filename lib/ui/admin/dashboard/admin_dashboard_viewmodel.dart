import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';
import '../../../core/state/view_status.dart';
import '../../../core/utils/error_mapper.dart';

/// ViewModel untuk Dashboard Admin.
class AdminDashboardViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;

  AdminDashboardViewModel({required this._reportRepository});

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  bool get isLoading => _status == ViewStatus.loading;

  List<Report> _reports = [];

  StreamSubscription<List<Report>>? _reportsSub;
  Set<String> _knownReportIds = {};
  bool _hasReceivedInitialSnapshot = false;
  int _newReportsCount = 0;
  Report? _latestNewReport;

  int get newReportsCount => _newReportsCount;
  bool get hasNewReports => _newReportsCount > 0;
  Report? get latestNewReport => _latestNewReport;
  
  // ── Statistik ──
  int get totalReports => _reports.length;
  int get pendingReports => _reports.where((r) => r.status == ReportStatus.pending).length;
  int get verifiedReports => _reports.where((r) => r.status == ReportStatus.verified).length;
  int get inProgressReports => _reports.where((r) => r.status == ReportStatus.inProgress).length;
  int get completedReports => _reports.where((r) => r.status == ReportStatus.completed).length;

  String? _error;
  String? get error => _error;

  /// Load data statistik dan mulai pantauan realtime.
  Future<void> loadDashboard() async {
    if (_reportsSub != null) {
      return;
    }

    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    _reportsSub = _reportRepository.watchAllReports().listen(
      _handleReportsSnapshot,
      onError: (Object e) {
        _error = mapErrorToMessage(e);
        _status = ViewStatus.failure;
        notifyListeners();
      },
    );
  }

  void _handleReportsSnapshot(List<Report> reports) {
    final incomingIds = reports.map((r) => r.id).toSet();

    if (_hasReceivedInitialSnapshot) {
      final newIds = incomingIds.difference(_knownReportIds);
      if (newIds.isNotEmpty) {
        _newReportsCount += newIds.length;
        _latestNewReport = reports.firstWhere((r) => newIds.contains(r.id));
      }
    } else {
      _hasReceivedInitialSnapshot = true;
    }

    _reports = reports;
    _knownReportIds = incomingIds;
    _status = ViewStatus.success;
    _error = null;
    notifyListeners();
  }

  void clearNewReportNotification() {
    if (_newReportsCount == 0 && _latestNewReport == null) return;
    _newReportsCount = 0;
    _latestNewReport = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _reportsSub?.cancel();
    super.dispose();
  }
}
