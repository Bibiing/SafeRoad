/// Abstraksi repository notifikasi (FCM).
///
/// Mengelola inisialisasi FCM, token, dan listener pesan masuk.
/// Concrete impl: [NotificationRepositoryImpl].
abstract class NotificationRepository {
  /// Inisialisasi FCM dan minta izin notifikasi.
  Future<void> initialize();

  /// Ambil FCM token perangkat saat ini.
  Future<String?> getToken();

  /// Stream perubahan token (token refresh).
  Stream<String> onTokenRefresh();
}
