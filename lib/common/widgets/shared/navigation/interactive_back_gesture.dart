import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget that enables interactive back navigation via swipe gesture
/// Detects horizontal swipes from 50px-200px from left edge (avoiding Android system gesture)
class InteractiveBackGesture extends StatefulWidget {
  final Widget child;

  const InteractiveBackGesture({
    super.key,
    required this.child,
  });

  @override
  State<InteractiveBackGesture> createState() => _InteractiveBackGestureState();
}

class _InteractiveBackGestureState extends State<InteractiveBackGesture> {
  double _dragProgress = 0.0;
  bool _isDragging = false;

  void _handleDragStart(DragStartDetails details) {
    // Only start if swipe begins in the left 200px zone (but not in system edge 0-50px)
    if (details.globalPosition.dx > 50 && details.globalPosition.dx < 200) {
      setState(() {
        _isDragging = true;
        _dragProgress = 0.0;
      });
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      // Calculate progress based on horizontal drag (0 to 1)
      final screenWidth = MediaQuery.of(context).size.width;
      _dragProgress = (details.globalPosition.dx / screenWidth).clamp(0.0, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
    });

    // Threshold: if dragged more than 30% of screen width, go back
    if (_dragProgress > 0.3) {
      Get.back();
    } else {
      // Reset
      setState(() {
        _dragProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
