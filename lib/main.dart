import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/utils/local_notification_service.dart';
import 'core/utils/push_notification_service.dart';
import 'data/remote/auth_remote_datasource.dart';
import 'data/remote/fcm_datasource.dart';
import 'data/remote/location_datasource.dart';
import 'data/remote/notification_remote_datasource.dart';
import 'data/remote/report_remote_datasource.dart';
import 'data/remote/storage_remote_datasource.dart';
import 'data/repository/auth_repository_impl.dart';
import 'data/repository/notification_repository_impl.dart';
import 'data/repository/report_repository_impl.dart';
import 'domain/repository/auth_repository.dart';
import 'domain/repository/notification_repository.dart';
import 'domain/repository/report_repository.dart';
import 'firebase_options.dart';

/// Entry point aplikasi SafeRoad.
///
/// Dependency injection:
/// 1. Buat semua DataSource (concrete implementation).
/// 2. Buat semua Repository (concrete impl, inject DataSource).
/// 3. Ekspos Repository via MultiProvider sebagai abstract interface.
/// 4. ViewModel dibuat per-route lewat ChangeNotifierProvider di masing-masing layar.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id');
  await LocalNotificationService.initialize();

  // ── FCM push handlers ──────────────────────────────────────────────
  // Background/terminated handler harus didaftarkan sebelum runApp; handler
  // foreground & "dibuka dari notifikasi" menampilkan notifikasi sistem dan
  // memicu deep link ke halaman notifikasi (callback di-set oleh AuthGate).
  PushNotificationService.registerBackgroundHandler();
  PushNotificationService.initForegroundHandlers();

  // ── DataSource ─────────────────────────────────────────────────────
  final authDataSource = FirebaseAuthRemoteDataSource();
  final reportDataSource = FirestoreReportRemoteDataSource();
  final storageDataSource = ImageKitStorageRemoteDataSource();
  final locationDataSource = GeolocatorLocationDataSource();
  final fcmDataSource = FirebaseFcmDataSource();
  final notifDataSource = FirestoreNotificationRemoteDataSource();

  // ── Repository ─────────────────────────────────────────────────────
  final authRepository = AuthRepositoryImpl(authDataSource);
  final reportRepository = ReportRepositoryImpl(
    reportDataSource: reportDataSource,
    storageDataSource: storageDataSource,
    locationDataSource: locationDataSource,
  );
  final notificationRepository = NotificationRepositoryImpl(
    fcmDataSource,
    notifDataSource,
  );

  // ── Inisialisasi FCM (Non-blocking) ──────────────────────────────
  // Dilakukan secara asinkron agar tidak menghambat startup bila FIS/FCM bermasalah.
  unawaited(() async {
    try {
      await notificationRepository.initialize();
      final token = await notificationRepository.getToken();
      // Token dicetak agar mudah dipakai untuk uji kirim dari Firebase Console.
      debugPrint('FCM token: $token');
      final uid = authRepository.currentUserId;
      if (uid != null && token != null) {
        await authRepository.updateFcmToken(uid: uid, token: token);
      }
      // Dengarkan token refresh.
      notificationRepository.onTokenRefresh().listen((newToken) {
        final currentUid = authRepository.currentUserId;
        if (currentUid != null) {
          authRepository.updateFcmToken(uid: currentUid, token: newToken);
        }
      });
    } catch (e) {
      debugPrint('FCM Initialization failed: $e');
    }
  }());

  // ── Run App ────────────────────────────────────────────────────────
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<ReportRepository>.value(value: reportRepository),
        Provider<NotificationRepository>.value(value: notificationRepository),
      ],
      child: SafeRoadApp(authRepository: authRepository),
    ),
  );
}
