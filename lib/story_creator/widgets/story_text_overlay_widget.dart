import 'package:flutter/material.dart';

import '../models/story_text_overlay.dart';

class StoryTextOverlayWidget extends StatelessWidget {
  const StoryTextOverlayWidget({
    super.key,
    required this.overlay,
    required this.isActive,
    required this.baseFontSize,
  });

  final StoryTextOverlay overlay;
  final bool isActive;
  final double baseFontSize;

  TextAlign get _textAlign {
    switch (overlay.alignment) {
      case StoryTextAlignment.left:
        return TextAlign.left;
      case StoryTextAlignment.center:
        return TextAlign.center;
      case StoryTextAlignment.right:
        return TextAlign.right;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = baseFontSize * overlay.scale;
    Widget content = Text(
      overlay.displayText,
      textAlign: _textAlign,
      style: TextStyle(
        color: overlay.color,
        fontSize: fontSize,
        height: 1.2,
        letterSpacing: 0.4,
        fontFamily: overlay.fontFamily,
        fontWeight: overlay.fontWeight,
      ),
    );

    if (overlay.backgroundMode == StoryBackgroundMode.pill) {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: overlay.backgroundColor ?? overlay.color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(32),
        ),
        child: content,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: overlay.backgroundMode == StoryBackgroundMode.none
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        border: isActive
            ? Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }
}
