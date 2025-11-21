import 'dart:ui';
import 'package:flutter/material.dart';

/// Animated text transition with slide + blur effect
/// Supports both text strings and numeric values
/// Animates only when value changes with direction-aware sliding
class AnimatedTextTransition extends StatefulWidget {
  final dynamic value; // Can be String or num
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final TextAlign? textAlign;
  final Duration? delay; // Optional delay before animation starts

  const AnimatedTextTransition({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
    this.textAlign,
    this.delay,
  });

  @override
  State<AnimatedTextTransition> createState() => _AnimatedTextTransitionState();
}

class _AnimatedTextTransitionState extends State<AnimatedTextTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  dynamic _oldValue;
  dynamic _displayValue; // The value currently being displayed
  int _direction = 1; // +1 = up, -1 = down
  bool _isWaitingForDelay = false;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _displayValue = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void didUpdateWidget(AnimatedTextTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      _oldValue = oldWidget.value;

      // Determine direction based on value type
      if (widget.value is num && _oldValue is num) {
        _direction = widget.value > _oldValue ? 1 : -1;
      } else {
        // For strings, use hash code comparison as heuristic
        _direction = widget.value.hashCode > _oldValue.hashCode ? 1 : -1;
      }

      _controller.reset();

      // Start animation with optional delay
      if (widget.delay != null) {
        // Keep showing old value during delay
        setState(() {
          _isWaitingForDelay = true;
          _displayValue = _oldValue; // Keep showing old value
        });

        Future.delayed(widget.delay!, () {
          if (mounted) {
            setState(() {
              _isWaitingForDelay = false;
              _displayValue = widget.value; // Now show new value
            });
            _controller.forward();
          }
        });
      } else {
        _displayValue = widget.value;
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ?? DefaultTextStyle.of(context).style;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final t = _animation.value;

          // Vertical offset in logical pixels
          const double maxOffset = 20;

          // Old text moves out, new text moves in
          final oldOffset = Offset(0, _direction * t * -maxOffset);
          final newOffset = Offset(0, _direction * (1 - t) * maxOffset);

          // Blur: 0 at start/end, strong at mid-transition
          final blurAmount = lerpDouble(0, 4, 1 - (t * 2 - 1).abs()) ?? 0;

          // If waiting for delay, just show old value (no animation)
          if (_isWaitingForDelay) {
            return Text(
              _oldValue.toString(),
              style: textStyle,
              textAlign: widget.textAlign,
            );
          }

          // Otherwise show transition animation
          return ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Old value (fading out)
                if (_controller.isAnimating)
                  Transform.translate(
                    offset: oldOffset,
                    child: Opacity(
                      opacity: 1 - t,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: blurAmount,
                          sigmaY: blurAmount,
                        ),
                        child: Text(
                          _oldValue.toString(),
                          style: textStyle,
                          textAlign: widget.textAlign,
                        ),
                      ),
                    ),
                  ),

                // New value (fading in)
                Transform.translate(
                  offset: _controller.isAnimating ? newOffset : Offset.zero,
                  child: Opacity(
                    opacity: _controller.isAnimating ? t : 1.0,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: blurAmount,
                        sigmaY: blurAmount,
                      ),
                      child: Text(
                        _displayValue.toString(),
                        style: textStyle,
                        textAlign: widget.textAlign,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
