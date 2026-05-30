import '../model/user.dart';

/// Abstraksi repository autentikasi.
///
/// ViewModel hanya bergantung pada interface ini, bukan pada implementasi
/// Firebase secara langsung. Concrete impl: [AuthRepositoryImpl].
abstract class AuthRepository {
  /// Stream perubahan status login. Emit `null` saat user logout.
  Stream<String?> authStateChanges();

  /// UID user yang sedang login, atau `null`.
  String? get currentUserId;

  /// Ambil profil [AppUser] berdasarkan [uid].
  Future<AppUser?> fetchUser(String uid);

  /// Login dengan email & password. Kembalikan profil user.
  Future<AppUser> signIn({required String email, required String password});

  /// Daftar akun baru. Kembalikan profil user yang baru dibuat.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Logout dari sesi aktif.
  Future<void> signOut();

  /// Perbarui FCM token di profil user.
  Future<void> updateFcmToken({required String uid, required String token});
}
