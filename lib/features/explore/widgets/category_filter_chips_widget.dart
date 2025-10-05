import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class CategoryFilterChipsWidget extends StatelessWidget {
  final ExploreController exploreController;

  const CategoryFilterChipsWidget({
    super.key,
    required this.exploreController,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        if (categoryController.categoryList == null ||
            categoryController.categoryList!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeDefault,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: GetBuilder<ExploreController>(
              builder: (controller) {
                return Row(
                  children: [
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
                );
              },
            ),
          ),
        );
      },
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
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
