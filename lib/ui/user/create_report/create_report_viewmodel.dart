import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../auth/login/login_viewmodel.dart';

/// ViewModel untuk layar Buat Laporan.
class CreateReportViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;
  final AuthRepository _authRepository;

  CreateReportViewModel({
    required ReportRepository reportRepository,
    required AuthRepository authRepository,
  })  : _reportRepository = reportRepository,
        _authRepository = authRepository;

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  String? _error;
  String? get error => _error;

  bool get isSubmitting => _status == ViewStatus.loading;

  // ── Lokasi ──
  double? _latitude;
  double? get latitude => _latitude;

  double? _longitude;
  double? get longitude => _longitude;

  String _address = '';
  String get address => _address;

  bool _locating = false;
  bool get isLocating => _locating;

  bool get hasLocation => _latitude != null && _longitude != null;

  /// Ambil lokasi GPS saat ini dan reverse geocoding alamat.
  Future<void> fetchCurrentLocation() async {
    _locating = true;
    _error = null;
    notifyListeners();

    try {
      final loc = await _reportRepository.getCurrentLocation();
      _latitude = loc.latitude;
      _longitude = loc.longitude;
      _address = await _reportRepository.getAddressFromCoordinates(
        loc.latitude,
        loc.longitude,
      );
    } catch (e) {
      _error = _extractMessage(e);
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  /// Submit laporan baru.
  Future<bool> submitReport({
    required String title,
    required String description,
    required ReportCategory category,
    List<File> images = const [],
  }) async {
    final uid = _authRepository.currentUserId;
    if (uid == null) {
      _error = 'User belum login.';
      notifyListeners();
      return false;
    }

    if (!hasLocation) {
      _error = 'Ambil lokasi terlebih dahulu.';
      notifyListeners();
      return false;
    }

    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // Upload foto.
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _reportRepository.uploadImages(
          userId: uid,
          files: images,
        );
      }

      final report = Report(
        id: '',
        userId: uid,
        title: title.trim(),
        description: description.trim(),
        category: category,
        imageUrls: imageUrls,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address,
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _reportRepository.createReport(report);
      _status = ViewStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractMessage(e);
      _status = ViewStatus.failure;
      notifyListeners();
      return false;
    }
  }

  String _extractMessage(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
  }
}
