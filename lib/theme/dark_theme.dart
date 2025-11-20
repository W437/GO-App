import 'package:godelivery_user/util/app_colors.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

ThemeData dark({String? languageCode}) => ThemeData(
  fontFamily: AppConstants.getFontFamily(languageCode ?? Get.locale?.languageCode ?? 'en'),
  primaryColor: AppColors.brandPrimary,
  secondaryHeaderColor: AppColors.brandSecondary,
  disabledColor: AppColors.textMuted,
  brightness: Brightness.dark,
  hintColor: AppColors.textSecondary,
  cardColor: AppColors.backgroundDarkGray,
  shadowColor: Colors.black.withValues(alpha: 0.3),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.brandPrimary)),
  colorScheme: const ColorScheme.dark(
    primary: AppColors.brandPrimary,
    tertiary: AppColors.brandSecondary,
    tertiaryContainer: AppColors.brandSecondaryLight,
    secondary: AppColors.brandPrimary,
  ).copyWith(surface: AppColors.backgroundDarkLight).copyWith(error: AppColors.semanticError),
  popupMenuTheme: const PopupMenuThemeData(
    color: AppColors.backgroundDarkElevated,
    surfaceTintColor: AppColors.backgroundDarkElevated,
  ),
  dialogTheme: const DialogThemeData(
    surfaceTintColor: Colors.transparent,
    backgroundColor: AppColors.backgroundDarkElevated,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: AppColors.backgroundDarkGray,
    color: AppColors.backgroundDarkGray,
    height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),
  dividerTheme: DividerThemeData(
    color: AppColors.borderDark.withValues(alpha: 0.15),
    thickness: 0.5,
  ),
  tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
  scaffoldBackgroundColor: AppColors.backgroundDarkLight,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundDarkGray,
    surfaceTintColor: AppColors.backgroundDarkGray,
  ),
);