import 'package:flutter/material.dart';
import 'package:godelivery_user/features/story/domain/models/story_overlay_model.dart';

class StoryOverlaysLayer extends StatelessWidget {
  const StoryOverlaysLayer({
    super.key,
    required this.overlays,
  });

  final List<StoryOverlayModel> overlays;

  @override
  Widget build(BuildContext context) {
    if (overlays.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = [...overlays]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthScale = constraints.maxWidth / 375;
        return Stack(
          children: sorted.map((overlay) {
            final alignment = Alignment(
              overlay.position.x * 2 - 1,
              overlay.position.y * 2 - 1,
            );
            return Positioned.fill(
              child: Align(
                alignment: alignment,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.9,
                  ),
                  child: _OverlayText(
                    overlay: overlay,
                    widthScale: widthScale,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _OverlayText extends StatelessWidget {
  const _OverlayText({
    required this.overlay,
    required this.widthScale,
  });

  final StoryOverlayModel overlay;
  final double widthScale;

  double get _fontSize {
    const base = 32.0;
    final scale = overlay.scale.clamp(0.5, 4.0);
    final normalizedWidth = widthScale.clamp(0.75, 1.5);
    return base * scale * normalizedWidth;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Text(
      overlay.displayText,
      textAlign: overlay.textAlign,
      style: TextStyle(
        color: overlay.color,
        fontSize: _fontSize,
        fontWeight: overlay.fontWeight,
        fontFamily: overlay.fontFamily,
        height: 1.2,
        letterSpacing: 0.5,
      ),
    );

    if (overlay.backgroundMode == StoryOverlayBackgroundMode.pill) {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: overlay.backgroundColor ?? overlay.color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(40),
        ),
        child: content,
      );
    }

    return content;
  }
}
