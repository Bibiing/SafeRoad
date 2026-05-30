import '../../domain/repository/notification_repository.dart';
import '../remote/fcm_datasource.dart';

/// Implementasi konkret [NotificationRepository].
///
/// Mendelegasikan ke [FcmDataSource] untuk interaksi Firebase Messaging.
class NotificationRepositoryImpl implements NotificationRepository {
  final FcmDataSource _fcmDataSource;

  NotificationRepositoryImpl(this._fcmDataSource);

  @override
  Future<void> initialize() => _fcmDataSource.initialize();

  @override
  Future<String?> getToken() => _fcmDataSource.getToken();

  @override
  Stream<String> onTokenRefresh() => _fcmDataSource.onTokenRefresh();
}
