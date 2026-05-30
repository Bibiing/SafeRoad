import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/login/login_screen.dart';
import '../user/home/home_screen.dart';
import '../../domain/repository/auth_repository.dart';
import 'package:provider/provider.dart';

/// Layar splash beranimasi yang tampil setelah native splash,
/// sebelum masuk ke alur AuthGate.
///
/// Animasi:
/// - Logo: fade-in + scale dari 0.75 → 1.0 (curve: easeOutBack)
/// - Teks "SafeRoad": fade-in + slide-up 12px (dengan delay)
/// - Total durasi: ~2.3 detik, lalu navigasi ke AuthGate.
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // ── Logo animations ────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // ── Text animations (delayed) ──────────────────────────────────────
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Logo: scale 0.75 → 1.0 dengan easeOutBack (efek pop ramah)
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    // Logo: opacity 0 → 1
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    // Teks: opacity 0 → 1 (mulai setelah 40% controller)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
      ),
    );

    // Teks: slide dari bawah 12px → posisi normal
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
      ),
    );

    // Jalankan animasi lalu navigate setelah total ~2.3 detik
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 900), _navigateNext);
    });
  }

  /// Navigate ke AuthGate (login atau home berdasarkan status Firebase Auth).
  void _navigateNext() {
    if (!mounted) return;
    final authRepository = context.read<AuthRepository>();
    final uid = authRepository.currentUserId;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            uid != null ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo ────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    'assets/images/logo-saferoad.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Teks "SafeRoad" ──────────────────────────────────────
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    children: [
                      Text(
                        'SafeRoad',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 30,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Laporkan kerusakan jalan & fasilitas publik',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
