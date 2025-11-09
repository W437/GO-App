import 'package:godelivery_user/util/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

ThemeData dark({String? languageCode}) => ThemeData(
  fontFamily: AppConstants.getFontFamily(languageCode ?? Get.locale?.languageCode ?? 'en'),
  primaryColor: const Color(0xFF9463ac),
  secondaryHeaderColor: const Color(0x9B9463ac),
  disabledColor: const Color(0xffa2a7ad),
  brightness: Brightness.dark,
  hintColor: const Color(0xFF5E6472),
  cardColor: const Color(0xFF1f1f1f),
  shadowColor: Colors.white.withValues(alpha: 0.03),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFF9463ac))),
  colorScheme: const ColorScheme.dark(primary: Color(0xFF9463ac),
    tertiary: Color(0xFF7d4f92),
    tertiaryContainer: Color(0xFF7d4f92),
    secondary: Color(0x9B9463ac)).copyWith(surface: const Color(0xFF1a1a1a)).copyWith(error: const Color(0xFFdd3135),
  ),
  popupMenuTheme: const PopupMenuThemeData(color: Color(0xFF242424), surfaceTintColor: Color(0xFF242424)),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white10),
  floatingActionButtonTheme: FloatingActionButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: Color(0xFF1a1a1a), height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),
  dividerTheme: DividerThemeData(color: const Color(0xffa2a7ad).withValues(alpha: 0.25), thickness: 0.5),
  tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
);
