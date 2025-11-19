import 'package:flutter/material.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class RestaurantStickyHeaderWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final categories = restController.categoryList ?? [];
    return Container(
      width: Dimensions.webMaxWidth,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault,
          ),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) {
            final category = categories[index];
            final bool isActive = category.id != null && category.id == activeCategoryId;
            return CustomInkWellWidget(
              radius: 20,
              onTap: category.id == null ? () {} : () => onCategorySelected(category.id!),
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
            );
          },
        ),
      ),
    );
  }
}
