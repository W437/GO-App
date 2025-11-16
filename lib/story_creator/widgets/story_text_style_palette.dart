import 'package:flutter/material.dart';

import '../models/story_text_style_preset.dart';

class StoryTextStylePalette extends StatelessWidget {
  const StoryTextStylePalette({
    super.key,
    required this.selectedPreset,
    required this.onPresetSelected,
  });

  final String? selectedPreset;
  final ValueChanged<StoryTextStylePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        itemCount: presetStyles.length,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final preset = presetStyles[index];
          final isActive = preset.name == selectedPreset;
          return GestureDetector(
            onTap: () => onPresetSelected(preset),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.black45,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive ? Colors.white : Colors.white24,
                ),
              ),
              child: Center(
                child: Text(
                  preset.displayName,
                  style: TextStyle(
                    fontFamily: preset.fontFamily,
                    fontWeight: preset.fontWeight,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
