/// Custom reusable button widget with loading states and styling options
/// Provides consistent button appearance and behavior across the app

import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomButtonWidget extends StatefulWidget {
  final Function? onPressed;
  final String? buttonText;
  final bool transparent;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double? fontSize;
  final double radius;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final Color? iconColor;
  final double? iconSize;
  final bool isLoading;
  final bool isBold;
  final bool isCircular;
  final Widget? child;
  final BoxBorder? border;

  const CustomButtonWidget({
    super.key,
    this.onPressed,
    this.buttonText,
    this.transparent = false,
    this.margin,
    this.width,
    this.height,
    this.fontSize,
    this.radius = 100,
    this.icon,
    this.color,
    this.textColor,
    this.iconColor,
    this.iconSize,
    this.isLoading = false,
    this.isBold = true,
    this.isCircular = false,
    this.child,
    this.border,
  });

  @override
  State<CustomButtonWidget> createState() => _CustomButtonWidgetState();
}

class _CustomButtonWidgetState extends State<CustomButtonWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // For circular buttons (icon-only)
    if (widget.isCircular) {
      final size = widget.width ?? widget.height ?? 44.0;
      return Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: GestureDetector(
          onTapDown: widget.onPressed != null && !widget.isLoading ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.isLoading ? null : widget.onPressed as void Function()?,
          child: AnimatedOpacity(
            opacity: _isPressed ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: widget.onPressed == null
                  ? Theme.of(context).disabledColor.withValues(alpha: 0.6)
                  : widget.transparent
                    ? Colors.transparent
                    : widget.color ?? Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: widget.border,
              ),
              child: Center(
                child: widget.child ?? (widget.icon != null
                  ? Icon(
                      widget.icon,
                      color: widget.iconColor ?? (widget.transparent ? Theme.of(context).primaryColor : Theme.of(context).cardColor),
                      size: widget.iconSize ?? 24,
                    )
                  : null),
              ),
            ),
          ),
        ),
      );
    }

    // For regular buttons (existing behavior)
    return Center(child: SizedBox(width: widget.width ?? Dimensions.webMaxWidth, child: Padding(
      padding: widget.margin == null ? const EdgeInsets.all(0) : widget.margin!,
      child: GestureDetector(
        onTapDown: widget.onPressed != null && !widget.isLoading ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isLoading ? null : widget.onPressed as void Function()?,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              color: widget.onPressed == null ? Theme.of(context).disabledColor.withValues(alpha: 0.6) : widget.transparent
                  ? Colors.transparent : widget.color ?? Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(widget.radius),
              border: widget.border,
            ),
            constraints: BoxConstraints(
              minWidth: widget.width ?? Dimensions.webMaxWidth,
              minHeight: widget.height ?? 56,
            ),
            child: widget.child ?? Center(
              child: widget.isLoading ? Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
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
                widget.icon != null ? Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                  child: Icon(widget.icon, color: widget.iconColor ?? (widget.transparent ? Theme.of(context).primaryColor : Theme.of(context).cardColor)),
                ) : const SizedBox(),
                widget.buttonText != null ? Text(widget.buttonText!, textAlign: TextAlign.center,  style: widget.isBold ? robotoBold.copyWith(
                    color: widget.textColor ?? (widget.transparent ? Theme.of(context).primaryColor : Colors.white),
                    fontSize: widget.fontSize ?? Dimensions.fontSizeLarge,
                  ) : robotoRegular.copyWith(
                    color: widget.textColor ?? (widget.transparent ? Theme.of(context).primaryColor : Colors.white),
                    fontSize: widget.fontSize ?? Dimensions.fontSizeLarge,
                  )
                ) : const SizedBox(),
              ]),
            ),
          ),
        ),
      ),
    )));
  }
}
