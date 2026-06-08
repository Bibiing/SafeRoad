import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../firebase_options.dart';
import 'local_notification_service.dart';

/// Handler pesan FCM saat aplikasi berada di **background** atau **terminated**.
///
/// WAJIB berupa fungsi **top-level** (atau `static`) dengan anotasi
/// `@pragma('vm:entry-point')` — ini requirement Firebase Messaging karena
/// handler dieksekusi pada isolate terpisah di luar widget tree.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Isolate terpisah → Firebase & plugin notifikasi perlu diinisialisasi ulang.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.initialize();

  // Pesan dengan blok `notification` sudah ditampilkan OS di system tray.
  // Pesan data-only tidak → tampilkan manual agar tetap muncul di notifikasi HP.
  if (message.notification == null) {
    await PushNotificationService.showFromRemote(message);
  }
}

/// Jembatan Firebase Cloud Messaging → notifikasi sistem + deep link.
///
/// Mengikuti pola service statis seperti [LocalNotificationService]
/// (infrastruktur, bukan data domain) sehingga tidak melewati repository.
class PushNotificationService {
  PushNotificationService._();

  /// Dipanggil saat user mengetuk notifikasi → membuka halaman notifikasi.
  static void Function()? onNotificationOpen;

  /// Daftarkan handler background. Panggil di `main()` setelah Firebase init.
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Pasang listener foreground & saat notifikasi membuka app dari background.
  static void initForegroundHandlers() {
    // Foreground: OS tidak menampilkan notifikasi otomatis → tampilkan sendiri.
    FirebaseMessaging.onMessage.listen(showFromRemote);
    // App di background lalu dibuka via tap notifikasi.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (_) => onNotificationOpen?.call(),
    );
  }

  /// Periksa apakah app diluncurkan dari kondisi terminated via tap notifikasi.
  ///
  /// Panggil setelah [onNotificationOpen] di-set agar tap awal tidak terlewat.
  static Future<void> checkInitialMessage() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) onNotificationOpen?.call();
  }

  /// Tampilkan [message] sebagai notifikasi sistem via local notifications.
  static Future<void> showFromRemote(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final title =
        notification?.title ?? (data['title'] as String?) ?? 'SafeRoad';
    final body = notification?.body ?? (data['body'] as String?) ?? '';
    if (title.isEmpty && body.isEmpty) return;

    await LocalNotificationService.show(
      id: (message.messageId ?? DateTime.now().toIso8601String()).hashCode,
      title: title,
      body: body,
      payload: jsonEncode(data),
    );
  }
}
