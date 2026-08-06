import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Card component matching the Crucible Grey design tokens.
class ForgeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const ForgeCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor != null
        ? Border.all(color: borderColor!, width: 1.0)
        : null;

    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.crucibleGrey,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }

    return cardContent;
  }
}
