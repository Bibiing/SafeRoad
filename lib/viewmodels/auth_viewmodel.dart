import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// State + logika autentikasi. Murni Dart + ChangeNotifier; Service di-inject.
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel(this._authService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  /// Muat profil user yang sedang login (mis. saat app start).
  Future<void> loadCurrentUser() async {
    final fbUser = _authService.currentUser;
    if (fbUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    _setLoading(true);
    try {
      _currentUser = await _authService.fetchUserModel(fbUser.uid);
      _error = null;
    } catch (e) {
      _error = _message(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = _message(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = _message(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _message(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : text;
  }
}
