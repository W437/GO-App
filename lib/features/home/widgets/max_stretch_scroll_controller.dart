import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Scroll controller that limits overscroll/stretch to a fixed value so the
/// custom refresh indicator stays aligned with the content.
class MaxStretchScrollController extends ScrollController {
  final double maxStretchExtent;

  MaxStretchScrollController({
    required this.maxStretchExtent,
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
  }) : super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _MaxStretchScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      maxStretchExtent: maxStretchExtent,
    );
  }
}

class _MaxStretchScrollPosition extends ScrollPositionWithSingleContext {
  final double maxStretchExtent;

  _MaxStretchScrollPosition({
    required this.maxStretchExtent,
    required super.physics,
    required super.context,
    super.oldPosition,
  });

  @override
  double applyBoundaryConditions(double value) {
    final double minAllowed = minScrollExtent - maxStretchExtent;
    final double maxAllowed = maxScrollExtent + maxStretchExtent;

    if (value < minAllowed) {
      return value - minAllowed;
    }

    if (value > maxAllowed) {
      return value - maxAllowed;
    }

    return super.applyBoundaryConditions(value);
  }

  @override
  void applyUserOffset(double delta) {
    final double minAllowed = minScrollExtent - maxStretchExtent;
    final double maxAllowed = maxScrollExtent + maxStretchExtent;

    double adjustedDelta = delta;
    final double proposedPixels = pixels - delta;

    if (proposedPixels < minAllowed) {
      adjustedDelta = pixels - minAllowed;
    } else if (proposedPixels > maxAllowed) {
      adjustedDelta = pixels - maxAllowed;
    }

    if (adjustedDelta == 0) {
      updateUserScrollDirection(ScrollDirection.idle);
      return;
    }

    updateUserScrollDirection(adjustedDelta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);

    final bool overscrollingTop = (pixels <= minScrollExtent && adjustedDelta > 0) || pixels < minScrollExtent;
    final bool overscrollingBottom = (pixels >= maxScrollExtent && adjustedDelta < 0) || pixels > maxScrollExtent;

    if (overscrollingTop || overscrollingBottom) {
      setPixels(pixels - adjustedDelta);
      return;
    }

    final double physicsDelta = physics.applyPhysicsToUserOffset(this, adjustedDelta);
    if (physicsDelta == 0.0) {
      return;
    }
    setPixels(pixels - physicsDelta);
  }
}
