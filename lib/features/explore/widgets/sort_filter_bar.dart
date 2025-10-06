import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/advanced_filter_sheet.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class SortFilterBar extends StatelessWidget {
  final ExploreController exploreController;

  const SortFilterBar({
    super.key,
    required this.exploreController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: GetBuilder<ExploreController>(
        builder: (controller) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            children: [
              // Sort & Filter Button
              _buildSortChip(
                context: context,
                label: 'sort_and_filter'.tr,
                icon: Icons.tune,
                isActive: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AdvancedFilterSheet(),
                  );
                },
                badge: controller.minRatingFilter > 0 ||
                       controller.maxDeliveryFeeFilter < 20 ||
                       controller.currentSortOption != SortOption.distance
                    ? '•'
                    : null,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              // Quick Filters
              _buildFilterChip(
                context: context,
                label: 'open_now'.tr,
                isActive: controller.filterOpenNow,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.toggleOpenNowFilter();
                },
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              _buildFilterChip(
                context: context,
                label: 'free_delivery'.tr,
                isActive: controller.filterFreeDelivery,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.toggleFreeDeliveryFilter();
                },
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              _buildFilterChip(
                context: context,
                label: 'top_rated'.tr,
                isActive: controller.filterTopRated,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.toggleTopRatedFilter();
                },
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              _buildFilterChip(
                context: context,
                label: 'fast_delivery'.tr,
                icon: Icons.speed,
                isActive: controller.filterFastDelivery,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.toggleFastDeliveryFilter();
                },
              ),

              // Active Filters Summary
              if (controller.activeFilterCount > 0) ...[
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _buildFilterChip(
                  context: context,
                  label: 'clear_all'.tr,
                  icon: Icons.clear,
                  isActive: false,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.clearAllFilters();
                  },
                  isDestructive: true,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSortChip({
    required BuildContext context,
    required String label,
    IconData? icon,
    required bool isActive,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: robotoMedium.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge,
                  style: robotoBold.copyWith(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    IconData? icon,
    required bool isActive,
    required VoidCallback onTap,
    bool isDestructive = false,
    String? badge,
  }) {
    final backgroundColor = isDestructive
        ? Colors.red.withOpacity(0.1)
        : isActive
            ? Theme.of(context).primaryColor
            : Theme.of(context).cardColor;

    final textColor = isDestructive
        ? Colors.red
        : isActive
            ? Colors.white
            : Theme.of(context).textTheme.bodyMedium!.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.3)
                : isActive
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: textColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: robotoMedium.copyWith(
                    color: textColor,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: robotoBold.copyWith(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}