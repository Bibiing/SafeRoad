import 'package:flutter/foundation.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';
import '../../../core/state/view_status.dart';
import '../../../core/utils/error_mapper.dart';

/// ViewModel untuk tab Peta.
class MapViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;

  MapViewModel(this._reportRepository);

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  String? _error;
  String? get error => _error;

  List<Report> _reports = const [];
  List<Report> get reports => List.unmodifiable(_reports);

  ReportCategory? _categoryFilter;
  ReportCategory? get categoryFilter => _categoryFilter;

  /// Laporan setelah filter kategori (null = semua/terdekat).
  List<Report> get filteredReports => _categoryFilter == null
      ? _reports
      : _reports.where((r) => r.category == _categoryFilter).toList();

  void setCategoryFilter(ReportCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  bool get isLoading => _status == ViewStatus.loading;

  double? _currentLat;
  double? get currentLat => _currentLat;

  double? _currentLng;
  double? get currentLng => _currentLng;

  /// Muat semua laporan untuk ditampilkan di peta.
  Future<void> loadReports() async {
    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _reports = await _reportRepository.getAllReports();

      // Ambil lokasi saat ini untuk center peta.
      try {
        final loc = await _reportRepository.getCurrentLocation();
        _currentLat = loc.latitude;
        _currentLng = loc.longitude;
      } catch (_) {
        // Gagal ambil lokasi bukan error fatal — peta tetap bisa ditampilkan.
      }

      _status = ViewStatus.success;
    } catch (e) {
      _error = mapErrorToMessage(e);
      _status = ViewStatus.failure;
    }
    notifyListeners();
  }

}
