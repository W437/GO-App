import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/draggable_restaurant_sheet.dart';
import 'package:godelivery_user/features/explore/widgets/explore_map_view_widget.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _mapOffsetAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onSheetPositionChanged(double position) {
    // position: 0.5 = default, 0.95 = expanded
    // Map this to animation value: 0.5 -> 0, 0.95 -> 1
    final animValue = ((position - 0.5) / 0.45).clamp(0.0, 1.0);
    _animationController.value = animValue;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: GetBuilder<ExploreController>(
        builder: (exploreController) {
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
                ),
              ),

              // Draggable Restaurant Sheet
              DraggableRestaurantSheet(
                exploreController: exploreController,
                onPositionChanged: _onSheetPositionChanged,
              ),
            ],
          );
        },
      ),
    );
  }
}
