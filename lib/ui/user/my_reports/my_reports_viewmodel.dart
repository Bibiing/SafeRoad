import 'package:flutter/foundation.dart';

import '../../../domain/model/report.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../auth/login/login_viewmodel.dart';

/// ViewModel untuk tab Laporan Saya.
class MyReportsViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;
  final AuthRepository _authRepository;

  MyReportsViewModel({
    required ReportRepository reportRepository,
    required AuthRepository authRepository,
  })  : _reportRepository = reportRepository,
        _authRepository = authRepository;

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  String? _error;
  String? get error => _error;

  List<Report> _reports = const [];
  List<Report> get reports => List.unmodifiable(_reports);

  bool get isLoading => _status == ViewStatus.loading;

  /// Muat laporan milik user saat ini.
  Future<void> loadMyReports() async {
    final uid = _authRepository.currentUserId;
    if (uid == null) return;

    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _reports = await _reportRepository.getReportsByUser(uid);
      _status = ViewStatus.success;
    } catch (e) {
      _error = _extractMessage(e);
      _status = ViewStatus.failure;
    }
    notifyListeners();
  }

  String _extractMessage(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
  }
}
