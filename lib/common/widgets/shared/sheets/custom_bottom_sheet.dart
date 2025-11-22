import 'package:flutter/material.dart';
import 'package:godelivery_user/util/dimensions.dart';

/// Reusable custom bottom sheet with smooth animations
/// Usage: CustomBottomSheet.show(context, child: YourWidget())
class CustomBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;
  final bool isFullScreen;
  final bool showDragHandle;
  final BorderRadius? borderRadius;

  const CustomBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.isFullScreen = true,
    this.showDragHandle = false,
    this.borderRadius,
  });

  /// Show the bottom sheet with custom slide-up + scale bounce animation
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? height,
    bool isFullScreen = true,
    bool showDragHandle = false,
    BorderRadius? borderRadius,
    Duration? transitionDuration,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: transitionDuration ?? const Duration(milliseconds: 500),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Spring curve for natural physics-based animation
        const springCurve = Curves.easeOutBack;

        // Slide animation with spring physics
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: springCurve,
        ));

        // Scale animation with spring physics and bounce
        final scaleAnimation = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.85, end: 1.12)
                .chain(CurveTween(curve: Curves.easeOutCirc)),
            weight: 55,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.12, end: 0.98)
                .chain(CurveTween(curve: Curves.easeInOutSine)),
            weight: 25,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.98, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 20,
          ),
        ]).animate(animation);

        // Fade animation for smoother appearance
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return CustomBottomSheet(
          height: height,
          isFullScreen: isFullScreen,
          showDragHandle: showDragHandle,
          borderRadius: borderRadius,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = isFullScreen
        ? MediaQuery.of(context).size.height
        : (height ?? MediaQuery.of(context).size.height * 0.75);

    return SizedBox(
      height: sheetHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional drag handle
          if (showDragHandle)
            Container(
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          if (showDragHandle) const SizedBox(height: Dimensions.paddingSizeSmall),

          // Sheet content - child is responsible for its own styling
          Expanded(child: child),
        ],
      ),
    );
  }
}
