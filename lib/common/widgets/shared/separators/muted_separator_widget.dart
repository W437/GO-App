/// Reusable muted separator line widget
/// Provides a subtle horizontal divider for visual separation

import 'package:flutter/material.dart';

class MutedSeparatorWidget extends StatelessWidget {
  final double height;
  final double opacity;
  final EdgeInsets? margin;

  const MutedSeparatorWidget({
    super.key,
    this.height = 1.0,
    this.opacity = 0.1,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      color: Theme.of(context).dividerColor.withValues(alpha: opacity),
    );
  }
}
