import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
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
              // Sort Options
              _buildSortChip(
                context: context,
                label: controller.currentSortOption.displayName,
                icon: Icons.sort,
                isActive: true,
                onTap: () => _showSortOptions(context),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              // Quick Filters
              _buildFilterChip(
                context: context,
                label: 'open_now'.tr,
                isActive: controller.filterOpenNow,
                onTap: () => controller.toggleOpenNowFilter(),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              _buildFilterChip(
                context: context,
                label: 'free_delivery'.tr,
                isActive: controller.filterFreeDelivery,
                onTap: () => controller.toggleFreeDeliveryFilter(),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              _buildFilterChip(
                context: context,
                label: 'top_rated'.tr,
                isActive: controller.filterTopRated,
                onTap: () => controller.toggleTopRatedFilter(),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              _buildFilterChip(
                context: context,
                label: 'fast_delivery'.tr,
                icon: Icons.speed,
                isActive: controller.filterFastDelivery,
                onTap: () => controller.toggleFastDeliveryFilter(),
              ),

              // Active Filters Summary
              if (controller.activeFilterCount > 0) ...[
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _buildFilterChip(
                  context: context,
                  label: 'clear_all'.tr,
                  icon: Icons.clear,
                  isActive: false,
                  onTap: () => controller.clearAllFilters(),
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
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
  }) {
    final backgroundColor = isDestructive
        ? Colors.red.withValues(alpha: 0.1)
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
                ? Colors.red.withValues(alpha: 0.3)
                : isActive
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
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
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Text(
                  'sort_by'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
              ),

              // Sort Options
              ...SortOption.values.map((option) {
                final isSelected = exploreController.currentSortOption == option;
                return ListTile(
                  leading: Icon(
                    option.icon,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).disabledColor,
                  ),
                  title: Text(
                    option.displayName,
                    style: robotoMedium.copyWith(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () {
                    exploreController.setSortOption(option);
                    Navigator.pop(context);
                  },
                );
              }).toList(),

              const SizedBox(height: Dimensions.paddingSizeDefault),
            ],
          ),
        ),
      ),
    );
  }
}