import 'package:flutter/material.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/features/restaurant/domain/models/menu_sections_response.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class RestaurantStickyHeaderWidget extends StatefulWidget {
  final RestaurantController restController;
  final int? activeSectionId;
  final ValueChanged<int> onSectionSelected;
  const RestaurantStickyHeaderWidget({
    super.key,
    required this.restController,
    this.activeSectionId,
    required this.onSectionSelected,
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
    final sections = widget.restController.visibleMenuSections ?? [];

    if (sections.length != _itemKeys.length) {
      _initializeKeys();
    }
    if (widget.activeSectionId != oldWidget.activeSectionId) {
      _scrollToActiveSection();
    }
  }

  void _initializeKeys() {
    final sections = widget.restController.visibleMenuSections;
    final sectionsMeta = widget.restController.menuSectionsMeta;
    final count = sections?.length ?? sectionsMeta?.length ?? 0;

    _itemKeys.clear();
    for (var i = 0; i < count; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  void _scrollToActiveSection() {
    final sections = widget.restController.visibleMenuSections;
    final sectionsMeta = widget.restController.menuSectionsMeta;

    int index = -1;
    if (sections != null && sections.isNotEmpty) {
      index = sections.indexWhere((s) => s.id == widget.activeSectionId);
    } else if (sectionsMeta != null && sectionsMeta.isNotEmpty) {
      index = sectionsMeta.indexWhere((s) => s.id == widget.activeSectionId);
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
    // Use full sections if available, otherwise use lightweight metadata
    final sections = widget.restController.visibleMenuSections;
    final sectionsMeta = widget.restController.menuSectionsMeta;

    List<_SectionItem> items = [];

    // Prefer full sections, fallback to metadata
    if (sections != null && sections.isNotEmpty) {
      items = sections.map((s) => _SectionItem(s.id!, s.name ?? '')).toList();
    } else if (sectionsMeta != null && sectionsMeta.isNotEmpty) {
      items = sectionsMeta.map((s) => _SectionItem(s.id!, s.name ?? '')).toList();
    }

    if (items.isEmpty) return const SizedBox();

    return ListView.separated(
      key: _listKey,
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault,
        vertical: 2,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isActive = item.id == widget.activeSectionId;
        return Center(
          child: KeyedSubtree(
            key: _itemKeys.length > index ? _itemKeys[index] : null,
            child: CustomInkWellWidget(
              radius: Dimensions.radiusDefault,
              onTap: () => widget.onSectionSelected(item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeLarge,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: isActive
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                      : Theme.of(context).disabledColor.withValues(alpha: 0.1),
                ),
                child: Text(
                  item.name,
                  style: (isActive ? robotoBold : robotoMedium).copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
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

// Helper class for section items
class _SectionItem {
  final int id;
  final String name;
  _SectionItem(this.id, this.name);
}
