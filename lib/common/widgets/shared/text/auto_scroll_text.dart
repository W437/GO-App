import 'package:flutter/material.dart';

/// Auto-scrolling single-line text with fading edges when it overflows.
class AutoScrollText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const AutoScrollText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<AutoScrollText> {
  late final ScrollController _scrollController;
  bool _shouldScroll = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(AutoScrollText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      setState(() {
        _shouldScroll = false;
      });
      _resetScrolling();
    }
  }

  void _resetScrolling() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _isAnimating = false;
  }

  Future<void> _startScrolling() async {
    if (!mounted || !_shouldScroll || _isAnimating) return;
    _isAnimating = true;
    await Future.delayed(const Duration(milliseconds: 1000));

    while (mounted && _shouldScroll) {
      if (!_scrollController.hasClients) break;

      final duration = Duration(
        milliseconds: (widget.text.length * 60).clamp(3000, 8000),
      );

      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.linear,
        duration: duration,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted || !_shouldScroll) break;

      await _scrollController.animateTo(
        0,
        curve: Curves.linear,
        duration: duration,
      );

      await Future.delayed(const Duration(milliseconds: 800));
    }

    _isAnimating = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: direction,
        )..layout(maxWidth: double.infinity);

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final needsScroll = textPainter.size.width > availableWidth;

        if (needsScroll != _shouldScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_shouldScroll == needsScroll) return;
            setState(() {
              _shouldScroll = needsScroll;
            });
            if (_shouldScroll) {
              _startScrolling();
            } else {
              _resetScrolling();
            }
          });
        }

        if (!_shouldScroll) {
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return ClipRect(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.05, 0.95, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              width: availableWidth,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.text,
                    style: widget.style,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
