/// Gradient screen header widget for consistent page headers with rounded bottom
/// Displays title with optional back button in a styled container

import 'package:flutter/material.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:get/get.dart';

class GradientScreenHeaderWidget extends StatelessWidget {
  final String title;
  final double? height;
  final bool showBackButton;

  const GradientScreenHeaderWidget({
    super.key,
    required this.title,
    this.height,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 80,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeOverLarge,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                child: Text(
                  title,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).cardColor,
                  ),
                ),
              ),
            ),
            if (showBackButton)
              Positioned(
                left: Dimensions.paddingSizeSmall,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Theme.of(context).cardColor,
                      size: 20,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
