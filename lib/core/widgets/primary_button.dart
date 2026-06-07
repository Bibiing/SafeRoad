import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Tombol primer SafeRoad — hijau solid dengan loading state.
class PrimaryButton extends StatelessWidget {
  /// Label teks tombol.
  final String label;

  /// Callback saat ditekan.
  final VoidCallback? onPressed;

  /// Tampilkan spinner saat loading.
  final bool loading;

  /// Ikon opsional di sebelah kiri label.
  final IconData? icon;

  /// Tambahkan glow hijau lembut di belakang tombol (mis. layar auth).
  final bool glow;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onPrimary,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: child,
    );

    if (!glow) return button;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: button,
    );
  }
}
