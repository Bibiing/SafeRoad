/// Model domain untuk notifikasi perubahan status laporan.
///
/// Setiap notifikasi disimpan di Firestore path:
/// `notifications/{userId}/items/{notificationId}`
class AppNotification {
  final String id;
  final String reportId;
  final String reportTitle;
  final String title;
  final String body;
  final String oldStatus;
  final String newStatus;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.reportId,
    required this.reportTitle,
    required this.title,
    required this.body,
    required this.oldStatus,
    required this.newStatus,
    required this.isRead,
    required this.createdAt,
  });
}
