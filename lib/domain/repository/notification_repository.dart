import '../model/enums.dart';
import '../model/notification_model.dart';

/// Abstraksi repository notifikasi.
///
/// Menggabungkan dua tanggung jawab:
/// 1. FCM: Inisialisasi, token management.
/// 2. Firestore: CRUD notifikasi perubahan status laporan.
abstract class NotificationRepository {
  // ── FCM ──────────────────────────────────────────────────────────────────

  /// Minta izin notifikasi dan subscribe ke topik FCM.
  Future<void> initialize();

  /// Ambil FCM token perangkat saat ini.
  Future<String?> getToken();

  /// Stream token baru setiap kali token di-refresh oleh FCM.
  Stream<String> onTokenRefresh();

  // ── Firestore Notifications ───────────────────────────────────────────────

  /// Tulis notifikasi perubahan status ke Firestore milik [userId].
  ///
  /// Dipanggil oleh admin saat mengubah status laporan.
  Future<void> sendStatusChangeNotification({
    required String userId,
    required String reportId,
    required String reportTitle,
    required ReportStatus oldStatus,
    required ReportStatus newStatus,
  });

  /// Stream daftar notifikasi user [userId], urut terbaru di atas.
  Stream<List<AppNotification>> watchNotifications(String userId);

  /// Tandai satu notifikasi [notificationId] milik [userId] sudah dibaca.
  Future<void> markAsRead(String userId, String notificationId);

  /// Stream jumlah notifikasi belum dibaca milik [userId].
  Stream<int> watchUnreadCount(String userId);

  /// Tandai semua notifikasi milik [userId] sudah dibaca.
  Future<void> markAllAsRead(String userId);
}
