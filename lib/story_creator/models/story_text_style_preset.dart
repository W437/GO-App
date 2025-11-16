import 'package:flutter/material.dart';
import 'story_text_overlay.dart';

class StoryTextStylePreset {
  const StoryTextStylePreset({
    required this.name,
    required this.displayName,
    required this.fontFamily,
    this.fontWeight = FontWeight.w600,
    this.backgroundMode = StoryBackgroundMode.none,
    this.defaultTextCase = StoryTextCase.normal,
    this.defaultColor = Colors.white,
    this.backgroundColor,
  });

  final String name;
  final String displayName;
  final String fontFamily;
  final FontWeight fontWeight;
  final StoryBackgroundMode backgroundMode;
  final StoryTextCase defaultTextCase;
  final Color defaultColor;
  final Color? backgroundColor;
}

const presetStyles = <StoryTextStylePreset>[
  StoryTextStylePreset(
    name: 'meme',
    displayName: 'Meme',
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w900,
    backgroundMode: StoryBackgroundMode.pill,
    backgroundColor: Colors.black87,
  ),
  StoryTextStylePreset(
    name: 'elegant',
    displayName: 'Elegant',
    fontFamily: 'Omnes',
    fontWeight: FontWeight.w400,
  ),
  StoryTextStylePreset(
    name: 'directional',
    displayName: 'Directional',
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w700,
  ),
  StoryTextStylePreset(
    name: 'literature',
    displayName: 'Literature',
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    defaultTextCase: StoryTextCase.normal,
  ),
];
