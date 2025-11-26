/// Custom snackbar widget for displaying toast messages and notifications
/// Provides styled error and success messages with consistent appearance

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast.dart';
import 'package:godelivery_user/util/dimensions.dart';

// Global overlay entry manager
OverlayEntry? _currentToastEntry;
Timer? _dismissTimer;

// Keep reference to the current toast widget state for animation control
_NonBlockingToastOverlayState? _currentToastState;

Future<void> showCustomSnackBar(String? message, {bool isError = true}) async {
  if (message != null && message.isNotEmpty) {
    // Get the current context from navigator
    final context = Get.overlayContext ?? Get.context;
    if (context == null) {
      debugPrint('No context available for toast');
      return;
    }

    // Get the overlay before async operations
    final overlay = Overlay.of(context);

    // Remove any existing toast
    await _removeCurrentToast();

    // Create the overlay entry with truly non-blocking behavior
    final GlobalKey<_NonBlockingToastOverlayState> toastKey = GlobalKey();
    _currentToastEntry = OverlayEntry(
      builder: (context) => _NonBlockingToastOverlay(
        key: toastKey,
        message: message,
        isError: isError,
        onDismiss: _removeCurrentToast,
      ),
    );

    // Insert the overlay
    overlay.insert(_currentToastEntry!);

    // Wait a frame to ensure the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentToastState = toastKey.currentState;
    });

    // Set auto-dismiss timer with animation
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () async {
      await _removeCurrentToast();
    });
  }
}

Future<void> _removeCurrentToast() async {
  _dismissTimer?.cancel();
  _dismissTimer = null;

  // Animate out before removing
  if (_currentToastState != null) {
    await _currentToastState!.animateOut();
  }

  _currentToastEntry?.remove();
  _currentToastEntry = null;
  _currentToastState = null;
}

// Truly non-blocking toast overlay widget with Wolt-style drag-to-dismiss
class _NonBlockingToastOverlay extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _NonBlockingToastOverlay({
    super.key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_NonBlockingToastOverlay> createState() => _NonBlockingToastOverlayState();
}

class _NonBlockingToastOverlayState extends State<_NonBlockingToastOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _snapBackController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Drag state
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  double _manualOpacity = 1.0;
  static const double _dismissThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _snapBackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _snapBackController.dispose();
    super.dispose();
  }

  Future<void> animateOut({Offset? targetOffset}) async {
    if (targetOffset != null) {
      // Animate to the drag direction
      await _animationController.reverse();
    } else {
      await _animationController.reverse();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) {
      // Pause timer when drag starts
      _dismissTimer?.cancel();
    }

    setState(() {
      _isDragging = true;
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final distance = math.sqrt(_dragOffset.dx * _dragOffset.dx + _dragOffset.dy * _dragOffset.dy);

    if (distance > _dismissThreshold) {
      // Dismiss - animate off screen in drag direction
      // Calculate direction and extend it further off screen
      final direction = Offset(
        _dragOffset.dx / distance,
        _dragOffset.dy / distance,
      );
      final targetOffset = direction * 600.0; // Increased from 400

      setState(() {
        _isDragging = false;
      });

      // Create new animation controller for smooth dismiss
      final dismissController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      final Animation<Offset> dismissAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: targetOffset,
      ).animate(CurvedAnimation(
        parent: dismissController,
        curve: Curves.easeOutCubic,
      ));

      final Animation<double> fadeOutAnimation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: dismissController,
        curve: Curves.easeOut,
      ));

      dismissAnimation.addListener(() {
        if (mounted) {
          setState(() {
            _dragOffset = dismissAnimation.value;
            _manualOpacity = fadeOutAnimation.value;
          });
        }
      });

      dismissController.forward().then((_) {
        dismissController.dispose();
        widget.onDismiss();
      });
    } else {
      // Snap back to center using separate controller
      final Animation<Offset> snapAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _snapBackController,
        curve: Curves.easeOutBack,
      ));

      snapAnimation.addListener(() {
        if (mounted) {
          setState(() {
            _dragOffset = snapAnimation.value;
          });
        }
      });

      setState(() {
        _isDragging = false;
        _manualOpacity = 1.0;
      });

      _snapBackController.forward(from: 0.0);

      // Resume auto-dismiss timer after snap back completes
      _snapBackController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _restartDismissTimer();
        }
      });
    }
  }

  void _restartDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () async {
      if (_currentToastState == this) {
        await _removeCurrentToast();
      }
    });
  }

  double _calculateRotation() {
    // Rotation based on horizontal drag, max ±15 degrees
    const maxRotation = 15.0 * (math.pi / 180); // 15 degrees in radians
    const fullDragDistance = 200.0; // Distance for max rotation

    final normalized = (_dragOffset.dx / fullDragDistance).clamp(-1.0, 1.0);
    return normalized * maxRotation;
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _calculateRotation();

    return Positioned(
      bottom: 100, // Nav (65px) + gap (35px)
      left: Dimensions.paddingSizeSmall,
      right: Dimensions.paddingSizeSmall,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Opacity(
              opacity: _manualOpacity,
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.rotate(
                  angle: rotation,
                  child: Center(
                    child: CustomToast(
                      text: widget.message,
                      isError: widget.isError,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
