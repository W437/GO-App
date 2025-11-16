import 'package:flutter/material.dart';

class StoryOverlayPositionModel {
  const StoryOverlayPositionModel({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  factory StoryOverlayPositionModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const StoryOverlayPositionModel(x: 0.5, y: 0.5);
    }
    return StoryOverlayPositionModel(
      x: (json['x'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5,
      y: (json['y'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5,
    );
  }
}

enum StoryOverlayAlignment { left, center, right }

enum StoryOverlayBackgroundMode { none, pill }

enum StoryOverlayTextCase { normal, uppercase, lowercase }

class StoryOverlayModel {
  StoryOverlayModel({
    required this.id,
    required this.text,
    required this.position,
    required this.scale,
    required this.fontFamily,
    required this.fontWeight,
    required this.color,
    required this.backgroundColor,
    required this.backgroundMode,
    required this.alignment,
    required this.zIndex,
    required this.stylePreset,
    required this.textCase,
  });

  final String id;
  final String text;
  final StoryOverlayPositionModel position;
  final double scale;
  final String fontFamily;
  final FontWeight fontWeight;
  final Color color;
  final Color? backgroundColor;
  final StoryOverlayBackgroundMode backgroundMode;
  final StoryOverlayAlignment alignment;
  final int zIndex;
  final String? stylePreset;
  final StoryOverlayTextCase textCase;

  static StoryOverlayModel fromJson(Map<String, dynamic> json) {
    final backgroundMode = _parseBackgroundMode(json['backgroundMode'] as String?);
    return StoryOverlayModel(
      id: (json['id'] ?? UniqueKey().toString()).toString(),
      text: (json['text'] as String?) ?? '',
      position: StoryOverlayPositionModel.fromJson(json['position'] as Map<String, dynamic>?),
      scale: (json['scale'] as num?)?.toDouble().clamp(0.5, 4.0) ?? 1.0,
      fontFamily: (json['fontFamily'] as String?) ?? 'Roboto',
      fontWeight: _parseFontWeight(json['fontWeight']),
      color: _parseColor(json['color']) ?? Colors.white,
      backgroundColor: backgroundMode == StoryOverlayBackgroundMode.none
          ? null
          : _parseColor(json['backgroundColor']) ?? Colors.black.withValues(alpha: 0.4),
      backgroundMode: backgroundMode,
      alignment: _parseAlignment(json['alignment'] as String?),
      zIndex: json['zIndex'] is int
          ? json['zIndex'] as int
          : int.tryParse(json['zIndex']?.toString() ?? '') ?? 0,
      stylePreset: json['stylePreset'] as String?,
      textCase: _parseTextCase(json['textCase'] as String?),
    );
  }

  String get displayText {
    switch (textCase) {
      case StoryOverlayTextCase.uppercase:
        return text.toUpperCase();
      case StoryOverlayTextCase.lowercase:
        return text.toLowerCase();
      case StoryOverlayTextCase.normal:
        return text;
    }
  }

  TextAlign get textAlign {
    switch (alignment) {
      case StoryOverlayAlignment.left:
        return TextAlign.left;
      case StoryOverlayAlignment.center:
        return TextAlign.center;
      case StoryOverlayAlignment.right:
        return TextAlign.right;
    }
  }
}

StoryOverlayAlignment _parseAlignment(String? raw) {
  switch (raw) {
    case 'left':
      return StoryOverlayAlignment.left;
    case 'right':
      return StoryOverlayAlignment.right;
    case 'center':
    default:
      return StoryOverlayAlignment.center;
  }
}

StoryOverlayBackgroundMode _parseBackgroundMode(String? raw) {
  switch (raw) {
    case 'pill':
      return StoryOverlayBackgroundMode.pill;
    case 'none':
    default:
      return StoryOverlayBackgroundMode.none;
  }
}

StoryOverlayTextCase _parseTextCase(String? raw) {
  switch (raw) {
    case 'uppercase':
      return StoryOverlayTextCase.uppercase;
    case 'lowercase':
      return StoryOverlayTextCase.lowercase;
    case 'normal':
    default:
      return StoryOverlayTextCase.normal;
  }
}

FontWeight _parseFontWeight(dynamic raw) {
  if (raw is int) {
    switch (raw) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w600;
    }
  }
  return FontWeight.w600;
}

Color? _parseColor(dynamic raw) {
  if (raw is String) {
    var value = raw.trim();
    if (value.startsWith('#')) {
      value = value.substring(1);
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    final parsed = int.tryParse(value, radix: 16);
    if (parsed != null) {
      return Color(parsed);
    }
  }
  return null;
}
