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
  final bool expand;

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
    this.expand = true,
  });

  @override
  State<CustomButtonWidget> createState() => _CustomButtonWidgetState();
}

class _CustomButtonWidgetState extends State<CustomButtonWidget> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Press animation - very subtle scale down
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOut,
    ));

    // Bounce animation - minimal spring back
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.02).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 0.995).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.995, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For circular buttons (icon-only)
    if (widget.isCircular) {
      final size = widget.width ?? widget.height ?? 44.0;
      return Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pressAnimation, _bounceAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pressAnimation.value * _bounceAnimation.value,
              child: child,
            );
          },
          child: GestureDetector(
            onTapDown: widget.onPressed != null && !widget.isLoading ? (_) => _pressController.forward() : null,
            onTapUp: (_) => _pressController.reverse(),
            onTapCancel: () => _pressController.reverse(),
            onTap: widget.isLoading ? null : () {
              // Only start bounce if not already animating (prevent double-click reset)
              if (!_bounceController.isAnimating) {
                _bounceController.forward(from: 0.0);
              }
              widget.onPressed?.call();
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: widget.onPressed == null
                  ? Theme.of(context).disabledColor.withValues(alpha: 0.6)
                  : widget.transparent
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
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

    // For regular buttons
    Widget buttonCore = GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading ? (_) => _pressController.forward() : null,
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.isLoading ? null : () {
        if (!_bounceController.isAnimating) {
          _bounceController.forward(from: 0.0);
        }
        widget.onPressed?.call();
      },
      child: Container(
        width: widget.expand ? double.infinity : widget.width,
        decoration: BoxDecoration(
          color: widget.onPressed == null ? Theme.of(context).disabledColor.withValues(alpha: 0.6) : widget.transparent
              ? Theme.of(context).primaryColor.withValues(alpha: 0.08) : widget.color ?? Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(widget.radius),
          border: widget.border,
        ),
        constraints: BoxConstraints(
          minWidth: widget.expand ? 0 : (widget.width ?? 0),
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
    );

    Widget animatedButton = AnimatedBuilder(
      animation: Listenable.merge([_pressAnimation, _bounceAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pressAnimation.value * _bounceAnimation.value,
          child: child,
        );
      },
      child: buttonCore,
    );

    Widget padded = Padding(
      padding: widget.margin == null ? const EdgeInsets.all(0) : widget.margin!,
      child: animatedButton,
    );

    if (widget.expand) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Guarantee a finite width even when parent gives unbounded constraints (e.g. dialogs/sheets).
          final double resolvedWidth = constraints.hasBoundedWidth && constraints.maxWidth < double.infinity
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          return SizedBox(
            width: resolvedWidth,
            child: padded,
          );
        },
      );
    }

    if (widget.width != null) {
      padded = SizedBox(width: widget.width, child: padded);
    }

    return padded;
  }
}
