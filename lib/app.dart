import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/local_notification_service.dart';
import 'core/utils/notification_listener_service.dart';
import 'domain/model/user.dart';
import 'domain/repository/auth_repository.dart';
import 'domain/repository/notification_repository.dart';
import 'ui/admin/dashboard/admin_dashboard_screen.dart';
import 'ui/auth/login/login_screen.dart';
import 'ui/splash/animated_splash_screen.dart';
import 'ui/user/home/home_screen.dart';

/// Widget root aplikasi SafeRoad.
///
/// Alur startup:
///   Native Splash (flutter_native_splash)
///   → AnimatedSplashScreen (logo animasi ~2.3 detik)
///   → _AuthGate (routing berdasarkan status Firebase Auth)
class SafeRoadApp extends StatelessWidget {
  final AuthRepository authRepository;

  const SafeRoadApp({super.key, required this.authRepository});

  /// Navigator key global — digunakan oleh [LocalNotificationService]
  /// untuk navigasi deep link saat user mengetuk notifikasi.
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRoad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      // Splash beranimasi sebagai layar pertama.
      // Setelah animasi selesai, splash navigate ke AuthGate secara manual.
      home: const AnimatedSplashScreen(),
    );
  }
}

/// Tentukan layar berikutnya berdasarkan status login Firebase dan Peran (Role).
class AuthGate extends StatefulWidget {
  final AuthRepository authRepository;

  const AuthGate({super.key, required this.authRepository});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _notifListener = NotificationListenerService();
  String? _listeningForUid;

  @override
  void initState() {
    super.initState();
    // Setup tap handler: saat user ketuk notifikasi → navigasi ke laporan.
    LocalNotificationService.onNotificationTap = _handleNotificationTap;
  }

  @override
  void dispose() {
    _notifListener.stopListening();
    LocalNotificationService.onNotificationTap = null;
    super.dispose();
  }

  void _handleNotificationTap(String reportId) {
    debugPrint('AuthGate: notification tapped, reportId=$reportId');
    // TODO (Alvin): navigasi ke halaman detail laporan user saat tap notif.
    // Contoh navigasi:
    // SafeRoadApp.navigatorKey.currentState?.push(
    //   MaterialPageRoute(builder: (_) => ReportDetailScreen(reportId: reportId)),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final notifRepo = context.read<NotificationRepository>();

    return StreamBuilder<String?>(
      stream: widget.authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final uid = snapshot.data;

        if (uid != null) {
          // Mulai listener notifikasi bila belum atau UID berubah.
          if (_listeningForUid != uid) {
            _listeningForUid = uid;
            _notifListener.startListening(uid, notifRepo);
          }

          // User terautentikasi → Ambil profil untuk cek role.
          return FutureBuilder<AppUser?>(
            future: widget.authRepository.fetchUser(uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final user = userSnapshot.data;
              debugPrint('AuthGate: User UID=$uid, Role=${user?.role}, IsAdmin=${user?.isAdmin}');

              if (user != null && user.isAdmin) {
                return const AdminDashboardScreen();
              }

              // Default ke HomeScreen jika profil gagal diambil atau bukan admin.
              return const HomeScreen();
            },
          );
        }

        // User logout → hentikan listener.
        if (_listeningForUid != null) {
          _notifListener.stopListening();
          _listeningForUid = null;
        }

        // Belum login → Login.
        return const LoginScreen();
      },
    );
  }
}
