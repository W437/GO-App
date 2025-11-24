import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/util/dimensions.dart';

/// Reusable custom bottom sheet with smooth animations, drag-to-dismiss, handle bar, and keyboard support
/// Usage: CustomSheet.show(context, child: YourWidget())
class CustomSheet extends StatefulWidget {
  final Widget child;
  final bool showHandle;
  final EdgeInsets? padding;
  final bool enableDrag;

  const CustomSheet({
    super.key,
    required this.child,
    this.showHandle = true,
    this.padding,
    this.enableDrag = true,
  });

  @override
  State<CustomSheet> createState() => _CustomSheetState();

  /// Show the bottom sheet with custom smooth animations
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool showHandle = true,
    EdgeInsets? padding,
    bool isDismissible = true,
    bool enableDrag = true,
    Duration? transitionDuration,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: transitionDuration ?? const Duration(milliseconds: 450),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Smooth and swift curve
        const curve = Curves.easeOutExpo;

        // Slide animation - smooth upward motion
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        // Scale animation - subtle zoom in
        final scaleAnimation = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        // 3D rotation animation - top edges tilted forward (toward viewer)
        final rotationXAnimation = Tween<double>(
          begin: 0.3, // Subtle tilt: top tilted forward (toward viewer)
          end: 0.0,   // Flat
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            // Motion blur - peaks at middle of animation (fastest motion)
            final t = animation.value;
            final blurAmount = lerpDouble(0, 2, 1 - (t * 2 - 1).abs()) ?? 0;

            // Create 3D perspective transformation
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.003) // Stronger perspective for more visible effect
              ..rotateX(rotationXAnimation.value); // Rotate around X-axis

            return ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blurAmount,
                sigmaY: blurAmount,
                tileMode: TileMode.decal,
              ),
              child: Transform(
                transform: transform,
                alignment: Alignment.bottomCenter, // Pivot at bottom
                child: child!,
              ),
            );
          },
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
        return Align(
          alignment: Alignment.bottomCenter,
          child: CustomSheet(
            showHandle: showHandle,
            padding: padding,
            enableDrag: enableDrag,
            child: child,
          ),
        );
      },
    );
  }
}

class _CustomSheetState extends State<CustomSheet> with TickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isDragging = false;
  late AnimationController _dismissController;
  late Animation<double> _dismissAnimation;
  late AnimationController _snapBackController;
  late Animation<double> _snapBackAnimation;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _dismissAnimation = CurvedAnimation(
      parent: _dismissController,
      curve: Curves.fastOutSlowIn,
    );

    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.easeOutBack,
    );

    _snapBackAnimation.addListener(() {
      if (!_isDragging) {
        setState(() {
          _dragOffset = _snapBackAnimation.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissController.dispose();
    _snapBackController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enableDrag) return;
    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      // Only allow dragging down (positive offset)
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    const dismissThreshold = 100.0; // Dismiss if dragged down 100px

    if (_dragOffset > dismissThreshold) {
      // Dismiss the sheet
      final screenHeight = MediaQuery.of(context).size.height;
      _dismissAnimation = Tween<double>(
        begin: _dragOffset,
        end: screenHeight,
      ).animate(CurvedAnimation(
        parent: _dismissController,
        curve: Curves.easeOut,
      ));

      void updateOffset() {
        setState(() {
          _dragOffset = _dismissAnimation.value;
        });
      }

      _dismissController.addListener(updateOffset);

      setState(() {
        _isDragging = false;
      });

      _dismissController.forward(from: 0.0).then((_) {
        _dismissController.removeListener(updateOffset);
        Get.back();
      });
    } else {
      // Snap back to original position
      _snapBackAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _snapBackController,
        curve: Curves.easeOutBack,
      ));

      setState(() {
        _isDragging = false;
      });

      _snapBackController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Dimensions.radiusDefault),
              ),
            ),
            padding: widget.padding ?? const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showHandle)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
