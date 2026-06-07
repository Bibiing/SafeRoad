import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service statis untuk menampilkan notifikasi lokal (system tray).
///
/// Digunakan saat app di foreground, mengubah Firestore event menjadi
/// notifikasi yang terlihat di notification shade Android.
class LocalNotificationService {
  LocalNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Callback yang dipanggil saat user mengetuk notifikasi.
  ///
  /// Payload berisi JSON string `{"reportId": "<id>"}`.
  static void Function(String reportId)? onNotificationTap;

  static const _channelId = 'saferoad_status_updates';
  static const _channelName = 'Status Laporan';
  static const _channelDesc =
      'Notifikasi saat admin mengubah status laporan kamu.';

  /// Inisialisasi plugin dan buat Android notification channel.
  ///
  /// Harus dipanggil sekali di [main] sebelum [runApp].
  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    await _createAndroidChannel();
    debugPrint('LocalNotificationService: initialized');
  }

  /// Tampilkan notifikasi dengan judul [title] dan isi [body].
  ///
  /// [id] harus unik per notifikasi (gunakan `hashCode` dari notif ID).
  /// [payload] adalah JSON string `{"reportId": "<id>"}`.
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final reportId = data['reportId'] as String?;
      if (reportId != null && reportId.isNotEmpty) {
        onNotificationTap?.call(reportId);
      }
    } catch (e) {
      debugPrint('LocalNotificationService: invalid payload – $e');
    }
  }

  static Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
