import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class CategoryFilterChipsWidget extends StatefulWidget {
  final ExploreController exploreController;

  const CategoryFilterChipsWidget({
    super.key,
    required this.exploreController,
  });

  @override
  State<CategoryFilterChipsWidget> createState() => _CategoryFilterChipsWidgetState();
}

class _CategoryFilterChipsWidgetState extends State<CategoryFilterChipsWidget> with SingleTickerProviderStateMixin {
  bool _isSearchExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    if (_isSearchExpanded) {
      // Closing - animate first, then update state
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isSearchExpanded = false;
          });
        }
      });
      _searchFocusNode.unfocus();
      _searchController.clear();
      widget.exploreController.clearSearch();
    } else {
      // Opening - update state first, then animate
      setState(() {
        _isSearchExpanded = true;
      });
      _animationController.forward();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        // Show shimmer loading state
        if (categoryController.categoryList == null) {
          return SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeDefault,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(
                  left: Dimensions.paddingSizeDefault,
                  right: Dimensions.paddingSizeDefault,
                ),
                child: Row(
                  children: List.generate(6, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                      child: _buildCategoryShimmer(context),
                    );
                  }),
                ),
              ),
            ),
          );
        }

        if (categoryController.categoryList!.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Dimensions.paddingSizeDefault,
            ),
            child: GetBuilder<ExploreController>(
              builder: (controller) {
                return RawGestureDetector(
                  gestures: {
                    VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                      (VerticalDragGestureRecognizer instance) {},
                    ),
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                      left: Dimensions.paddingSizeDefault,
                      right: Dimensions.paddingSizeDefault,
                    ),
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    // Animated Search Button/Field
                    AnimatedBuilder(
                      animation: _expandAnimation,
                      builder: (context, child) {
                        // Calculate dimensions to match category chip height
                        final double buttonHeight = 36; // Match category chip padding + text height
                        final double buttonSize = buttonHeight;
                        final double expandedWidth = 250;
                        final double currentWidth = _isSearchExpanded
                            ? buttonSize + (_expandAnimation.value * (expandedWidth - buttonSize))
                            : buttonSize;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: currentWidth,
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ClipRect(
                              child: Stack(
                                children: [
                                  // Search Field (expanded state)
                                  Opacity(
                                    opacity: _expandAnimation.value,
                                    child: IgnorePointer(
                                      ignoring: !_isSearchExpanded,
                                      child: OverflowBox(
                                        maxWidth: expandedWidth,
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          width: expandedWidth,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(left: 12, right: 8),
                                                child: Icon(
                                                  Icons.search,
                                                  size: 16,
                                                  color: Theme.of(context).disabledColor,
                                                ),
                                              ),
                                              Expanded(
                                                child: TextField(
                                                  controller: _searchController,
                                                  focusNode: _searchFocusNode,
                                                  style: robotoMedium.copyWith(
                                                    fontSize: Dimensions.fontSizeSmall,
                                                    color: Theme.of(context).textTheme.bodyMedium!.color,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: 'search'.tr,
                                                    hintStyle: robotoMedium.copyWith(
                                                      fontSize: Dimensions.fontSizeSmall,
                                                      color: Theme.of(context).disabledColor,
                                                    ),
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.zero,
                                                  ),
                                                  onChanged: (value) {
                                                    controller.searchRestaurants(value, saveToHistory: false);
                                                  },
                                                ),
                                              ),
                                              InkWell(
                                                onTap: _toggleSearch,
                                                borderRadius: BorderRadius.circular(100),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Theme.of(context).disabledColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Search Button (collapsed state)
                                  Opacity(
                                    opacity: 1 - _expandAnimation.value,
                                    child: IgnorePointer(
                                      ignoring: _isSearchExpanded,
                                      child: InkWell(
                                        onTap: _toggleSearch,
                                        borderRadius: BorderRadius.circular(100),
                                        child: Container(
                                          width: buttonSize,
                                          height: buttonSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.search,
                                              size: 18,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    // "All" chip
                    _buildCategoryChip(
                      context: context,
                      label: 'all'.tr,
                      isSelected: controller.selectedCategoryId == null,
                      onTap: () {
                        controller.filterByCategory(null);
                      },
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    // Category chips
                    ...categoryController.categoryList!.map((category) {
                      final isSelected = controller.selectedCategoryId == category.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                        child: _buildCategoryChip(
                          context: context,
                          label: category.name ?? '',
                          isSelected: isSelected,
                          onTap: () {
                            controller.filterByCategory(category.id);
                          },
                        ),
                      );
                    }).toList(),
                    ],
                  ),
                ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryShimmer(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Shimmer(
        color: Theme.of(context).disabledColor.withOpacity(0.3),
        child: Container(
          height: 32,
          width: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: robotoMedium.copyWith(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium!.color,
            fontSize: Dimensions.fontSizeSmall,
          ),
        ),
      ),
    );
  }
}
