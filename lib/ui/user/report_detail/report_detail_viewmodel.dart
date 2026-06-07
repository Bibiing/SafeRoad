import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/view_status.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../domain/model/report.dart';
import '../../../domain/model/report_status_log.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../additional/realtime_sync/realtime_sync_service.dart';

/// ViewModel untuk layar detail laporan.
class ReportDetailViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;
  final AuthRepository _authRepository;

  ReportDetailViewModel({
    required ReportRepository reportRepository,
    required AuthRepository authRepository,
  })  : _reportRepository = reportRepository,
        _authRepository = authRepository;

  late final RealtimeSyncService _realtimeSync =
      RealtimeSyncService(_reportRepository);
  StreamSubscription<Report?>? _reportSub;

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  String? _error;
  String? get error => _error;

  Report? _report;
  Report? get report => _report;

  List<ReportStatusLog> _statusLogs = const [];
  List<ReportStatusLog> get statusLogs => List.unmodifiable(_statusLogs);

  bool get isLoading => _status == ViewStatus.loading;

  /// Apakah user saat ini adalah pemilik laporan.
  bool get isOwner =>
      _report != null && _report!.userId == _authRepository.currentUserId;

  /// Apakah laporan bisa di-edit/hapus.
  bool get canEdit => isOwner && (_report?.isEditable ?? false);

  /// Muat detail laporan dan status log.
  Future<void> loadReport(String reportId) async {
    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _report = await _reportRepository.getReportById(reportId);
      if (_report != null) {
        _statusLogs = await _reportRepository.getStatusLogs(reportId);
      }
      _status = ViewStatus.success;
      _startWatching(reportId);
    } catch (e) {
      _error = mapErrorToMessage(e);
      _status = ViewStatus.failure;
    }
    notifyListeners();
  }

  /// Mulai memantau laporan secara realtime via [RealtimeSyncService].
  ///
  /// Saat admin mengubah status, perubahan langsung tampil tanpa refresh.
  /// Bila status berubah, timeline status log ikut disegarkan.
  void _startWatching(String reportId) {
    _reportSub?.cancel();
    _reportSub = _realtimeSync.watchReport(reportId).listen((report) async {
      if (report == null) return;
      final statusChanged = _report?.status != report.status;
      _report = report;
      if (statusChanged) {
        try {
          _statusLogs = await _reportRepository.getStatusLogs(reportId);
        } catch (_) {
          // Abaikan kegagalan refresh log; status utama tetap diperbarui.
        }
      }
      notifyListeners();
    });
  }

  /// Hapus laporan.
  Future<bool> deleteReport() async {
    if (_report == null) return false;

    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      await _reportRepository.deleteReport(_report!);
      _status = ViewStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error = mapErrorToMessage(e);
      _status = ViewStatus.failure;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _reportSub?.cancel();
    super.dispose();
  }
}
