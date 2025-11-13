/// Custom snackbar widget for displaying toast messages and notifications
/// Provides styled error and success messages with consistent appearance

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/custom_toast.dart';

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

// Truly non-blocking toast overlay widget
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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
      begin: const Offset(0, -0.5),
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
    super.dispose();
  }

  Future<void> animateOut() async {
    await _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Position the toast at the top center without blocking anything
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 0,
      right: 0,
      child: IgnorePointer(
        // Toast is not interactive - just a notification
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: CustomToast(
                text: widget.message,
                isError: widget.isError,
              ),
            ),
          ),
        ),
      ),
    );
  }
}