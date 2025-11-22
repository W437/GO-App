import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

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

/// Page configuration for CustomFullSheetNavigator
class CustomFullSheetPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? leading;
  final List<Widget>? actions;

  const CustomFullSheetPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }

  /// Extract page config from widget
  static CustomFullSheetPage? of(BuildContext context) {
    return context.findAncestorWidgetOfExactType<CustomFullSheetPage>();
  }
}

/// Navigation system for CustomFullSheet with persistent top bar and smooth transitions
/// Usage: CustomFullSheetNavigator(initialPage: CustomFullSheetPage(...))
class CustomFullSheetNavigator extends StatefulWidget {
  final CustomFullSheetPage initialPage;
  final GlobalKey<NavigatorState>? navigatorKey;

  const CustomFullSheetNavigator({
    super.key,
    required this.initialPage,
    this.navigatorKey,
  });

  @override
  State<CustomFullSheetNavigator> createState() => _CustomFullSheetNavigatorState();

  /// Navigate to a new page within the sheet
  static Future<T?> push<T>(BuildContext context, CustomFullSheetPage page) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        settings: RouteSettings(arguments: page),
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
  static Future<T?> replace<T>(BuildContext context, CustomFullSheetPage page) {
    return Navigator.of(context).pushReplacement<T, void>(
      PageRouteBuilder(
        settings: RouteSettings(arguments: page),
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

class _CustomFullSheetNavigatorState extends State<CustomFullSheetNavigator> {
  late String _currentTitle;
  String? _currentSubtitle;
  Widget? _currentLeading;
  List<Widget>? _currentActions;

  String _nextTitle = '';
  String? _nextSubtitle;
  Widget? _nextLeading;
  List<Widget>? _nextActions;

  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.initialPage.title;
    _currentSubtitle = widget.initialPage.subtitle;
    _currentLeading = widget.initialPage.leading;
    _currentActions = widget.initialPage.actions;
  }

  void _updatePageInfo(CustomFullSheetPage page, {bool isTransition = false}) {
    if (isTransition) {
      setState(() {
        _isTransitioning = true;
        _nextTitle = page.title;
        _nextSubtitle = page.subtitle;
        _nextLeading = page.leading;
        _nextActions = page.actions;
      });

      // After transition completes, update current
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _currentTitle = _nextTitle;
            _currentSubtitle = _nextSubtitle;
            _currentLeading = _nextLeading;
            _currentActions = _nextActions;
            _isTransitioning = false;
          });
        }
      });
    } else {
      setState(() {
        _currentTitle = page.title;
        _currentSubtitle = page.subtitle;
        _currentLeading = page.leading;
        _currentActions = page.actions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fixed top bar
        _buildTopBar(context),

        // Sliding content area
        Expanded(
          child: Navigator(
            key: widget.navigatorKey,
            onGenerateRoute: (settings) {
              // First page (initial route)
              if (settings.name == Navigator.defaultRouteName) {
                return PageRouteBuilder(
                  settings: settings,
                  pageBuilder: (_, __, ___) => widget.initialPage,
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: const Duration(milliseconds: 300),
                );
              }

              // Subsequent pages
              final page = settings.arguments as CustomFullSheetPage?;
              if (page == null) return null;

              // Update top bar with transition
              _updatePageInfo(page, isTransition: true);

              return _buildPageRoute(page, settings);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Leading widget (back button)
          _currentLeading ?? const SizedBox(width: 44),

          // Title with crossfade
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Column(
                key: ValueKey(_currentTitle),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentTitle,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_currentSubtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _currentSubtitle!,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Actions with crossfade
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: SizedBox(
              key: ValueKey(_currentActions?.length ?? 0),
              width: 44,
              child: _currentActions != null && _currentActions!.isNotEmpty
                  ? _currentActions!.first
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  PageRouteBuilder _buildPageRoute(CustomFullSheetPage page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Only slide the content, top bar stays fixed
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
    );
  }
}
