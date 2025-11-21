import 'package:flutter/material.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/category/domain/models/category_model.dart';
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
  final GlobalKey _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeKeys();
  }

  @override
  void didUpdateWidget(covariant RestaurantStickyHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final categories = widget.restController.categoryList ?? [];
    final hasAllCategory = categories.any((cat) => cat.id == 0);
    final expectedKeys = hasAllCategory ? categories.length : categories.length + 1;

    if (expectedKeys != _itemKeys.length) {
      _initializeKeys();
    }
    if (widget.activeCategoryId != oldWidget.activeCategoryId) {
      _scrollToActiveCategory();
    }
  }

  void _initializeKeys() {
    final categories = widget.restController.categoryList ?? [];
    _itemKeys.clear();
    // Check if "All" already exists
    final hasAllCategory = categories.any((cat) => cat.id == 0);
    // Add keys: +1 only if we need to add "All" category
    final totalItems = hasAllCategory ? categories.length : categories.length + 1;
    for (var i = 0; i < totalItems; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  void _scrollToActiveCategory() {
    final categories = widget.restController.categoryList ?? [];
    final hasAllCategory = categories.any((cat) => cat.id == 0);

    // Find the index in the displayed list
    int index;
    if (widget.activeCategoryId == 0) {
      index = 0; // "All" is always at the first position
    } else {
      index = categories.indexWhere((c) => c.id == widget.activeCategoryId);
      if (index != -1 && !hasAllCategory) {
        // Only offset by 1 if we added "All" (it doesn't exist in backend data)
        index = index + 1;
      }
    }

    if (index == -1 || index >= _itemKeys.length || !_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemContext = _itemKeys[index].currentContext;
      final listContext = _listKey.currentContext;
      if (itemContext == null || listContext == null || !_scrollController.hasClients) return;

      final RenderBox listBox = listContext.findRenderObject() as RenderBox;
      final RenderBox itemBox = itemContext.findRenderObject() as RenderBox;

      // Get the item's global position and the list's global position
      final Offset itemGlobalPosition = itemBox.localToGlobal(Offset.zero);
      final Offset listGlobalPosition = listBox.localToGlobal(Offset.zero);

      // Calculate the item's position relative to the list's scroll position
      final double itemRelativePosition = itemGlobalPosition.dx - listGlobalPosition.dx;
      final double itemCenterInList = itemRelativePosition + (itemBox.size.width / 2);

      // Calculate the target scroll offset to center the item
      final double listCenter = listBox.size.width / 2;
      final double targetOffset = _scrollController.offset + itemCenterInList - listCenter;
      final double clampedOffset = targetOffset
          .clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent)
          .toDouble();

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.restController.categoryList ?? [];

    // Check if "All" category already exists (id: 0)
    final hasAllCategory = categories.any((cat) => cat.id == 0);

    // Only add "All" category if it doesn't exist
    final categoriesWithAll = hasAllCategory
        ? categories
        : [CategoryModel(id: 0, name: 'All'), ...categories];

    return ListView.separated(
      key: _listKey,
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault,
        vertical: 2,
      ),
      itemCount: categoriesWithAll.length,
      separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
      itemBuilder: (context, index) {
        final category = categoriesWithAll[index];
        final bool isActive = category.id != null && category.id == widget.activeCategoryId;
        return Center(
          child: KeyedSubtree(
            key: _itemKeys.length > index ? _itemKeys[index] : null,
            child: CustomInkWellWidget(
              radius: 18,
              onTap: category.id == null ? () {} : () => widget.onCategorySelected(category.id!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeLarge,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor.withValues(alpha: 0.1),
                ),
                child: Text(
                    category.name ?? '',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: isActive ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
            ),
          ),
        );
      },
    );
  }
}
