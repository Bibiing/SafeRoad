import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color surface;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color primaryTint;

  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.primaryTint,
  });

  static const light = AppColorsExtension(
    background: Color(0xFFF7F7F5),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE5E5E3),
    divider: Color(0xFFEEEEEC),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    textHint: Color(0xFF9E9E9E),
    primaryTint: Color(0xFFEAF3DE),
  );

  static const dark = AppColorsExtension(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    border: Color(0xFF333333),
    divider: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFE8E8E8),
    textSecondary: Color(0xFFAAAAAA),
    textHint: Color(0xFF757575),
    primaryTint: Color(0xFF2A3C1A), // Darker green tint
  );

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? primaryTint,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      primaryTint: primaryTint ?? this.primaryTint,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
      covariant ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
