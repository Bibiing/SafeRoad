import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/notification_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../auth/login/login_viewmodel.dart';

/// ViewModel daftar semua laporan (admin).
class AllReportsViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;
  final NotificationRepository _notificationRepository;

  /// [adminUid] — UID admin yang sedang login, untuk dicatat di statusLog.
  final String? adminUid;

  AllReportsViewModel({
    required ReportRepository reportRepository,
    required NotificationRepository notificationRepository,
    this.adminUid,
  })  : _reportRepository = reportRepository,
        _notificationRepository = notificationRepository;

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  List<Report> _reports = [];
  
  // ── Filter & Search ──
  String _searchQuery = '';
  ReportStatus? _filterStatus;

  String? _error;
  String? get error => _error;

  /// Daftar laporan setelah difilter dan dicari.
  List<Report> get filteredReports {
    return _reports.where((r) {
      final matchesSearch = r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.address.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == null || r.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterStatus(ReportStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  ReportStatus? get filterStatus => _filterStatus;

  /// Ambil semua laporan dari repository.
  Future<void> fetchAllReports() async {
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

  /// Perbarui status laporan.
  ///
  /// Setelah update Firestore berhasil:
  /// 1. Tulis status log ke sub-collection `statusLogs`.
  /// 2. Kirim notifikasi ke user pemilik laporan via Firestore.
  Future<bool> updateStatus(Report report, ReportStatus newStatus, {String? reason}) async {
    try {
      final oldStatus = report.status;
      final updatedReport = report.copyWith(
        status: newStatus,
        adminReason: reason,
        updatedAt: DateTime.now(),
      );
      await _reportRepository.updateReport(updatedReport);

      // 1. Tulis status log.
      await _reportRepository.addStatusLog(
        reportId: report.id,
        updatedBy: adminUid ?? 'admin',
        newStatus: newStatus,
        note: reason ?? '',
      );

      // 2. Kirim notifikasi ke user pemilik laporan.
      await _notificationRepository.sendStatusChangeNotification(
        userId: report.userId,
        reportId: report.id,
        reportTitle: report.title,
        oldStatus: oldStatus,
        newStatus: newStatus,
      );

      // Update list lokal
      final index = _reports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _reports[index] = updatedReport;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Ekspor data ke CSV dan Share.
  Future<void> exportToCsv() async {
    final List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'ID Laporan',
      'Judul',
      'Deskripsi',
      'Kategori',
      'Alamat',
      'Status',
      'Alasan Admin',
      'Tanggal Buat',
    ]);

    for (final r in _reports) {
      rows.add([
        r.id,
        r.title,
        r.description,
        r.category.label,
        r.address,
        r.status.label,
        r.adminReason ?? '-',
        r.createdAt.toIso8601String(),
      ]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);
    final Directory directory = await getTemporaryDirectory();
    final String path = '${directory.path}/laporan_saferoad_${DateTime.now().millisecondsSinceEpoch}.csv';
    final File file = File(path);

    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(path)], text: 'Data Laporan SafeRoad');
  }
}
