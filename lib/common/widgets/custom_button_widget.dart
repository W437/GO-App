/// Custom reusable button widget with loading states and styling options
/// Provides consistent button appearance and behavior across the app

import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomButtonWidget extends StatelessWidget {
  final Function? onPressed;
  final String buttonText;
  final bool transparent;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double? fontSize;
  final double radius;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final bool isBold;
  const CustomButtonWidget({super.key, this.onPressed, required this.buttonText, this.transparent = false, this.margin, this.width, this.height,
    this.fontSize, this.radius = 24, this.icon, this.color, this.textColor, this.isLoading = false, this.isBold = true});

  @override
  Widget build(BuildContext context) {
    return Center(child: SizedBox(width: width ?? Dimensions.webMaxWidth, child: Padding(
      padding: margin == null ? const EdgeInsets.all(0) : margin!,
      child: Material(
        color: onPressed == null ? Theme.of(context).disabledColor.withValues(alpha: 0.6) : transparent
            ? Colors.transparent : color ?? Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: isLoading ? null : onPressed as void Function()?,
          borderRadius: BorderRadius.circular(radius),
          splashFactory: InkRipple.splashFactory,
          splashColor: Colors.black.withOpacity(0.1),
          highlightColor: Colors.black.withOpacity(0.05),
          child: Container(
            constraints: BoxConstraints(
              minWidth: width ?? Dimensions.webMaxWidth,
              minHeight: height ?? 56,
            ),
            child: Center(
              child: isLoading ? Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                  height: 15, width: 15,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Text('loading'.tr, style: robotoMedium.copyWith(color: Colors.white)),
              ]) : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                icon != null ? Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                  child: Icon(icon, color: transparent ? Theme.of(context).primaryColor : Theme.of(context).cardColor),
                ) : const SizedBox(),
                Text(buttonText, textAlign: TextAlign.center,  style: isBold ? robotoBold.copyWith(
                    color: textColor ?? (transparent ? Theme.of(context).primaryColor : Colors.white),
                    fontSize: fontSize ?? Dimensions.fontSizeLarge,
                  ) : robotoRegular.copyWith(
                    color: textColor ?? (transparent ? Theme.of(context).primaryColor : Colors.white),
                    fontSize: fontSize ?? Dimensions.fontSizeLarge,
                  )
                ),
              ]),
            ),
          ),
        ),
      ),
    )));
  }
}
