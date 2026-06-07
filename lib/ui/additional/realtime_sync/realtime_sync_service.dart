import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';

/// Service sinkronisasi realtime laporan.
///
/// Membungkus stream realtime [ReportRepository.watchReport] menjadi satu titik
/// akses bagi lapisan UI untuk memantau perubahan laporan secara langsung
/// (mis. saat admin mengubah status). Dipakai oleh [ReportDetailViewModel].
///
/// Pembungkus tipis yang sengaja dibuat agar peran "Realtime Sync" pada modul
/// Additional terwujud nyata dan bisa diperluas (mis. menggabungkan beberapa
/// stream) tanpa mengubah ViewModel.
class RealtimeSyncService {
  final ReportRepository _reportRepository;

  RealtimeSyncService(this._reportRepository);

  /// Pantau satu laporan secara realtime.
  Stream<Report?> watchReport(String reportId) =>
      _reportRepository.watchReport(reportId);
}
