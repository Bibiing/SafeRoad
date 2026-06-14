import 'package:saferoad/core/theme/app_colors_extension.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/repository/auth_repository.dart';

/// Layar splash beranimasi yang tampil setelah native splash, sebelum masuk
/// ke alur [AuthGate].
///
/// Animasi (memakai `flutter_animate`):
/// - Logo: fade-in + scale-up (0.8 遶翫・1.0) + sedikit naik (16px 遶翫・0) dengan
///   curve `easeOutCubic`, lalu satu micro pulse halus (1.0 遶翫・1.02 遶翫・1.0).
///   Di bawah logo ada bayangan hijau lembut yang mengikuti bentuk logo
///   (kesan "mengambang"), bukan glow mencolok.
/// - Teks "SafeRoad" + tagline: fade-in + slide-up berurutan (staggered).
/// - Total ~2.6 detik lalu fade-transition ke [AuthGate].
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  static const _holdDuration = Duration(milliseconds: 2600);

  @override
  void initState() {
    super.initState();
    // `flutter_animate` mengelola siklus animasi sendiri (tidak ada controller
    // manual yang perlu di-dispose). Kita hanya menjadwalkan navigasi.
    Future.delayed(_holdDuration, _navigateNext);
  }

  /// Navigasi ke [AuthGate] agar routing berbasis peran (user/admin) konsisten,
  /// termasuk saat cold-start dengan sesi yang masih aktif.
  void _navigateNext() {
    if (!mounted) return;
    final authRepository = context.read<AuthRepository>();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => AuthGate(authRepository: authRepository),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [context.appColors.primaryTint, context.appColors.background],
            stops: [0.0, 0.55],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 隨渉隨渉 Logo + bayangan hijau natural 隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉
              const _LogoWithShadow()
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                  .scaleXY(
                    begin: 0.8,
                    end: 1.0,
                    duration: 700.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .moveY(
                    begin: 16,
                    end: 0,
                    duration: 700.ms,
                    curve: Curves.easeOutCubic,
                  )
                  // Micro pulse sekali setelah logo muncul (naik lalu kembali).
                  .then(delay: 240.ms)
                  .scaleXY(
                    begin: 1.0,
                    end: 1.02,
                    duration: 560.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scaleXY(
                    begin: 1.02,
                    end: 1.0,
                    duration: 560.ms,
                    curve: Curves.easeInOut,
                  ),

              const SizedBox(height: 28),

              // 隨渉隨渉 Teks "SafeRoad" 隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉
              Text(
                AppConstants.appName,
                style: AppTextStyles.heading.copyWith(
                  fontSize: 30,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 520.ms, duration: 520.ms)
                  .moveY(begin: 12, end: 0, delay: 520.ms, duration: 520.ms),

              const SizedBox(height: 8),

              // 隨渉隨渉 Tagline 隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉隨渉
              Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: context.appColors.textSecondary,
                  fontSize: 13,
                ),
              )
                  .animate()
                  .fadeIn(delay: 760.ms, duration: 520.ms)
                  .moveY(begin: 12, end: 0, delay: 760.ms, duration: 520.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo SafeRoad dengan bayangan hijau lembut.
///
/// Bayangan dibuat dari siluet logo itu sendiri (di-tint hijau via
/// `BlendMode.srcIn`), di-blur, lalu digeser sedikit ke bawah 遯ｶ繝ｻsehingga
/// bayangan mengikuti bentuk logo dan tidak terlihat seperti kotak meski
/// logo punya area transparan.
class _LogoWithShadow extends StatelessWidget {
  const _LogoWithShadow();

  static const double _size = 118;
  static const String _asset = 'assets/images/logo-saferoad.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, 10),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Image.asset(
              _asset,
              width: _size,
              height: _size,
              fit: BoxFit.contain,
              color: AppColors.primary.withValues(alpha: 0.28),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
        Image.asset(
          _asset,
          width: _size,
          height: _size,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
