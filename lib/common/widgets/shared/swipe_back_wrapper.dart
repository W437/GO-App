import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A wrapper widget that detects left edge swipes and triggers back navigation.
/// Use this for screens with custom transitions that don't support interactive gestures.
class SwipeBackWrapper extends StatefulWidget {
  final Widget child;
  final double edgeWidth;
  final double swipeThreshold;

  const SwipeBackWrapper({
    super.key,
    required this.child,
    this.edgeWidth = 40.0, // Width of the edge detection zone
    this.swipeThreshold = 50.0, // Minimum horizontal distance to trigger back
  });

  @override
  State<SwipeBackWrapper> createState() => _SwipeBackWrapperState();
}

class _SwipeBackWrapperState extends State<SwipeBackWrapper> {
  double _startX = 0;
  bool _isEdgeSwipe = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        // Check if the drag started from the left edge
        if (details.localPosition.dx <= widget.edgeWidth) {
          _startX = details.localPosition.dx;
          _isEdgeSwipe = true;
        } else {
          _isEdgeSwipe = false;
        }
      },
      onHorizontalDragUpdate: (details) {
        // Optional: could add visual feedback here
      },
      onHorizontalDragEnd: (details) {
        if (_isEdgeSwipe) {
          final velocity = details.primaryVelocity ?? 0;
          // Trigger back if swiped right with enough velocity or distance
          if (velocity > 300) {
            Get.back();
          }
        }
        _isEdgeSwipe = false;
      },
      child: widget.child,
    );
  }
}
