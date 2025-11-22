/// Custom bottom sheet widget for modal presentations
/// Provides styled bottom sheet functionality with customizable height and animation

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/util/dimensions.dart';

void showCustomBottomSheet({required Widget child, double? maxHeight}) {
  final controller = AnimationController(
    duration: const Duration(milliseconds: 350),
    vsync: Navigator.of(Get.context!),
  );

  final curvedAnimation = CurvedAnimation(
    parent: controller,
    curve: Curves.easeOutBack,
  );

  controller.forward();

  showModalBottomSheet(
    isScrollControlled: true,
    useRootNavigator: true,
    context: Get.context!,
    backgroundColor: Colors.transparent,
    transitionAnimationController: controller,
    builder: (context) {
      return Container(
        constraints: BoxConstraints(maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.radiusExtraLarge),
            topRight: Radius.circular(Dimensions.radiusExtraLarge),
          ),
        ),
        child: child,
      );
    },
  );
}