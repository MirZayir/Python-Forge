import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Reusable section title header component.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headline.copyWith(color: Colors.white),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.micro),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.syntaxGrey,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Fixes the linter warning by using the null-coalescing operator
        // instead of an if-statement inside the collection.
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}
