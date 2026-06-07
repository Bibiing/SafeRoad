import 'package:flutter/foundation.dart';

import '../../../core/state/view_status.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';

/// ViewModel pencarian laporan berdasarkan kategori dan kata kunci.
///
/// Mengambil data lewat [ReportRepository] (SSOT) lalu memfilter di memori.
/// Tidak mengakses Firestore langsung (kepatuhan MVVM).
class SearchViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;

  SearchViewModel({required ReportRepository reportRepository})
      : _reportRepository = reportRepository;

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  bool get isLoading => _status == ViewStatus.loading;

  String? _error;
  String? get error => _error;

  List<Report> _allReports = [];

  String _query = '';
  String get query => _query;

  ReportCategory? _category;
  ReportCategory? get category => _category;

  /// Muat seluruh laporan sebagai sumber pencarian.
  Future<void> load() async {
    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _allReports = await _reportRepository.getAllReports();
      _status = ViewStatus.success;
    } catch (e) {
      _error = mapErrorToMessage(e);
      _status = ViewStatus.failure;
    }
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategory(ReportCategory? value) {
    _category = value;
    notifyListeners();
  }

  /// Hasil pencarian terfilter (kategori + kata kunci).
  List<Report> get results {
    final q = _query.trim().toLowerCase();
    return _allReports.where((r) {
      final matchCategory = _category == null || r.category == _category;
      final matchQuery = q.isEmpty ||
          r.title.toLowerCase().contains(q) ||
          r.address.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
      return matchCategory && matchQuery;
    }).toList();
  }
}
