import 'package:flutter/material.dart';

class StoryColorPalette extends StatelessWidget {
  const StoryColorPalette({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  static const _colors = [
    Colors.white,
    Colors.black,
    Color(0xFFFF3B30),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF00C853),
    Color(0xFF34C759),
    Color(0xFF0A84FF),
    Color(0xFF5856D6),
    Color(0xFFFF2D55),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final color = _colors[index];
          final isActive = color == selectedColor;
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Colors.white : Colors.white30,
                  width: isActive ? 3 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
