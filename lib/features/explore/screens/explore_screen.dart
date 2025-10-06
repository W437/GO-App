import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/circular_back_button_widget.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/draggable_restaurant_sheet.dart';
import 'package:godelivery_user/features/explore/widgets/explore_map_view_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _mapOffsetAnimation;
  late AnimationController _fullscreenAnimationController;
  late Animation<Offset> _sheetAnimation;
  late Animation<Offset> _topButtonsAnimation;
  late Animation<Offset> _backButtonAnimation;
  late Animation<double> _topButtonsFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _mapOffsetAnimation = Tween<double>(
      begin: 0,
      end: -0.4, // Push map up by 40% of screen height when expanded
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fullscreenAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _sheetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1), // Slide down
    ).animate(CurvedAnimation(
      parent: _fullscreenAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    _topButtonsAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1), // Slide up
    ).animate(CurvedAnimation(
      parent: _fullscreenAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    _backButtonAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Start from above
      end: Offset.zero, // Slide down to position
    ).animate(CurvedAnimation(
      parent: _fullscreenAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _topButtonsFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fullscreenAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullscreenAnimationController.dispose();
    super.dispose();
  }

  void _onSheetPositionChanged(double position) {
    // position: 0.5 = default, 0.95 = expanded
    // Map this to animation value: 0.5 -> 0, 0.95 -> 1
    final animValue = ((position - 0.5) / 0.45).clamp(0.0, 1.0);
    _animationController.value = animValue;
  }

  void _toggleFullscreen(ExploreController controller) {
    if (controller.isFullscreenMode) {
      _fullscreenAnimationController.reverse();
    } else {
      _fullscreenAnimationController.forward();
    }
    controller.toggleFullscreenMode();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (Get.find<ExploreController>().isFullscreenMode) {
          _toggleFullscreen(Get.find<ExploreController>());
        }
      },
      child: Scaffold(
        body: GetBuilder<ExploreController>(
          builder: (exploreController) {
            // Sync animation with controller state
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (exploreController.isFullscreenMode && _fullscreenAnimationController.status != AnimationStatus.completed) {
                _fullscreenAnimationController.forward();
              } else if (!exploreController.isFullscreenMode && _fullscreenAnimationController.status != AnimationStatus.dismissed) {
                _fullscreenAnimationController.reverse();
              }
            });

            return Stack(
            children: [
              // Animated Map View
              AnimatedBuilder(
                animation: _mapOffsetAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _mapOffsetAnimation.value * screenHeight),
                    child: child,
                  );
                },
                child: ExploreMapViewWidget(
                  exploreController: exploreController,
                  onFullscreenToggle: () => _toggleFullscreen(exploreController),
                  topButtonsAnimation: _topButtonsAnimation,
                  topButtonsFadeAnimation: _topButtonsFadeAnimation,
                ),
              ),

              // Draggable Restaurant Sheet
              SlideTransition(
                position: _sheetAnimation,
                child: DraggableRestaurantSheet(
                  exploreController: exploreController,
                  onPositionChanged: _onSheetPositionChanged,
                ),
              ),

              // Back button (only visible in fullscreen mode) with slide down animation
              if (exploreController.isFullscreenMode)
                Positioned(
                  top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeDefault,
                  left: Dimensions.paddingSizeDefault,
                  child: SlideTransition(
                    position: _backButtonAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircularBackButtonWidget(
                        showText: true,
                        backgroundColor: Theme.of(context).cardColor,
                        onPressed: () => _toggleFullscreen(exploreController),
                      ),
                    ),
                  ),
                ),
            ],
            );
          },
        ),
      ),
    );
  }
}
