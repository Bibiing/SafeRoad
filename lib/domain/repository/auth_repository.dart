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

  /// Masuk / daftar dengan akun Google.
  ///
  /// Kembalikan profil [AppUser]; bila user baru, dokumen `users/{uid}` dibuat
  /// dengan role default `user` dan provider `google`. Mengembalikan `null`
  /// bila user membatalkan dialog Google (bukan error).
  Future<AppUser?> signInWithGoogle();

  /// Logout dari sesi aktif (termasuk sesi Google bila ada).
  Future<void> signOut();

  /// Perbarui FCM token di profil user.
  Future<void> updateFcmToken({required String uid, required String token});

  /// Tambahkan [delta] poin kontribusi ke `users/{uid}` (akumulatif).
  Future<void> incrementPoints(String uid, int delta);
}
