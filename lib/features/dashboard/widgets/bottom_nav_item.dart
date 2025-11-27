import 'package:flutter/material.dart';

class BottomNavItem extends StatefulWidget {
  final IconData? iconData;
  final String? iconPath;
  final String label;
  final Function(TapDownDetails)? onTap;
  final bool isSelected;
  const BottomNavItem({super.key, this.iconData, this.iconPath, required this.label, this.onTap, this.isSelected = false});

  @override
  State<BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<BottomNavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;
  TapDownDetails? _tapDownDetails;
  int? _activePointerId; // Track which pointer is pressing this button

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(BottomNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerId = event.pointer;
    setState(() {
      _isPressed = true;
      _tapDownDetails = TapDownDetails(
        globalPosition: event.position,
        localPosition: event.localPosition,
        kind: event.kind,
      );
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer == _activePointerId) {
      if (_isPressed && _tapDownDetails != null) {
        widget.onTap?.call(_tapDownDetails!);
      }
      _resetPressState();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _activePointerId) {
      _resetPressState();
    }
  }

  void _resetPressState() {
    setState(() {
      _isPressed = false;
      _tapDownDetails = null;
      _activePointerId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final hintColor = Theme.of(context).hintColor;

    // Determine icon color: pressed or selected = primary, otherwise hint
    final iconColor = (_isPressed || widget.isSelected)
        ? primaryColor
        : hintColor.withValues(alpha: 0.4);

    // Determine label color
    final labelColor = (_isPressed || widget.isSelected)
        ? primaryColor
        : hintColor.withValues(alpha: 0.45);

    return Expanded(
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final value = _controller.value;
                  // Create wiggle effect with rotation
                  double rotation = 0;
                  if (value < 0.25) {
                    rotation = value * 4 * 0.2; // 0 to 0.2
                  } else if (value < 0.5) {
                    rotation = 0.2 - (value - 0.25) * 4 * 0.4; // 0.2 to -0.2
                  } else if (value < 0.75) {
                    rotation = -0.2 + (value - 0.5) * 4 * 0.3; // -0.2 to 0.1
                  } else {
                    rotation = 0.1 - (value - 0.75) * 4 * 0.1; // 0.1 to 0
                  }

                  // Create scale effect for wiggle animation
                  double wiggleScale = 1.0;
                  if (value < 0.5) {
                    wiggleScale = 1.0 + (value * 2 * 0.2); // 1.0 to 1.2
                  } else {
                    wiggleScale = 1.2 - ((value - 0.5) * 2 * 0.2); // 1.2 to 1.0
                  }

                  // Press feedback scale (5% pop)
                  final pressScale = _isPressed ? 1.05 : 1.0;
                  final totalScale = wiggleScale * pressScale;

                  return Transform.scale(
                    scale: totalScale,
                    child: Transform.rotate(
                      angle: rotation,
                      child: widget.iconPath != null
                          ? ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                iconColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                widget.iconPath!,
                                width: 28.8,
                                height: 28.8,
                              ),
                            )
                          : Icon(
                              widget.iconData!,
                              color: iconColor,
                              size: 28.8,
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: (_isPressed || widget.isSelected) ? FontWeight.w600 : FontWeight.w500,
                    color: labelColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
