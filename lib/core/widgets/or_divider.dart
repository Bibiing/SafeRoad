import 'package:saferoad/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Pemisah teks dengan garis di kiri-kanan (mis. "atau masuk dengan").
class OrDivider extends StatelessWidget {
  final String label;

  const OrDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.appColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: AppTextStyles.caption),
        ),
        Expanded(child: Divider(color: context.appColors.border)),
      ],
    );
  }
}
