import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/category_filter_chips_widget.dart';
import 'package:godelivery_user/features/explore/widgets/restaurant_list_view_widget.dart';
import 'package:godelivery_user/features/explore/widgets/search_bar_widget.dart';
import 'package:godelivery_user/features/explore/widgets/sort_filter_bar.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class DraggableRestaurantSheet extends StatefulWidget {
  final ExploreController exploreController;

  const DraggableRestaurantSheet({
    super.key,
    required this.exploreController,
  });

  @override
  State<DraggableRestaurantSheet> createState() => _DraggableRestaurantSheetState();
}

class _DraggableRestaurantSheetState extends State<DraggableRestaurantSheet> {
  final DraggableScrollableController _draggableController = DraggableScrollableController();

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
      widget.exploreController.updateSheetPosition(size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: 0.5, // 50% of screen
      minChildSize: 0.15,    // 15% minimum
      maxChildSize: 0.9,     // 90% maximum
      snap: true,
      snapSizes: const [0.15, 0.5, 0.9], // Snap points
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
                  final newSize = (_draggableController.size + percentageDragged).clamp(0.15, 0.9);

                  _draggableController.jumpTo(newSize);
                },
                onVerticalDragEnd: (details) {
                  if (!_draggableController.isAttached) return;

                  // Snap to nearest position
                  final velocity = details.primaryVelocity ?? 0;
                  final currentSize = _draggableController.size;

                  if (velocity.abs() > 500) {
                    // Fast swipe - expand or collapse based on direction
                    if (velocity < 0) {
                      // Swiped up - expand
                      _draggableController.animateTo(
                        currentSize < 0.5 ? 0.5 : 0.9,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    } else {
                      // Swiped down - collapse
                      _draggableController.animateTo(
                        currentSize > 0.5 ? 0.5 : 0.15,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  } else {
                    // Slow drag - snap to nearest
                    final snapSizes = [0.15, 0.5, 0.9];
                    double nearestSnap = snapSizes[0];
                    double minDiff = (currentSize - snapSizes[0]).abs();

                    for (final snap in snapSizes) {
                      final diff = (currentSize - snap).abs();
                      if (diff < minDiff) {
                        minDiff = diff;
                        nearestSnap = snap;
                      }
                    }

                    _draggableController.animateTo(
                      nearestSnap,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
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
                    // Expand/Collapse Button
                    IconButton(
                      onPressed: () {
                        if (!_draggableController.isAttached) return;

                        final currentSize = _draggableController.size;
                        if (currentSize < 0.5) {
                          _draggableController.animateTo(
                            0.5,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        } else if (currentSize < 0.9) {
                          _draggableController.animateTo(
                            0.9,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        } else {
                          _draggableController.animateTo(
                            0.5,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      icon: Icon(
                        _draggableController.isAttached && _draggableController.size < 0.9
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                child: SearchBarWidget(
                  exploreController: widget.exploreController,
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

              // Restaurant List (Expanded)
              Expanded(
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
  }
}