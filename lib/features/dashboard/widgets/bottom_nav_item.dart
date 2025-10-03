import 'package:flutter/material.dart';

class BottomNavItem extends StatefulWidget {
  final IconData iconData;
  final String label;
  final Function? onTap;
  final bool isSelected;
  const BottomNavItem({super.key, required this.iconData, required this.label, this.onTap, this.isSelected = false});

  @override
  State<BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<BottomNavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.onTap?.call();
        },
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

                  // Create scale effect
                  double scale = 1.0;
                  if (value < 0.5) {
                    scale = 1.0 + (value * 2 * 0.2); // 1.0 to 1.2
                  } else {
                    scale = 1.2 - ((value - 0.5) * 2 * 0.2); // 1.2 to 1.0
                  }

                  return Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Icon(
                        widget.iconData,
                        color: widget.isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        size: 24,
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
                    color: widget.isSelected ? Theme.of(context).primaryColor : Colors.grey,
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
