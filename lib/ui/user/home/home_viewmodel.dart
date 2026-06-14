import 'package:flutter/foundation.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/model/user.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../../core/state/view_status.dart';
import '../../../core/utils/error_mapper.dart';

/// ViewModel untuk tab Beranda (semua laporan + search).
class HomeViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;
  final AuthRepository _authRepository;

  HomeViewModel({
    required this._reportRepository,
    required this._authRepository,
  });

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

  ReportCategory? _categoryFilter;
  ReportCategory? get categoryFilter => _categoryFilter;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get isLoading => _status == ViewStatus.loading;

  // ── Ringkasan "Kondisi Jalan di Area Anda" (dihitung dari semua laporan) ──
  int get totalReports => _reports.length;
  int get resolvedReports =>
      _reports.where((r) => r.status == ReportStatus.completed).length;

  /// Rasio laporan yang sudah selesai (0.0–1.0).
  double get resolvedRatio =>
      _reports.isEmpty ? 0 : resolvedReports / _reports.length;

  List<Report> get _filteredReports {
    Iterable<Report> list = _reports;
    if (_categoryFilter != null) {
      list = list.where((r) => r.category == _categoryFilter);
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) =>
          r.title.toLowerCase().contains(q) ||
          r.address.toLowerCase().contains(q) ||
          r.category.label.toLowerCase().contains(q));
    }
    return list.toList(growable: false);
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
      _error = mapErrorToMessage(e);
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
      _error = mapErrorToMessage(e);
      _status = ViewStatus.failure;
    }
    notifyListeners();
  }

  /// Set query pencarian.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set filter kategori (null = semua).
  void setCategoryFilter(ReportCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }
}
