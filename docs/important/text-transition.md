Yesss, that effect is so satisfying 😅
Short answer: **Flutter doesn’t have a built-in `.numericText()`**, but we can get *very* close with a small custom widget.

Below is a **drop-in Flutter widget** that behaves like `contentTransition(.numericText())`:

* Animates **only when the number changes**
* **Slides** digits up/down like a counter
* Adds a **soft blur** during the motion
* Direction-aware: if value increases → slides up; decreases → slides down
* Optimized with `RepaintBoundary` so it stays smooth

---

## 1. Core idea

1. Keep **previous value** and **current value** in state.
2. When `value` changes:

   * start an `AnimationController`
   * show **two texts** stacked (old + new)
   * animate:

     * old → moves out + fades + blur
     * new → moves in + fades in + blur→sharp
3. Use `AnimatedBuilder` + `ImageFiltered.blur` for the blur.

---

## 2. Drop-in widget: `NumericTextTransition`

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

class NumericTextTransition extends StatefulWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const NumericTextTransition({
    Key? key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  State<NumericTextTransition> createState() => _NumericTextTransitionState();
}

class _NumericTextTransitionState extends State<NumericTextTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  num _oldValue = 0;
  int _direction = 1; // +1 = up, -1 = down

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void didUpdateWidget(NumericTextTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      _oldValue = oldWidget.value;
      _direction = widget.value > oldWidget.value ? 1 : -1;

      _controller
        ..reset()
        ..forward();
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

          // vertical offset in logical pixels
          const double maxOffset = 20;

          // old text moves out
          final oldOffset = Offset(0, _direction * t * -maxOffset);
          final newOffset = Offset(0, _direction * (1 - t) * maxOffset);

          // blur: strong at mid-transition, 0 at start/end
          final blurAmount = lerpDouble(0, 4, (t * 2 - 1).abs()) ?? 0;

          return ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // old value
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
                        ),
                      ),
                    ),
                  ),

                // new value
                Transform.translate(
                  offset: _controller.isAnimating ? newOffset : Offset.zero,
                  child: Opacity(
                    opacity: t,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: blurAmount,
                        sigmaY: blurAmount,
                      ),
                      child: Text(
                        widget.value.toString(),
                        style: textStyle,
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
```

---

## 3. Use it like SwiftUI’s `.numericText()`

```dart
int rating = 5;

NumericTextTransition(
  value: rating,
  style: const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  ),
)
```

Whenever you `setState` with a new `rating`, the text will:

* slide **up** with blur if the number increased
* slide **down** with blur if it decreased
* feel very close to `.contentTransition(.numericText())`.

---

## 4. Tweaks to get it *perfectly* Hopa-style

* Increase `maxOffset` for more dramatic roll.
* Change `duration` to ~250ms for snappier feel.
* Replace `Curves.easeOutCubic` with `Curves.easeOutBack` for a tiny overshoot.
* If you want **per-digit** animation (like 123 → 129 animating only last digit), we can extend this to work per character.

If you want, I can do a **per-digit version** where only changed digits roll (e.g., 109 → 110 rolls just the last digit) to get even closer to Apple’s magic.
