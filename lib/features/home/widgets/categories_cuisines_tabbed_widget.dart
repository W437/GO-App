import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/cuisine/controllers/cuisine_controller.dart';
import 'package:godelivery_user/features/home/widgets/cuisine_card_widget.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class CategoriesCuisinesTabbedWidget extends StatefulWidget {
  const CategoriesCuisinesTabbedWidget({super.key});

  @override
  State<CategoriesCuisinesTabbedWidget> createState() => _CategoriesCuisinesTabbedWidgetState();
}

class _CategoriesCuisinesTabbedWidgetState extends State<CategoriesCuisinesTabbedWidget> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeExtraLarge,
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeExtraLarge,
            Dimensions.paddingSizeDefault,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'what_on_your_mind'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
              // Tab switcher
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
                child: Row(
                  children: [
                    _buildTab(
                      context: context,
                      label: 'categories'.tr,
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    _buildTab(
                      context: context,
                      label: 'cuisines'.tr,
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content with animated switcher
        SizedBox(
          height: ResponsiveHelper.isMobile(context) ? 120 : 170,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));

              return ClipRect(
                child: SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                ),
              );
            },
            child: _selectedTab == 0
                ? _buildCategoriesView(key: const ValueKey('categories'))
                : _buildCuisinesView(key: const ValueKey('cuisines')),
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).cardColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: isSelected
                ? Theme.of(context).textTheme.bodyLarge!.color
                : Theme.of(context).hintColor,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildCategoriesView({Key? key}) {
    return GetBuilder<CategoryController>(
      key: key,
      builder: (categoryController) {
        // Show shimmer while loading
        if (categoryController.categoryList == null) {
          return _buildShimmer();
        }
        // Show empty state if no categories
        if (categoryController.categoryList!.isEmpty) {
          return _buildEmptyState(context, 'No categories available', Icons.category_outlined);
        }
        // Show categories list
        return ListView.builder(
                key: const PageStorageKey('categories_list'),
                physics: ResponsiveHelper.isMobile(context)
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                itemCount: categoryController.categoryList!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: Dimensions.paddingSizeSmall,
                    right: Dimensions.paddingSizeDefault,
                  ),
                  child: Column(
                    children: [
                      CustomInkWellWidget(
                        onTap: () => Get.toNamed(RouteHelper.getCategoryProductRoute(
                          categoryController.categoryList![index].id,
                          categoryController.categoryList![index].name!,
                        )),
                        radius: Dimensions.radiusExtraLarge,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).primaryColor.withValues(alpha: 0.85),
                                Theme.of(context).primaryColor.withValues(alpha: 0.85),
                                Colors.white,
                                Colors.white,
                              ],
                              stops: const [0.0, 0.2, 0.65, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.5),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge - 3),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    const Color(0xFFE8E8E8),
                                  ],
                                  stops: const [0.65, 1.0],
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge - 3),
                                child: CustomImageWidget(
                                  image: '${categoryController.categoryList![index].imageFullUrl}',
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      SizedBox(
                        width: 80,
                        child: Text(
                          categoryController.categoryList![index].name!,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
      },
    );
  }

  Widget _buildCuisinesView({Key? key}) {
    return GetBuilder<CuisineController>(
      key: key,
      builder: (cuisineController) {
        // Show shimmer while loading
        if (cuisineController.cuisineModel == null) {
          return _buildShimmer();
        }
        // Show empty state if no cuisines
        if (cuisineController.cuisineModel!.cuisines == null ||
            cuisineController.cuisineModel!.cuisines!.isEmpty) {
          return _buildEmptyState(context, 'No cuisines available', Icons.restaurant_menu_outlined);
        }
        // Show cuisines list
        return ListView.builder(
                key: const PageStorageKey('cuisines_list'),
                physics: ResponsiveHelper.isMobile(context)
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                itemCount: cuisineController.cuisineModel!.cuisines!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(
                    right: Dimensions.paddingSizeDefault,
                    bottom: Dimensions.paddingSizeSmall,
                  ),
                  child: CustomInkWellWidget(
                    onTap: () => Get.toNamed(RouteHelper.getCuisineRestaurantRoute(
                      cuisineController.cuisineModel!.cuisines![index].id,
                      cuisineController.cuisineModel!.cuisines![index].name!,
                    )),
                    radius: Dimensions.radiusDefault,
                    child: CuisineCardWidget(
                      image: cuisineController.cuisineModel!.cuisines![index].imageFullUrl ?? '',
                      name: cuisineController.cuisineModel!.cuisines![index].name ?? '',
                    ),
                  ),
                );
              },
            );
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
      itemCount: 8,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(
            right: Dimensions.paddingSizeDefault,
            bottom: Dimensions.paddingSizeSmall,
          ),
          child: Column(
            children: [
              // Simple rounded square shimmer
              Shimmer(
                duration: const Duration(seconds: 2),
                child: Container(
                  width: ResponsiveHelper.isMobile(context) ? 70 : 90,
                  height: ResponsiveHelper.isMobile(context) ? 70 : 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              // Text shimmer
              Shimmer(
                duration: const Duration(seconds: 2),
                child: Container(
                  width: 50,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
      itemCount: 5,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(
            right: Dimensions.paddingSizeDefault,
            bottom: Dimensions.paddingSizeSmall,
          ),
          child: Column(
            children: [
              Container(
                width: ResponsiveHelper.isMobile(context) ? 70 : 90,
                height: ResponsiveHelper.isMobile(context) ? 70 : 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Container(
                width: 50,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.withOpacity(0.15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
