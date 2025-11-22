import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/util/dimensions.dart';

/// Reusable custom full sheet with smooth animations and swipe-to-dismiss
/// Usage: CustomFullSheet.show(context, child: YourWidget())
class CustomFullSheet extends StatefulWidget {
  final Widget child;
  final double? height;
  final bool isFullScreen;
  final bool showDragHandle;
  final BorderRadius? borderRadius;

  const CustomFullSheet({
    super.key,
    required this.child,
    this.height,
    this.isFullScreen = true,
    this.showDragHandle = false,
    this.borderRadius,
  });

  @override
  State<CustomFullSheet> createState() => _CustomFullSheetState();

  /// Show the full sheet with custom slide-up + scale bounce animation
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
      transitionDuration: transitionDuration ?? const Duration(milliseconds: 450),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Smooth curve without overshoot
        const smoothCurve = Curves.easeOutCubic;

        // Slide animation - smooth upward motion
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: smoothCurve,
        ));

        // Scale animation - smooth scale without bounce
        final scaleAnimation = Tween<double>(
          begin: 0.94,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: smoothCurve,
        ));

        // Horizontal squeeze animation - starts squeezed, expands to full width
        final scaleXAnimation = Tween<double>(
          begin: 0.6, // Start heavily squeezed
          end: 1.0,   // Expand to full width
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack, // Smooth expansion with slight overshoot
        ));

        // 3D rotation animation - top tilts forward (toward viewer)
        final rotationXAnimation = Tween<double>(
          begin: 0.4, // X-axis: Top tilted forward ~23° (radians)
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: smoothCurve,
        ));

        final rotationYAnimation = Tween<double>(
          begin: 0.12, // Y-axis: Card rotation (radians)
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: smoothCurve,
        ));

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            // Motion blur - peaks at middle of animation (fastest motion)
            final t = animation.value;
            final blurAmount = lerpDouble(0, 2, 1 - (t * 2 - 1).abs()) ?? 0;

            // Create 3D perspective transformation with top tilted forward + horizontal squeeze
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Stronger perspective for forward tilt effect
              ..scale(scaleXAnimation.value, 1.0, 1.0) // Horizontal squeeze (X-axis only)
              ..rotateX(rotationXAnimation.value); // POSITIVE = top tilts FORWARD

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
        return CustomFullSheet(
          height: height,
          isFullScreen: isFullScreen,
          showDragHandle: showDragHandle,
          borderRadius: borderRadius,
          child: child,
        );
      },
    );
  }
}

class _CustomFullSheetState extends State<CustomFullSheet> with TickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 250),
    );
    _dismissAnimation = CurvedAnimation(
      parent: _dismissController,
      curve: Curves.easeInCubic, // Fast start, slow end for dismiss
    );

    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.easeOutBack, // Spring curve for snap-back
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
    // Only allow drag from top 100px of sheet
    if (details.localPosition.dy <= 100) {
      setState(() {
        _isDragging = true;
      });
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final screenHeight = MediaQuery.of(context).size.height;
    const dismissThreshold = 0.2; // Dismiss if dragged 20% of screen

    if (_dragOffset > screenHeight * dismissThreshold) {
      // Dismiss the sheet - animate down from current position
      final startOffset = _dragOffset;
      _dismissAnimation = Tween<double>(
        begin: startOffset,
        end: screenHeight,
      ).animate(CurvedAnimation(
        parent: _dismissController,
        curve: Curves.easeOutQuint, // Very fast start, smooth slow end
      ));

      // Add listener to update drag offset as animation progresses
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
      // Snap back smoothly with spring animation
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
    final double sheetHeight = widget.isFullScreen
        ? MediaQuery.of(context).size.height
        : (widget.height ?? MediaQuery.of(context).size.height * 0.75);

    // Calculate corner radius based on drag distance
    // Max radius at Dimensions.radiusExtraLarge when dragged 100px or more
    const maxRadius = Dimensions.radiusExtraLarge;
    final dragProgress = (_dragOffset / 100.0).clamp(0.0, 1.0);
    final currentRadius = maxRadius * dragProgress;

    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffset), // Use _dragOffset directly (updated by both drag and animations)
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(currentRadius),
          ),
          child: SizedBox(
            height: sheetHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Optional drag handle
                if (widget.showDragHandle)
                  Container(
                    margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                if (widget.showDragHandle) const SizedBox(height: Dimensions.paddingSizeSmall),

                // Sheet content - child is responsible for its own styling
                Expanded(child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation system for CustomFullSheet that allows multiple pages with slide transitions
/// Usage: CustomFullSheetNavigator(initialPage: YourWidget())
class CustomFullSheetNavigator extends StatelessWidget {
  final Widget initialPage;
  final GlobalKey<NavigatorState>? navigatorKey;

  const CustomFullSheetNavigator({
    super.key,
    required this.initialPage,
    this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        // First page (initial route)
        if (settings.name == Navigator.defaultRouteName) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (_, __, ___) => initialPage,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: const Duration(milliseconds: 300),
          );
        }

        // Subsequent pages
        final page = settings.arguments as Widget?;
        if (page == null) return null;

        return _buildPageRoute(page, settings);
      },
    );
  }

  PageRouteBuilder _buildPageRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Forward: New page slides in from right
        final inAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        // Backward: Current page slides out to right, previous page slides in from left
        final outAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.25, 0), // Previous page slightly visible on left
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
        ));

        return Stack(
          children: [
            // Previous page (slides left when new page enters)
            if (secondaryAnimation.status != AnimationStatus.dismissed)
              SlideTransition(
                position: outAnimation,
                child: child,
              ),
            // Current/New page (slides in from right)
            SlideTransition(
              position: inAnimation,
              child: child,
            ),
          ],
        );
      },
    );
  }

  /// Navigate to a new page within the sheet
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final inAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));

          final outAnimation = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.25, 0),
          ).animate(CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutCubic,
          ));

          return Stack(
            children: [
              if (secondaryAnimation.status != AnimationStatus.dismissed)
                SlideTransition(position: outAnimation, child: child),
              SlideTransition(position: inAnimation, child: child),
            ],
          );
        },
      ),
    );
  }

  /// Pop the current page and return to previous
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  /// Replace current page with a new one (no back navigation)
  static Future<T?> replace<T>(BuildContext context, Widget page) {
    return Navigator.of(context).pushReplacement<T, void>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final inAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));

          return SlideTransition(position: inAnimation, child: child);
        },
      ),
    );
  }
}
