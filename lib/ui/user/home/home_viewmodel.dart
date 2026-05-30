import 'package:flutter/foundation.dart';

import '../../../domain/model/report.dart';
import '../../../domain/model/user.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../auth/login/login_viewmodel.dart';

/// ViewModel untuk tab Beranda (semua laporan + search).
class HomeViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;
  final AuthRepository _authRepository;

  HomeViewModel({
    required ReportRepository reportRepository,
    required AuthRepository authRepository,
  })  : _reportRepository = reportRepository,
        _authRepository = authRepository;

  // ── State ──────────────────────────────────────────────────────────
  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  String? _error;
  String? get error => _error;

  List<Report> _reports = const [];
  /// Semua laporan (read-only).
  List<Report> get reports => List.unmodifiable(_filteredReports);

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get isLoading => _status == ViewStatus.loading;

  List<Report> get _filteredReports {
    if (_searchQuery.isEmpty) return _reports;
    final q = _searchQuery.toLowerCase();
    return _reports
        .where((r) =>
            r.title.toLowerCase().contains(q) ||
            r.address.toLowerCase().contains(q) ||
            r.category.label.toLowerCase().contains(q))
        .toList(growable: false);
  }

  // ── Commands ───────────────────────────────────────────────────────

  /// Muat profil user saat ini dan daftar semua laporan.
  Future<void> loadInitialData() async {
    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final uid = _authRepository.currentUserId;
      if (uid != null) {
        _currentUser = await _authRepository.fetchUser(uid);
      }
      _reports = await _reportRepository.getAllReports();
      _status = ViewStatus.success;
    } catch (e) {
      _error = _extractMessage(e);
      _status = ViewStatus.failure;
    }
    notifyListeners();
  }

  /// Refresh daftar laporan.
  Future<void> refresh() async {
    try {
      _reports = await _reportRepository.getAllReports();
      _error = null;
      _status = ViewStatus.success;
    } catch (e) {
      _error = _extractMessage(e);
      _status = ViewStatus.failure;
    }
    notifyListeners();
  }

  /// Set query pencarian.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  String _extractMessage(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
  }
}
