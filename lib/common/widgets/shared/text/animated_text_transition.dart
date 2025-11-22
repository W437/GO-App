import 'dart:ui';
import 'package:flutter/material.dart';

/// Animated text transition with automatic strategy selection
/// - Numeric values: Per-digit animation (Apple .numericText() style)
/// - Text strings: Whole-string slide + blur animation
/// Supports optional delay before animation starts
class AnimatedTextTransition extends StatefulWidget {
  final dynamic value; // Can be String or num
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final TextAlign? textAlign;
  final Duration? delay;

  const AnimatedTextTransition({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutBack,
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
  dynamic _displayValue;
  int _direction = 1;
  bool _isWaitingForDelay = false;

  // Per-digit animation state
  bool _usePerDigit = false;
  String _prefix = '';
  String _suffix = '';
  List<_DigitSlot> _digitSlots = [];

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

      // Convert to strings
      final oldText = oldWidget.value.toString();
      final newText = widget.value.toString();

      // Try to parse as numeric for per-digit animation
      final diff = _buildDiff(oldText, newText);
      _usePerDigit = diff.usePerDigit;
      _prefix = diff.prefix;
      _suffix = diff.suffix;
      _digitSlots = diff.digitSlots;

      // Determine direction
      if (widget.value is num && _oldValue is num) {
        _direction = widget.value > _oldValue ? 1 : -1;
      } else {
        _direction = widget.value.hashCode > _oldValue.hashCode ? 1 : -1;
      }

      _controller.reset();

      // Start animation with optional delay
      if (widget.delay != null) {
        setState(() {
          _isWaitingForDelay = true;
          _displayValue = _oldValue;
        });

        Future.delayed(widget.delay!, () {
          if (mounted) {
            // Start animation immediately, then update state
            _controller.forward();
            setState(() {
              _isWaitingForDelay = false;
              _displayValue = widget.value;
            });
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

    // If waiting for delay, show old value
    if (_isWaitingForDelay) {
      return Text(
        _oldValue.toString(),
        style: textStyle,
        textAlign: widget.textAlign,
      );
    }

    // Choose animation strategy
    if (_usePerDigit && _controller.isAnimating) {
      return _buildPerDigitAnimation(textStyle);
    } else if (_usePerDigit) {
      // Per-digit mode but not animating - show current value
      return _buildStaticPerDigit(textStyle);
    } else {
      return _buildWholeStringAnimation(textStyle);
    }
  }

  // Apple-style per-digit animation
  Widget _buildPerDigitAnimation(TextStyle textStyle) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (_prefix.isNotEmpty) Text(_prefix, style: textStyle),
        ..._digitSlots.map((slot) {
          if (!slot.changed) {
            // Static digit (unchanged)
            return Text(slot.newChar, style: textStyle);
          } else {
            // Animated digit
            return _DigitTransition(
              oldChar: slot.oldChar,
              newChar: slot.newChar,
              style: textStyle,
              direction: _direction,
              animation: _animation,
            );
          }
        }),
        if (_suffix.isNotEmpty) Text(_suffix, style: textStyle),
      ],
    );

    // Center the row if textAlign is center
    return RepaintBoundary(
      child: widget.textAlign == TextAlign.center
        ? Center(child: row)
        : row,
    );
  }

  // Static display for per-digit mode (no animation)
  Widget _buildStaticPerDigit(TextStyle textStyle) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_prefix.isNotEmpty) Text(_prefix, style: textStyle),
        Text(_extractNumericPart(_displayValue.toString()), style: textStyle),
        if (_suffix.isNotEmpty) Text(_suffix, style: textStyle),
      ],
    );

    return widget.textAlign == TextAlign.center ? Center(child: row) : row;
  }

  // Whole-string animation (fallback for non-numeric)
  Widget _buildWholeStringAnimation(TextStyle textStyle) {
    final t = _animation.value;
    const double maxOffset = 20;
    final oldOffset = Offset(0, _direction * t * -maxOffset);
    final newOffset = Offset(0, _direction * (1 - t) * maxOffset);
    final blurAmount = lerpDouble(0, 4, 1 - (t * 2 - 1).abs()) ?? 0;

    // Determine stack alignment based on textAlign
    final Alignment stackAlignment;
    switch (widget.textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        stackAlignment = Alignment.centerLeft;
        break;
      case TextAlign.right:
      case TextAlign.end:
        stackAlignment = Alignment.centerRight;
        break;
      case TextAlign.center:
      default:
        stackAlignment = Alignment.center;
        break;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ClipRect(
            child: Stack(
              alignment: stackAlignment,
              children: [
                if (_controller.isAnimating)
                  Transform.translate(
                    offset: oldOffset,
                    child: Opacity(
                      opacity: 1 - t,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                        child: Text(_oldValue.toString(), style: textStyle, textAlign: widget.textAlign),
                      ),
                    ),
                  ),
                Transform.translate(
                  offset: _controller.isAnimating ? newOffset : Offset.zero,
                  child: Opacity(
                    opacity: _controller.isAnimating ? t : 1.0,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                      child: Text(_displayValue.toString(), style: textStyle, textAlign: widget.textAlign),
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

  // Parse text to extract numeric part, prefix, suffix
  _DiffResult _buildDiff(String oldText, String newText) {
    // Regex to match numbers with commas and decimals (e.g., "1,165.56")
    final regex = RegExp(r'([0-9,]+(?:\.[0-9]+)?)');
    final oldMatch = regex.firstMatch(oldText);
    final newMatch = regex.firstMatch(newText);

    if (oldMatch == null || newMatch == null) {
      return _DiffResult(usePerDigit: false);
    }

    final oldPrefix = oldText.substring(0, oldMatch.start);
    final newPrefix = newText.substring(0, newMatch.start);
    String oldNum = oldMatch.group(0)!;
    String newNum = newMatch.group(0)!;
    final oldSuffix = oldText.substring(oldMatch.end);
    final newSuffix = newText.substring(newMatch.end);

    if (oldPrefix != newPrefix || oldSuffix != newSuffix) {
      return _DiffResult(usePerDigit: false);
    }

    // If digit count difference is too large (more than 3 digits), fall back to whole-string
    // This prevents bad alignment when going from single digits to thousands
    final oldDigitCount = oldNum.replaceAll(RegExp(r'[,.]'), '').length;
    final newDigitCount = newNum.replaceAll(RegExp(r'[,.]'), '').length;

    print('🔢 [TEXT TRANSITION] Old: "$oldText" → New: "$newText"');
    print('   Old digits: $oldDigitCount, New digits: $newDigitCount, Diff: ${(oldDigitCount - newDigitCount).abs()}');

    if ((oldDigitCount - newDigitCount).abs() > 5) {
      print('   → Using WHOLE-STRING mode (digit diff too large)');
      return _DiffResult(usePerDigit: false);
    }

    print('   → Using PER-DIGIT mode');

    // Normalize: keep commas and decimals for character-by-character comparison
    // Pad to same length
    final maxLen = oldNum.length > newNum.length ? oldNum.length : newNum.length;
    final o = oldNum.padLeft(maxLen);
    final n = newNum.padLeft(maxLen);

    final digitSlots = <_DigitSlot>[];
    for (var i = 0; i < maxLen; i++) {
      digitSlots.add(_DigitSlot(
        oldChar: o[i],
        newChar: n[i],
        changed: o[i] != n[i],
      ));
    }

    return _DiffResult(
      usePerDigit: true,
      prefix: oldPrefix,
      suffix: oldSuffix,
      digitSlots: digitSlots,
    );
  }

  String _extractNumericPart(String value) {
    return value.replaceAll(RegExp(r'[^\d.,]'), '');
  }
}

// Internal digit transition widget
class _DigitTransition extends StatelessWidget {
  final String oldChar;
  final String newChar;
  final TextStyle style;
  final int direction;
  final Animation<double> animation;

  const _DigitTransition({
    required this.oldChar,
    required this.newChar,
    required this.style,
    required this.direction,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    const maxOffset = 16.0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        final oldOffset = Offset(0, direction * t * -maxOffset);
        final newOffset = Offset(0, direction * (1 - t) * maxOffset);
        final blur = lerpDouble(0, 1.5, 1 - (t * 2 - 1).abs()) ?? 0;

        return ClipRect(
          child: SizedBox(
            width: _measureTextWidth(newChar, style),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: oldOffset,
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: Text(oldChar, style: style),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: newOffset,
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: Text(newChar, style: style),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _measureTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }
}

// Helper classes for digit diffing
class _DigitSlot {
  final String oldChar;
  final String newChar;
  final bool changed;

  _DigitSlot({
    required this.oldChar,
    required this.newChar,
    required this.changed,
  });
}

class _DiffResult {
  final bool usePerDigit;
  final String prefix;
  final String suffix;
  final List<_DigitSlot> digitSlots;

  _DiffResult({
    required this.usePerDigit,
    this.prefix = '',
    this.suffix = '',
    this.digitSlots = const [],
  });
}
