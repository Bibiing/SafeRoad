import 'dart:io';

import '../../domain/model/report.dart';
import '../../domain/model/report_status_log.dart';
import '../../domain/repository/report_repository.dart';
import '../remote/dto/report_dto.dart';
import '../remote/location_datasource.dart';
import '../remote/report_remote_datasource.dart';
import '../remote/storage_remote_datasource.dart';

/// Implementasi konkret [ReportRepository].
///
/// Mengorkestrasi akses ke Firestore (laporan), Storage (foto), dan
/// lokasi (GPS + geocoding). Menerjemahkan DTO ↔ domain model.
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _reportDataSource;
  final StorageRemoteDataSource _storageDataSource;
  final LocationDataSource _locationDataSource;

  ReportRepositoryImpl({
    required ReportRemoteDataSource reportDataSource,
    required StorageRemoteDataSource storageDataSource,
    required LocationDataSource locationDataSource,
  })  : _reportDataSource = reportDataSource,
        _storageDataSource = storageDataSource,
        _locationDataSource = locationDataSource;

  @override
  Future<String> createReport(Report report) {
    final dto = ReportDto.fromDomain(report);
    return _reportDataSource.createReport(dto);
  }

  @override
  Future<void> updateReport(Report report) {
    final dto = ReportDto.fromDomain(report);
    return _reportDataSource.updateReport(dto);
  }

  @override
  Future<void> deleteReport(Report report) async {
    // Hapus foto dari Storage terlebih dahulu.
    for (final url in report.imageUrls) {
      if (url.isNotEmpty) {
        await _storageDataSource.deleteByUrl(url);
      }
    }
    await _reportDataSource.deleteReport(report.id);
  }

  @override
  Future<Report?> getReportById(String id) async {
    final dto = await _reportDataSource.getReportById(id);
    return dto?.toDomain();
  }

  @override
  Future<List<Report>> getReportsByUser(String userId) async {
    final dtos = await _reportDataSource.getReportsByUser(userId);
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  @override
  Future<List<Report>> getAllReports() async {
    final dtos = await _reportDataSource.getAllReports();
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  @override
  Future<List<ReportStatusLog>> getStatusLogs(String reportId) async {
    final dtos = await _reportDataSource.getStatusLogs(reportId);
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  @override
  Future<List<String>> uploadImages({
    required String userId,
    required List<File> files,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'reports/$userId/$name';
      final url = await _storageDataSource.uploadFile(path: path, file: file);
      urls.add(url);
    }
    return urls;
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) {
    return _locationDataSource.getAddress(lat, lng);
  }

  @override
  Future<({double latitude, double longitude})> getCurrentLocation() async {
    final result = await _locationDataSource.getCurrentLocation();
    return (latitude: result.latitude, longitude: result.longitude);
  }
}
