import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

TextStyle get robotoRegular => TextStyle(
  fontFamily: AppConstants.getFontFamily(Get.locale?.languageCode ?? 'en'),
  fontWeight: FontWeight.w400,
  fontSize: Dimensions.fontSizeDefault,
);

TextStyle get robotoMedium => TextStyle(
  fontFamily: AppConstants.getFontFamily(Get.locale?.languageCode ?? 'en'),
  fontWeight: FontWeight.w500,
  fontSize: Dimensions.fontSizeDefault,
);

TextStyle get robotoBold => TextStyle(
  fontFamily: AppConstants.getFontFamily(Get.locale?.languageCode ?? 'en'),
  fontWeight: FontWeight.w700,
  fontSize: Dimensions.fontSizeDefault,
);

TextStyle get robotoBlack => TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w900,
  fontSize: Dimensions.fontSizeDefault,
);