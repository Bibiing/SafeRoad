import 'package:flutter/foundation.dart';

import '../../../domain/model/user.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../auth/login/login_viewmodel.dart';

/// ViewModel untuk tab Profil.
class ProfileViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final ReportRepository _reportRepository;

  ProfileViewModel({
    required AuthRepository authRepository,
    required ReportRepository reportRepository,
  })  : _authRepository = authRepository,
        _reportRepository = reportRepository;

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  String? _error;
  String? get error => _error;

  AppUser? _user;
  AppUser? get user => _user;

  int _reportCount = 0;
  int get reportCount => _reportCount;

  bool get isLoading => _status == ViewStatus.loading;

  /// Muat data profil dan jumlah laporan.
  Future<void> loadProfile() async {
    final uid = _authRepository.currentUserId;
    if (uid == null) return;

    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.fetchUser(uid);
      final reports = await _reportRepository.getReportsByUser(uid);
      _reportCount = reports.length;
      _status = ViewStatus.success;
    } catch (e) {
      _error = _extractMessage(e);
      _status = ViewStatus.failure;
    }
    notifyListeners();
  }

  /// Logout.
  Future<void> logout() async {
    await _authRepository.signOut();
    _user = null;
    notifyListeners();
  }

  String _extractMessage(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
  }
}
