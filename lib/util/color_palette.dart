import 'package:flutter/material.dart';

class ColorPalette {
  static const List<Map<String, dynamic>> profileColors = [
    {
      'name': 'Red',
      'shades': [
        Color(0xFFFF5252),
        Color(0xFFEF5350),
        Color(0xFFF44336),
      ],
    },
    {
      'name': 'Orange',
      'shades': [
        Color(0xFFFF9800),
        Color(0xFFFB8C00),
        Color(0xFFF57C00),
      ],
    },
    {
      'name': 'Green',
      'shades': [
        Color(0xFF4CAF50),
        Color(0xFF66BB6A),
        Color(0xFF43A047),
      ],
    },
    {
      'name': 'Blue',
      'shades': [
        Color(0xFF2196F3),
        Color(0xFF42A5F5),
        Color(0xFF1E88E5),
      ],
    },
    {
      'name': 'Purple',
      'shades': [
        Color(0xFF9C27B0),
        Color(0xFFAB47BC),
        Color(0xFF8E24AA),
      ],
    },
    {
      'name': 'Pink',
      'shades': [
        Color(0xFFE91E63),
        Color(0xFFEC407A),
        Color(0xFFD81B60),
      ],
    },
    {
      'name': 'Teal',
      'shades': [
        Color(0xFF009688),
        Color(0xFF26A69A),
        Color(0xFF00897B),
      ],
    },
    {
      'name': 'Indigo',
      'shades': [
        Color(0xFF3F51B5),
        Color(0xFF5C6BC0),
        Color(0xFF3949AB),
      ],
    },
  ];

  static const Color defaultBgColor = Colors.white; // White
  static const String defaultEmoji = '😊';

  // Convert Color to hex string
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // Convert hex string to Color
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
