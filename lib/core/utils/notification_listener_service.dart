import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/model/notification_model.dart';
import '../../domain/repository/notification_repository.dart';
import 'local_notification_service.dart';

/// Service yang mendengarkan stream notifikasi Firestore dan
/// menampilkan notifikasi sistem via [LocalNotificationService].
///
/// Siklus hidup:
/// - [startListening] → dipanggil setelah user login.
/// - [stopListening]  → dipanggil saat user logout.
class NotificationListenerService {
  StreamSubscription<List<AppNotification>>? _sub;

  /// Set ID notifikasi yang sudah ditampilkan dalam sesi ini
  /// agar tidak ditampilkan ulang saat stream emit ulang.
  final Set<String> _shown = {};

  /// Mulai mendengarkan notifikasi milik [userId].
  ///
  /// Setiap notifikasi baru yang belum dibaca akan ditampilkan
  /// sebagai system notification via [LocalNotificationService.show].
  void startListening(String userId, NotificationRepository repo) {
    _sub?.cancel();
    _shown.clear();

    _sub = repo.watchNotifications(userId).listen(
      (notifications) {
        for (final notif in notifications) {
          if (!notif.isRead && !_shown.contains(notif.id)) {
            _shown.add(notif.id);
            LocalNotificationService.show(
              id: notif.id.hashCode,
              title: notif.title,
              body: notif.body,
              payload: jsonEncode({'reportId': notif.reportId}),
            );
          }
        }
      },
      onError: (Object e) {
        debugPrint('NotificationListenerService: error – $e');
      },
    );

    debugPrint('NotificationListenerService: listening for uid=$userId');
  }

  /// Hentikan pendengaran dan bersihkan state.
  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _shown.clear();
    debugPrint('NotificationListenerService: stopped');
  }
}
