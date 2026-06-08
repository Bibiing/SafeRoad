import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/connectivity_service.dart';
import 'core/utils/local_notification_service.dart';
import 'core/utils/notification_listener_service.dart';
import 'core/utils/push_notification_service.dart';
import 'core/widgets/primary_button.dart';
import 'domain/model/user.dart';
import 'domain/repository/auth_repository.dart';
import 'domain/repository/notification_repository.dart';
import 'ui/additional/notifications/notifications_screen.dart';
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

  /// Navigator key global — digunakan oleh [LocalNotificationService] dan
  /// [PushNotificationService] untuk navigasi deep link saat user mengetuk
  /// notifikasi, serta untuk menampilkan dialog offline dari luar widget tree.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Messenger key global untuk menampilkan SnackBar dari luar widget tree
  /// (mis. saat koneksi internet kembali tersedia).
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRoad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
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

  // ── Deteksi koneksi (peringatan offline) ──
  final _connectivity = ConnectivityService();
  StreamSubscription<bool>? _connSub;
  Timer? _connDebounce;
  bool _offlineDialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Tap notifikasi (lokal maupun FCM; foreground/background/terminated) →
    // buka halaman notifikasi di dalam app.
    LocalNotificationService.onNotificationTap = (_) => _openNotifications();
    PushNotificationService.onNotificationOpen = _openNotifications;
    // Tangani app yang diluncurkan dari kondisi terminated via tap notifikasi.
    PushNotificationService.checkInitialMessage();
    _setupConnectivityMonitor();
  }

  @override
  void dispose() {
    _notifListener.stopListening();
    LocalNotificationService.onNotificationTap = null;
    PushNotificationService.onNotificationOpen = null;
    _connSub?.cancel();
    _connDebounce?.cancel();
    super.dispose();
  }

  // ── Connectivity ───────────────────────────────────────────────────

  void _setupConnectivityMonitor() {
    // Status awal setelah frame pertama (agar navigator siap menampilkan dialog).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final online = await _connectivity.isOnline();
      if (!online) _showOfflineDialog();
    });

    // Pantau perubahan dengan sedikit debounce agar fluktuasi koneksi sesaat
    // tidak memunculkan/menutup dialog berulang-ulang.
    _connSub = _connectivity.onStatusChange.listen((online) {
      _connDebounce?.cancel();
      _connDebounce = Timer(const Duration(milliseconds: 800), () {
        if (online) {
          _dismissOfflineDialog();
        } else {
          _showOfflineDialog();
        }
      });
    });
  }

  void _showOfflineDialog() {
    if (_offlineDialogShowing) return;
    final context = SafeRoadApp.navigatorKey.currentContext;
    if (context == null) return;
    _offlineDialogShowing = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _OfflineDialog(),
    ).then((_) => _offlineDialogShowing = false);
  }

  void _dismissOfflineDialog() {
    if (!_offlineDialogShowing) return;
    // Tutup dialog offline (flag direset oleh .then di _showOfflineDialog).
    SafeRoadApp.navigatorKey.currentState?.pop();
    SafeRoadApp.scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Koneksi kembali tersedia'),
          backgroundColor: AppColors.success,
        ),
      );
  }

  /// Buka halaman daftar notifikasi via [SafeRoadApp.navigatorKey] global,
  /// sehingga bisa dipanggil dari luar widget tree (handler FCM).
  ///
  /// [NotificationsScreen] membaca `NotificationRepository` & `AuthRepository`
  /// dari Provider yang berada di atas MaterialApp (lihat main.dart), sehingga
  /// aman dipush via navigatorKey.
  void _openNotifications() {
    debugPrint('AuthGate: notification tapped → open NotificationsScreen');
    SafeRoadApp.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
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

/// Dialog peringatan saat perangkat kehilangan koneksi internet.
///
/// Tidak bisa ditutup dengan tap di luar (barrierDismissible: false). User
/// memilih **Lanjutkan** (tetap memakai app dalam kondisi terbatas) atau
/// **Keluar**. Dialog ditutup otomatis saat koneksi kembali (lihat
/// `_AuthGateState._dismissOfflineDialog`).
class _OfflineDialog extends StatelessWidget {
  const _OfflineDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.wifi_off_rounded,
          color: AppColors.warning, size: 40),
      title: Text(
        'Anda Sedang Offline',
        style: AppTextStyles.title,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Beberapa fitur mungkin terganggu karena tidak ada koneksi internet.',
            style: AppTextStyles.body
                .copyWith(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Lanjutkan',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            // Keluar aplikasi. Di Android menutup app; di iOS Apple tidak
            // mengizinkan keluar secara programatik (kebijakan App Store),
            // sehingga SystemNavigator.pop() di iOS hanya men-minimize app.
            onPressed: () => SystemNavigator.pop(),
            icon: const Icon(Icons.close),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
