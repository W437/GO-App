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
  final GlobalKey _listKey = GlobalKey();

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
    
    if (index == -1 || index >= _itemKeys.length || !_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemContext = _itemKeys[index].currentContext;
      final listContext = _listKey.currentContext;
      if (itemContext == null || listContext == null || !_scrollController.hasClients) return;

      final RenderBox listBox = listContext.findRenderObject() as RenderBox;
      final RenderBox itemBox = itemContext.findRenderObject() as RenderBox;

      final Offset itemOffset = itemBox.localToGlobal(Offset.zero, ancestor: listBox);
      final double itemCenter = itemOffset.dx + itemBox.size.width / 2;
      final double targetOffset = itemCenter - listBox.size.width / 2;
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
    return ListView.separated(
      key: _listKey,
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault,
        vertical: 2,
      ),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
      itemBuilder: (context, index) {
        final category = categories[index];
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
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: 7,
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
                      fontSize: Dimensions.fontSizeSmall,
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
