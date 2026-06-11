import 'package:flutter/material.dart';
import 'package:polaris/app/theme/color_tokens.dart';

/// Opinionated scaffold used by all top-level pages.
///
/// Single Responsibility: provide consistent page chrome (safe area,
/// background, optional app bar slot) so feature screens only focus on
/// content. Build the [appBar] outside and pass it in to keep this widget
/// composition-friendly.
class PolarisScaffold extends StatelessWidget {
  const PolarisScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Spacing.x4,
      vertical: Spacing.x4,
    ),
    this.safeArea = true,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsets padding;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: body);
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: safeArea ? SafeArea(child: content) : content,
    );
  }
}
