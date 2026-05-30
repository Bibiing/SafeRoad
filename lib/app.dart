import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'domain/repository/auth_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRoad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Splash beranimasi sebagai layar pertama.
      // Setelah animasi selesai, splash navigate ke AuthGate secara manual.
      home: const AnimatedSplashScreen(),
    );
  }
}

/// Tentukan layar berikutnya berdasarkan status login Firebase.
///
/// Dipanggil oleh [AnimatedSplashScreen] setelah animasi selesai,
/// dan juga tersedia sebagai rute terpisah untuk keperluan lain.
class AuthGate extends StatelessWidget {
  final AuthRepository authRepository;

  const AuthGate({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // User terautentikasi → Home.
        if (snapshot.data != null) {
          return const HomeScreen();
        }
        // Belum login → Login.
        return const LoginScreen();
      },
    );
  }
}
