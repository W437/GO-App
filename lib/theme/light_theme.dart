import 'package:godelivery_user/util/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

ThemeData light({String? languageCode}) => ThemeData(
  fontFamily: AppConstants.getFontFamily(languageCode ?? Get.locale?.languageCode ?? 'en'),
  primaryColor: const Color(0xFFff6b00),
  secondaryHeaderColor: const Color(0x9Bff6b00),
  disabledColor: const Color(0xFF9B9B9B),
  brightness: Brightness.light,
  hintColor: const Color(0xFF5E6472),
  cardColor: Colors.white,
  shadowColor: Colors.black.withValues(alpha: 0.03),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFFff6b00))),
  colorScheme: const ColorScheme.light(primary: Color(0xFFff6b00),
    tertiary: Color(0xFFe65c00),
    tertiaryContainer: Color(0xFFe65c00),
    secondary: Color(0xFFff6b00)).copyWith(surface: const Color(0xFFF5F6F8)).copyWith(error: const Color(0xFFE84D4F),
  ),
  popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.white),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white),
  floatingActionButtonTheme: FloatingActionButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
  bottomAppBarTheme: const BottomAppBarTheme(
    surfaceTintColor: Colors.white, height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),
  dividerTheme: DividerThemeData(color: const Color(0xFFBABFC4).withValues(alpha: 0.25), thickness: 0.5),
  tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
);