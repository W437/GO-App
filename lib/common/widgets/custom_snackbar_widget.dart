/// Custom snackbar widget for displaying toast messages and notifications
/// Provides styled error and success messages with consistent appearance

import 'package:godelivery_user/common/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> showCustomSnackBar(String? message, {bool isError = true}) async {
  if(message != null && message.isNotEmpty) {

    Get.closeCurrentSnackbar();
    Get.showSnackbar(GetSnackBar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 3),
      overlayBlur: 0.0,
      margin: const EdgeInsets.all(0),
      messageText: CustomToast(text: message, isError: isError),
      borderRadius: 0,
      padding: const EdgeInsets.all(0),
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      blockBackgroundInteraction: false,
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      animationDuration: const Duration(milliseconds: 300),
    ));

  }
}