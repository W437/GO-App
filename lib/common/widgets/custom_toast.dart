/// Custom toast widget for showing temporary notification messages
/// Displays styled toast notifications with responsive design

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class CustomToast extends StatelessWidget {
  final String text;
  final bool isError;
  final Color textColor;
  final double borderRadius;
  final EdgeInsets padding;

  const CustomToast({
    super.key,
    required this.text,
    this.textColor = Colors.white,
    this.borderRadius = 30,
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 10), required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(top: 80.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: EdgeInsets.only(
                right: ResponsiveHelper.isDesktop(Get.context) ? Get.context!.width * 0.7 : Dimensions.paddingSizeLarge,
                left: Dimensions.paddingSizeLarge,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  isError ? CupertinoIcons.exclamationmark_circle_fill : Icons.check_circle,
                  color: isError ? const Color(0xffFF3B30) : const Color(0xff34C759),
                  size: 20,
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Flexible(
                  child: Text(
                    text,
                    style: robotoMedium.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}