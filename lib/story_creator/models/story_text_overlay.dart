import 'dart:convert';
import 'package:flutter/material.dart';

class StoryOverlayPosition {
  StoryOverlayPosition({
    required this.x,
    required this.y,
  });

  double x;
  double y;

  StoryOverlayPosition copyWith({double? x, double? y}) {
    return StoryOverlayPosition(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

enum StoryTextAlignment { left, center, right }

enum StoryBackgroundMode { none, pill }

enum StoryTextCase { normal, uppercase, lowercase }

class StoryTextOverlay {
  StoryTextOverlay({
    required this.id,
    required this.text,
    required this.position,
    required this.scale,
    this.rotation = 0,
    this.fontFamily = 'Roboto',
    this.fontWeight = FontWeight.w600,
    this.stylePreset,
    this.color = Colors.white,
    this.backgroundColor,
    this.backgroundMode = StoryBackgroundMode.none,
    this.alignment = StoryTextAlignment.center,
    this.zIndex = 0,
    this.textCase = StoryTextCase.normal,
  });

  final String id;
  String text;
  StoryOverlayPosition position;
  double scale;
  double rotation;
  String fontFamily;
  FontWeight fontWeight;
  String? stylePreset;
  Color color;
  Color? backgroundColor;
  StoryBackgroundMode backgroundMode;
  StoryTextAlignment alignment;
  int zIndex;
  StoryTextCase textCase;

  String get displayText {
    switch (textCase) {
      case StoryTextCase.uppercase:
        return text.toUpperCase();
      case StoryTextCase.lowercase:
        return text.toLowerCase();
      case StoryTextCase.normal:
        return text;
    }
  }

  StoryTextOverlay copyWith({
    String? text,
    StoryOverlayPosition? position,
    double? scale,
    double? rotation,
    String? fontFamily,
    FontWeight? fontWeight,
    String? stylePreset,
    Color? color,
    Color? backgroundColor,
    StoryBackgroundMode? backgroundMode,
    StoryTextAlignment? alignment,
    int? zIndex,
    StoryTextCase? textCase,
  }) {
    final nextBackgroundMode = backgroundMode ?? this.backgroundMode;
    return StoryTextOverlay(
      id: id,
      text: text ?? this.text,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      stylePreset: stylePreset ?? this.stylePreset,
      color: color ?? this.color,
      backgroundColor: nextBackgroundMode == StoryBackgroundMode.none
          ? null
          : backgroundColor ?? this.backgroundColor,
      backgroundMode: nextBackgroundMode,
      alignment: alignment ?? this.alignment,
      zIndex: zIndex ?? this.zIndex,
      textCase: textCase ?? this.textCase,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'position': position.toJson(),
      'scale': scale,
      'rotation': rotation,
      'fontFamily': fontFamily,
      'fontWeight': fontWeight.value,
      'stylePreset': stylePreset,
      'color': _colorToHex(color),
      'backgroundColor': backgroundColor == null ? null : _colorToHex(backgroundColor!),
      'backgroundMode': backgroundMode.name,
      'alignment': alignment.name,
      'zIndex': zIndex,
      'textCase': textCase.name,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

String _colorToHex(Color color) {
  final a = _componentToHex(color.a);
  final r = _componentToHex(color.r);
  final g = _componentToHex(color.g);
  final b = _componentToHex(color.b);
  return '#$a$r$g$b';
}

String _componentToHex(double value) {
  final component = (value * 255.0).round();
  final safeComponent = component.clamp(0, 255).toInt();
  return safeComponent.toRadixString(16).padLeft(2, '0');
}
