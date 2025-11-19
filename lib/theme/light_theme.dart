import 'package:godelivery_user/util/app_colors.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

ThemeData light({String? languageCode}) => ThemeData(
  fontFamily: AppConstants.getFontFamily(languageCode ?? Get.locale?.languageCode ?? 'en'),
  primaryColor: AppColors.brandPrimary,
  secondaryHeaderColor: AppColors.brandSecondary,
  disabledColor: AppColors.textMuted,
  brightness: Brightness.light,
  hintColor: AppColors.textSecondary,
  cardColor: AppColors.backgroundPrimary,
  shadowColor: AppColors.shadowLight,
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.brandPrimary)),
  colorScheme: const ColorScheme.light(
    primary: AppColors.brandPrimary,
    tertiary: AppColors.brandSecondary,
    tertiaryContainer: AppColors.brandSecondaryLight,
    secondary: AppColors.brandPrimary,
  ).copyWith(surface: AppColors.backgroundSecondary).copyWith(error: AppColors.semanticError),
  popupMenuTheme: const PopupMenuThemeData(color: AppColors.backgroundPrimary, surfaceTintColor: AppColors.backgroundPrimary),
  dialogTheme: const DialogThemeData(surfaceTintColor: AppColors.backgroundPrimary),
  floatingActionButtonTheme: FloatingActionButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: AppColors.backgroundPrimary, height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),
  dividerTheme: DividerThemeData(color: AppColors.borderLight.withValues(alpha: 0.25), thickness: 0.5),
  tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
);