import 'package:flutter/foundation.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/user.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../../core/state/view_status.dart';
import '../../../core/utils/achievements.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/level_system.dart';

/// ViewModel untuk tab Profil.
class ProfileViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final ReportRepository _reportRepository;

  ProfileViewModel({
    required this._authRepository,
    required this._reportRepository,
  });

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  String? _error;
  String? get error => _error;

  AppUser? _user;
  AppUser? get user => _user;

  int _reportCount = 0;
  int get reportCount => _reportCount;

  int _reportsCompleted = 0;

  bool get isLoading => _status == ViewStatus.loading;

  // ── Statistik kontribusi (Tahap 6) ──
  /// Jumlah laporan yang dikirim user.
  int get reportsSubmitted => _reportCount;

  /// Jumlah laporan user berstatus selesai.
  int get reportsCompleted => _reportsCompleted;

  /// Poin kontribusi akumulatif.
  int get contributionPoints => _user?.contributionPoints ?? 0;

  /// Level dihitung dari poin.
  int get level => LevelSystem.levelFromPoints(contributionPoints);

  /// Nama tier (Pemula / Kontributor / Pro Reporter).
  String get tier => LevelSystem.tierFromPoints(contributionPoints);

  /// Progres menuju level berikutnya (0.0–1.0).
  double get levelProgress => LevelSystem.levelProgress(contributionPoints);

  /// Sisa poin menuju level berikutnya.
  int get pointsToNextLevel =>
      LevelSystem.pointsToNextLevel(contributionPoints);

  AchievementStats get _stats => AchievementStats(
        reportsSubmitted: reportsSubmitted,
        reportsCompleted: reportsCompleted,
        points: contributionPoints,
      );

  /// Daftar achievement dengan status terbuka/terkunci.
  List<AchievementStatus> get achievements => Achievements.evaluate(_stats);

  /// Jumlah achievement yang terbuka.
  int get achievementsUnlocked => Achievements.unlockedCount(_stats);

  /// Muat data profil dan statistik laporan.
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
      _reportsCompleted =
          reports.where((r) => r.status == ReportStatus.completed).length;
      _status = ViewStatus.success;
    } catch (e) {
      _error = mapErrorToMessage(e);
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

}
