import 'package:flutter/material.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class RestaurantStickyHeaderWidget extends StatefulWidget {
  final RestaurantController restController;
  final int? activeCategoryId;
  final ValueChanged<int> onCategorySelected;
  const RestaurantStickyHeaderWidget({
    super.key,
    required this.restController,
    required this.activeCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<RestaurantStickyHeaderWidget> createState() => _RestaurantStickyHeaderWidgetState();
}

class _RestaurantStickyHeaderWidgetState extends State<RestaurantStickyHeaderWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    _initializeKeys();
  }

  @override
  void didUpdateWidget(covariant RestaurantStickyHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restController.categoryList?.length != _itemKeys.length) {
      _initializeKeys();
    }
    if (widget.activeCategoryId != oldWidget.activeCategoryId) {
      _scrollToActiveCategory();
    }
  }

  void _initializeKeys() {
    final categories = widget.restController.categoryList ?? [];
    _itemKeys.clear();
    for (var i = 0; i < categories.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  void _scrollToActiveCategory() {
    final categories = widget.restController.categoryList ?? [];
    final index = categories.indexWhere((c) => c.id == widget.activeCategoryId);
    
    if (index != -1 && index < _itemKeys.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _itemKeys[index];
        final context = key.currentContext;
        if (context != null) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final double screenWidth = MediaQuery.of(context).size.width;
            final double itemWidth = box.size.width;
            final double itemPosition = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject()?.parent as RenderObject?).dx; 
            // Note: localToGlobal relative to viewport is tricky with ListView. 
            // Better approach: Calculate offset based on item position in the scroll view.
            
            // Simplified approach:
            // We can't easily get exact scroll offset without adding up widths or using a different scrollable.
            // But we can try to ensure it's visible.
            // A more robust way for variable width list centering without packages:
            Scrollable.ensureVisible(
              context,
              alignment: 0.5, // Center the item
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.restController.categoryList ?? [];
    return Container(
      width: Dimensions.webMaxWidth,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault,
          ),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) {
            final category = categories[index];
            final bool isActive = category.id != null && category.id == widget.activeCategoryId;
            return KeyedSubtree(
              key: _itemKeys.length > index ? _itemKeys[index] : null,
              child: CustomInkWellWidget(
                radius: 20,
                onTap: category.id == null ? () {} : () => widget.onCategorySelected(category.id!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).disabledColor.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      category.name ?? '',
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: isActive ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
