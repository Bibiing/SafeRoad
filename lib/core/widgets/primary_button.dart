import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
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

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: child,
    );
  }
}
