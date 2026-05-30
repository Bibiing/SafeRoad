// TODO(session): implementasi penyimpanan sesi lokal (opsional).
// Bisa menggunakan SharedPreferences untuk cache data user offline.

/// Abstraksi data source sesi lokal.
abstract class SessionLocalDataSource {
  /// Simpan UID user yang sedang login.
  Future<void> saveUserId(String uid);

  /// Ambil UID user yang tersimpan.
  Future<String?> getUserId();

  /// Hapus sesi lokal.
  Future<void> clear();
}
