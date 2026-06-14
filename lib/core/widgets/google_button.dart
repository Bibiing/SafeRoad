import 'package:saferoad/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'google_logo.dart';

/// Tombol "Masuk/Daftar dengan Google" 窶・putih, border, logo Google.
class GoogleSignInButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const GoogleSignInButton({
    super.key,
    required this.label,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.appColors.textPrimary,
          backgroundColor: context.appColors.surface,
          side: BorderSide(color: context.appColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GoogleLogo(size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: AppTextStyles.button
                        .copyWith(color: context.appColors.textPrimary),
                  ),
                ],
              ),
      ),
    );
  }
}
