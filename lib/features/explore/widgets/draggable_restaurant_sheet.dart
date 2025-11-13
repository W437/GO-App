import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/rounded_icon_button_widget.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/category_filter_chips_widget.dart';
import 'package:godelivery_user/features/explore/widgets/restaurant_list_view_widget.dart';
import 'package:godelivery_user/features/explore/widgets/sort_filter_bar.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class DraggableRestaurantSheet extends StatefulWidget {
  final ExploreController exploreController;
  final Function(double)? onPositionChanged;
  final VoidCallback? onFullscreenToggle;

  const DraggableRestaurantSheet({
    super.key,
    required this.exploreController,
    this.onPositionChanged,
    this.onFullscreenToggle,
  });

  @override
  State<DraggableRestaurantSheet> createState() => _DraggableRestaurantSheetState();
}

class _DraggableRestaurantSheetState extends State<DraggableRestaurantSheet> {
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  bool _wasInFullscreenMode = false;

  @override
  void initState() {
    super.initState();
    _draggableController.addListener(_onDragUpdate);
  }

  @override
  void dispose() {
    _draggableController.removeListener(_onDragUpdate);
    _draggableController.dispose();
    super.dispose();
  }

  void _onDragUpdate() {
    // Update map visibility based on sheet position
    if (_draggableController.isAttached) {
      final size = _draggableController.size;
      // Schedule update after build to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.exploreController.updateSheetPosition(size);
          widget.onPositionChanged?.call(size);
        }
      });
    }
  }

  void _checkFullscreenTransition() {
    final isInFullscreen = widget.exploreController.isFullscreenMode;

    // Detect transition from fullscreen to normal mode
    if (_wasInFullscreenMode && !isInFullscreen) {
      // Reset sheet to default position when exiting fullscreen
      if (_draggableController.isAttached) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _draggableController.isAttached) {
            _draggableController.animateTo(
              0.5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }

    _wasInFullscreenMode = isInFullscreen;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExploreController>(
      builder: (controller) {
        // Check for fullscreen transitions
        _checkFullscreenTransition();

        // Allow sheet to slide down when not in fullscreen mode
        return DraggableScrollableSheet(
          controller: _draggableController,
          initialChildSize: 0.5, // 50% of screen (default)
          minChildSize: 0.5,    // Keep at 50% minimum
          maxChildSize: 0.95,    // 95% maximum (expanded - almost full screen)
          snap: true,
          snapSizes: const [0.5, 0.95], // Only 2 snap points
          builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Draggable Area (Handle + Header)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (!_draggableController.isAttached) return;

                  // Calculate new size based on drag
                  final renderBox = context.findRenderObject() as RenderBox;
                  final size = renderBox.size;
                  final pixelsDragged = -details.delta.dy;
                  final percentageDragged = pixelsDragged / size.height;

                  // Get current size
                  final currentSize = _draggableController.size;
                  var newSize = currentSize + percentageDragged;

                  // Add elastic resistance at ALL boundaries
                  const resistance = 0.25; // Resistance factor (lower = more resistance)
                  const maxOverscroll = 0.05; // Maximum 5% overscroll

                  // At default position (0.5)
                  if (currentSize <= 0.5 && newSize < 0.5) {
                    // Trying to drag down from default - apply resistance
                    final overflow = 0.5 - newSize;
                    newSize = 0.5 - (overflow * resistance);
                    newSize = newSize.clamp(0.5 - maxOverscroll, 0.5); // Max 5% below
                  }
                  // At expanded position (0.95)
                  else if (currentSize >= 0.95 && newSize > 0.95) {
                    // Trying to drag up from expanded - apply resistance
                    final overflow = newSize - 0.95;
                    newSize = 0.95 + (overflow * resistance);
                    newSize = newSize.clamp(0.95, 0.99); // Max to 99%
                  }
                  // Between positions - normal movement
                  else {
                    // No resistance in the middle zone
                    newSize = newSize.clamp(0.5 - maxOverscroll, 0.95 + maxOverscroll);
                  }

                  _draggableController.jumpTo(newSize);
                },
                onVerticalDragEnd: (details) {
                  if (!_draggableController.isAttached) return;

                  final velocity = details.primaryVelocity ?? 0;
                  final currentSize = _draggableController.size;

                  // SIMPLE RULE: Fast downward swipe at default position = trigger fullscreen
                  if (currentSize <= 0.52 && velocity > 700 && !widget.exploreController.isFullscreenMode) {
                    widget.onFullscreenToggle?.call();
                    return;
                  }

                  // Handle overscroll bounce back
                  if (currentSize < 0.5) {
                    _draggableController.animateTo(
                      0.5,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                    );
                    return;
                  } else if (currentSize > 0.95) {
                    _draggableController.animateTo(
                      0.95,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                    );
                    return;
                  }

                  // Normal zone (between 0.5 and 0.95)
                  if (velocity.abs() > 500) {
                    // Fast swipe
                    if (velocity < 0 && currentSize < 0.90) {
                      // Swiped up - expand
                      _draggableController.animateTo(
                        0.95,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    } else if (velocity > 0 && currentSize > 0.55) {
                      // Swiped down - return to default
                      _draggableController.animateTo(
                        0.5,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      // Stay at current position
                      final nearestSnap = currentSize < 0.725 ? 0.5 : 0.95;
                      _draggableController.animateTo(
                        nearestSnap,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                      );
                    }
                  } else {
                    // Slow drag - snap to nearest
                    final nearestSnap = currentSize < 0.725 ? 0.5 : 0.95;
                    _draggableController.animateTo(
                      nearestSnap,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                    );
                  }
                },
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                      ),
                      child: Row(
                  children: [
                    Expanded(
                      child: GetBuilder<ExploreController>(
                        builder: (controller) {
                          final count = controller.filteredRestaurants?.length ?? 0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.searchQuery.isEmpty
                                    ? 'nearby_restaurants'.tr
                                    : 'search_results'.tr,
                                style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                ),
                              ),
                              Text(
                                '$count ${'restaurants_found'.tr}',
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).disabledColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Expand/Collapse Button with background
                    AnimatedBuilder(
                      animation: _draggableController,
                      builder: (context, child) {
                        final isExpanded = _draggableController.isAttached && _draggableController.size >= 0.725;
                        return AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: RoundedIconButtonWidget(
                            icon: Icons.keyboard_arrow_up,
                            onPressed: () {
                              if (!_draggableController.isAttached) return;

                              final currentSize = _draggableController.size;
                              // Toggle between default (0.5) and expanded (0.95)
                              final targetSize = currentSize < 0.725 ? 0.95 : 0.5;
                              _draggableController.animateTo(
                                targetSize,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            size: 44,
                            iconSize: 28,
                            backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                            pressedColor: Theme.of(context).disabledColor.withValues(alpha: 0.25),
                            iconColor: Theme.of(context).textTheme.bodyMedium!.color,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Sort & Filter Bar
              SortFilterBar(
                exploreController: widget.exploreController,
              ),

              // Category Filter Chips
              CategoryFilterChipsWidget(
                exploreController: widget.exploreController,
              ),

              const Divider(height: 1),

              // Restaurant List (Flexible to prevent overflow)
              Flexible(
                child: RestaurantListViewWidget(
                  exploreController: widget.exploreController,
                  scrollController: scrollController, // Pass the scroll controller
                ),
              ),
            ],
          ),
        );
      },
        );
      },
    );
  }
}