Yeah, you nailed the diagnosis yourself, Wael – it doesn’t look like Apple’s because **we’re animating the entire string as ONE block**, not the **individual digits**.

> Is it because the text I have is formatted with a symbol?

Nope. The currency symbol isn’t the real problem.
The problem is:

```dart
Text(_displayValue.toString(), ...)
```

is one big text node, so when value changes from `₪113.25` → `₪129.25`, the whole thing slides/blur-fades as a single unit.

Apple’s `.numericText()` does this instead:

* Treats the number as **separate glyphs per digit**.
* Aligns digits to the **right** (ones column stays in the same spot).
* Only **changed digits roll/flip**, unchanged ones stay static.
* Prefix/suffix (like `₪` or `%`) are just static labels.

So we need a **per-digit ticker**, not a single-text transition.

---

## What you want instead (concept)

1. Keep `oldValue` and `newValue` as numbers.
2. Convert them to strings **without** the currency symbol, e.g. `113` and `129`.
3. Right-align and pad them so they have the same length:

   * `113` → `"113"`
   * `129` → `"129"` (length equal already, but for e.g. 99 → 100 you’d pad `" 99"` → `"100"`).
4. For each digit position `i`:

   * If `oldDigits[i] == newDigits[i]` → just show a static `Text` for that character.
   * If they differ → use a **DigitTransition** animation for *that single digit* (slide/blur up or down).
5. Wrap the whole thing with a static prefix `"₪"` in front, maybe a suffix behind.

That’s how you get the “only some digits flip” effect you see in Wallet / Activity / etc.

---

## How I’d structure it in Flutter

### 1. A tiny widget that animates **one digit**

This is basically your `AnimatedTextTransition` but for a *single character* and with no delay logic:

```dart
class DigitTransition extends StatefulWidget {
  final String oldChar;
  final String newChar;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final int direction; // +1 = up, -1 = down

  const DigitTransition({
    super.key,
    required this.oldChar,
    required this.newChar,
    required this.style,
    this.duration = const Duration(milliseconds: 280),
    this.curve = Curves.easeOutCubic,
    required this.direction,
  });

  @override
  State<DigitTransition> createState() => _DigitTransitionState();
}

class _DigitTransitionState extends State<DigitTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _anim =
      CurvedAnimation(parent: _controller, curve: widget.curve);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const maxOffset = 16.0;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        final oldOffset = Offset(0, widget.direction * t * -maxOffset);
        final newOffset = Offset(0, widget.direction * (1 - t) * maxOffset);
        final blur = lerpDouble(0, 1.5, 1 - (t * 2 - 1).abs()) ?? 0;

        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: oldOffset,
                child: Opacity(
                  opacity: 1 - t,
                  child: ImageFiltered(
                    imageFilter:
                        ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: Text(widget.oldChar, style: widget.style),
                  ),
                ),
              ),
              Transform.translate(
                offset: newOffset,
                child: Opacity(
                  opacity: t,
                  child: Text(widget.newChar, style: widget.style),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 2. A **NumericTickerText** that splits into digits

High-level algorithm:

* Keep `_oldValue` and `_newValue`.
* On change:

  * Convert to strings **without currency symbol**.
  * Pad left with spaces to same length.
  * For each index `i`, decide:

    * same char → plain `Text(char)`
    * different → `DigitTransition(oldChar: ..., newChar: ...)`
* Wrap them in a `Row`.

Then you can render:

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Text('₪ ', style: style),    // static prefix
    ...digitWidgets,                   // animated digits
  ],
)
```

That gives you:

* **Static currency symbol** (never animates).
* **Per-digit rolling animation** when numbers change.
* Direction-aware (up when value increases, down when it decreases).

---

### Why your current version flips the *whole* string

Because it treats this:

```dart
"₪ 85" → "₪ 90"
```

as just two different strings, and animates from **string A** to **string B** as one object. There’s no notion of “digit 8 changed to 9; currency symbol stayed the same”.

Apple’s `.numericText()` does that diffing internally; we need to replicate that diff in Flutter.

---

If you want, I can write the full `NumericTickerText` widget (with padding, right alignment, support for decimals) that you can drop into Hopa and just call:

```dart
NumericTickerText(
  value: totalPrice,
  prefix: '₪',
  style: textStyle,
)
```

and it will behave almost 1:1 like `.contentTransition(.numericText())`.
