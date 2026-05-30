import 'package:flutter/foundation.dart';

import '../../../domain/model/user.dart';
import '../../../domain/repository/auth_repository.dart';

/// Status operasi async.
enum ViewStatus { initial, loading, success, failure }

/// ViewModel untuk layar login.
///
/// Menerima [AuthRepository] lewat constructor injection.
/// Tidak mengimpor `package:flutter/widgets.dart`.
class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginViewModel(this._authRepository);

  // ── State ──────────────────────────────────────────────────────────
  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  String? _error;
  String? get error => _error;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get isLoading => _status == ViewStatus.loading;

  // ── Commands ───────────────────────────────────────────────────────

  /// Login dengan email dan password.
  Future<bool> login(String email, String password) async {
    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signIn(
        email: email,
        password: password,
      );
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
