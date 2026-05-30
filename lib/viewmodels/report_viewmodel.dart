import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/report_model.dart';
import '../services/location_service.dart';
import '../services/report_repository.dart';
import '../services/storage_service.dart';

/// State + logika laporan user. Semua Service di-inject lewat konstruktor.
class ReportViewModel extends ChangeNotifier {
  final ReportRepository _repository;
  final StorageService _storageService;
  final LocationService _locationService;

  ReportViewModel(
    this._repository,
    this._storageService,
    this._locationService,
  );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  List<ReportModel> _myReports = const [];
  List<ReportModel> get myReports => _myReports;

  /// Muat daftar laporan milik [uid].
  Future<void> loadMyReports(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _myReports = await _repository.getReportsByUser(uid);
    } catch (e) {
      _error = _message(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil lokasi GPS saat ini.
  Future<LocationResult?> fetchCurrentLocation() async {
    try {
      _error = null;
      return await _locationService.getCurrentLocation();
    } catch (e) {
      _error = _message(e);
      notifyListeners();
      return null;
    }
  }

  /// Buat laporan baru. Upload foto dulu bila ada. Refresh daftar bila sukses.
  Future<bool> submitReport({
    required String uid,
    required String title,
    required String description,
    required ReportCategory category,
    required double latitude,
    required double longitude,
    String address = '',
    File? image,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      String? photoUrl;
      if (image != null) {
        photoUrl = await _storageService.uploadReportImage(
          userId: uid,
          file: image,
        );
      }

      final report = ReportModel(
        id: '',
        userId: uid,
        title: title.trim(),
        description: description.trim(),
        category: category,
        status: ReportStatus.pending,
        photoUrl: photoUrl,
        latitude: latitude,
        longitude: longitude,
        address: address.trim(),
      );

      await _repository.createReport(report);
      await loadMyReports(uid);
      return true;
    } catch (e) {
      _error = _message(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Hapus laporan beserta fotonya, lalu refresh daftar.
  Future<bool> deleteReport(ReportModel report) async {
    _error = null;
    try {
      await _repository.deleteReport(report.id);
      final url = report.photoUrl;
      if (url != null && url.isNotEmpty) {
        await _storageService.deleteByUrl(url);
      }
      _myReports = _myReports
          .where((r) => r.id != report.id)
          .toList(growable: false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _message(e);
      notifyListeners();
      return false;
    }
  }

  String _message(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
  }
}
