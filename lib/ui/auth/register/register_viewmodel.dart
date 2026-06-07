import 'package:flutter/foundation.dart';

import '../../../core/state/view_status.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../domain/model/user.dart';
import '../../../domain/repository/auth_repository.dart';

/// ViewModel untuk layar registrasi.
///
/// Menerima [AuthRepository] lewat constructor injection.
class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  RegisterViewModel(this._authRepository);

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  String? _error;
  String? get error => _error;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get isLoading => _status == ViewStatus.loading;

  /// Daftar akun baru.
  Future<bool> register(String name, String email, String password) async {
    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signUp(
        name: name,
        email: email,
        password: password,
      );
      _status = ViewStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error = mapErrorToMessage(e);
      _status = ViewStatus.failure;
      notifyListeners();
      return false;
    }
  }

  /// Daftar / masuk dengan Google. Kembalikan `true` bila sukses; `false` bila
  /// gagal atau dibatalkan user (pembatalan tidak menampilkan error).
  Future<bool> registerWithGoogle() async {
    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepository.signInWithGoogle();
      if (user == null) {
        _status = ViewStatus.initial;
        notifyListeners();
        return false;
      }
      _currentUser = user;
      _status = ViewStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error = mapErrorToMessage(e);
      _status = ViewStatus.failure;
      notifyListeners();
      return false;
    }
  }
}
