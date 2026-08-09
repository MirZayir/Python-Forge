import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Standard Scaffold wrapper for Python Forge screens.
///
/// The background is cream to match the neubrutalist screens. Padding defaults
/// to zero so scrollable content can own its own insets instead of being boxed
/// inside a contrasting frame.
class ForgeScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;

  const ForgeScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding,
    this.backgroundColor = AppColors.bgCream,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: body,
        ),
      ),
    );
  }
}
