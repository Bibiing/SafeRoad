import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kartu standar SafeRoad — membungkus [Card] (radius & border dari
/// `cardTheme`) dengan padding default dan dukungan ketukan (InkWell).
///
/// Menyeragamkan pola `Card > InkWell > Padding` yang berulang di banyak
/// layar (audit masalah #2 & #11).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return Card(
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: content,
            ),
    );
  }
}
