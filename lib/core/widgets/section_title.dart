import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Judul seksi yang konsisten (gaya [AppTextStyles.title]).
class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.title);
  }
}
