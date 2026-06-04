import '../../domain/model/enums.dart';
import '../../domain/model/notification_model.dart';
import '../../domain/repository/notification_repository.dart';
import '../remote/fcm_datasource.dart';
import '../remote/notification_remote_datasource.dart';

/// Implementasi konkret [NotificationRepository].
///
/// Menggabungkan [FcmDataSource] (token/izin FCM) dan
/// [NotificationRemoteDataSource] (notifikasi berbasis Firestore).
class NotificationRepositoryImpl implements NotificationRepository {
  final FcmDataSource _fcmDataSource;
  final NotificationRemoteDataSource _notifDataSource;

  NotificationRepositoryImpl(this._fcmDataSource, this._notifDataSource);

  // ── FCM ──────────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() => _fcmDataSource.initialize();

  @override
  Future<String?> getToken() => _fcmDataSource.getToken();

  @override
  Stream<String> onTokenRefresh() => _fcmDataSource.onTokenRefresh();

  // ── Firestore Notifications ───────────────────────────────────────────────

  @override
  Future<void> sendStatusChangeNotification({
    required String userId,
    required String reportId,
    required String reportTitle,
    required ReportStatus oldStatus,
    required ReportStatus newStatus,
  }) =>
      _notifDataSource.createStatusChangeNotification(
        userId: userId,
        reportId: reportId,
        reportTitle: reportTitle,
        oldStatus: oldStatus,
        newStatus: newStatus,
      );

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      _notifDataSource.watchNotifications(userId);

  @override
  Future<void> markAsRead(String userId, String notificationId) =>
      _notifDataSource.markAsRead(userId, notificationId);

  @override
  Stream<int> watchUnreadCount(String userId) =>
      _notifDataSource.watchUnreadCount(userId);

  @override
  Future<void> markAllAsRead(String userId) =>
      _notifDataSource.markAllAsRead(userId);
}
