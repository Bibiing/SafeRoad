import 'package:firebase_messaging/firebase_messaging.dart';

/// Abstraksi data source Firebase Cloud Messaging.
abstract class FcmDataSource {
  /// Inisialisasi FCM dan minta izin notifikasi.
  Future<void> initialize();

  /// Ambil FCM token perangkat.
  Future<String?> getToken();

  /// Stream token refresh.
  Stream<String> onTokenRefresh();
}

/// Implementasi [FcmDataSource] menggunakan Firebase Messaging.
class FirebaseFcmDataSource implements FcmDataSource {
  final FirebaseMessaging _messaging;

  FirebaseFcmDataSource({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  @override
  Future<void> initialize() async {
    // Minta izin notifikasi (terutama iOS).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Subscribe ke topic umum untuk broadcast.
    await _messaging.subscribeToTopic('all_reports');
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> onTokenRefresh() => _messaging.onTokenRefresh;
}
