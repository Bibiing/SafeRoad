import 'package:flutter/foundation.dart';

import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';
import '../../auth/login/login_viewmodel.dart';

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
