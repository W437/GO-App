import 'package:flutter/material.dart';

import '../models/story_text_overlay.dart';

class StoryTextToolbar extends StatelessWidget {
  const StoryTextToolbar({
    super.key,
    required this.alignment,
    required this.onAlignmentChanged,
    required this.onToggleCase,
    required this.onToggleBackground,
    required this.onToggleColorPalette,
    required this.onDelete,
  });

  final StoryTextAlignment alignment;
  final ValueChanged<StoryTextAlignment> onAlignmentChanged;
  final VoidCallback onToggleCase;
  final VoidCallback onToggleBackground;
  final VoidCallback onToggleColorPalette;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 48,
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.text_fields,
            onPressed: onToggleCase,
          ),
          _ToolbarButton(
            icon: Icons.palette_outlined,
            onPressed: onToggleColorPalette,
          ),
          const SizedBox(width: 4),
          ToggleButtons(
            color: Colors.white70,
            selectedColor: Colors.white,
            fillColor: Colors.white24,
            borderRadius: BorderRadius.circular(12),
            isSelected: [
              alignment == StoryTextAlignment.left,
              alignment == StoryTextAlignment.center,
              alignment == StoryTextAlignment.right,
            ],
            onPressed: (index) {
              switch (index) {
                case 0:
                  onAlignmentChanged(StoryTextAlignment.left);
                  break;
                case 1:
                  onAlignmentChanged(StoryTextAlignment.center);
                  break;
                case 2:
                  onAlignmentChanged(StoryTextAlignment.right);
                  break;
              }
            },
            children: const [
              Icon(Icons.format_align_left),
              Icon(Icons.format_align_center),
              Icon(Icons.format_align_right),
            ],
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.crop_3_2_outlined,
            onPressed: onToggleBackground,
          ),
          const Spacer(),
          _ToolbarButton(
            icon: Icons.delete_outline,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
