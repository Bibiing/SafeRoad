import 'dart:io';

import '../model/report.dart';
import '../model/report_status_log.dart';

/// Abstraksi repository laporan.
///
/// Menyediakan CRUD laporan, upload foto, dan akses status log.
/// Concrete impl: [ReportRepositoryImpl].
abstract class ReportRepository {
  /// Buat laporan baru. Kembalikan ID dokumen yang dihasilkan.
  Future<String> createReport(Report report);

  /// Perbarui field laporan yang sudah ada.
  Future<void> updateReport(Report report);

  /// Hapus laporan beserta foto-fotonya di Storage.
  Future<void> deleteReport(Report report);

  /// Ambil laporan berdasarkan [id]. `null` bila tidak ditemukan.
  Future<Report?> getReportById(String id);

  /// Ambil semua laporan milik [userId], urut terbaru di atas.
  Future<List<Report>> getReportsByUser(String userId);

  /// Ambil semua laporan (untuk peta / beranda), urut terbaru di atas.
  Future<List<Report>> getAllReports();

  /// Ambil daftar status log untuk laporan [reportId], urut kronologis.
  Future<List<ReportStatusLog>> getStatusLogs(String reportId);

  /// Upload satu atau lebih foto, kembalikan daftar URL unduh.
  Future<List<String>> uploadImages({
    required String userId,
    required List<File> files,
  });

  /// Ambil alamat dari koordinat (reverse geocoding).
  Future<String> getAddressFromCoordinates(double lat, double lng);

  /// Ambil lokasi GPS saat ini sebagai (latitude, longitude).
  Future<({double latitude, double longitude})> getCurrentLocation();
}
