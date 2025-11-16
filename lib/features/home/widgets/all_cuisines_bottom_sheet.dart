import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/cuisine/controllers/cuisine_controller.dart';
import 'package:godelivery_user/features/home/widgets/cuisine_card_widget.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class AllCuisinesBottomSheet extends StatelessWidget {
  const AllCuisinesBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'cuisines'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),

          // Cuisines Grid
          Flexible(
            child: GetBuilder<CuisineController>(
              builder: (cuisineController) {
                return cuisineController.cuisineModel != null
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeLarge,
                          vertical: Dimensions.paddingSizeSmall,
                        ),
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: ResponsiveHelper.isMobile(context) ? 4 : 6,
                          mainAxisSpacing: Dimensions.paddingSizeLarge,
                          crossAxisSpacing: Dimensions.paddingSizeLarge,
                          childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.65 : 0.85,
                        ),
                        itemCount: cuisineController.cuisineModel!.cuisines!.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              Get.back();
                              Get.toNamed(RouteHelper.getCuisineRestaurantRoute(
                                cuisineController.cuisineModel!.cuisines![index].id,
                                cuisineController.cuisineModel!.cuisines![index].name,
                              ));
                            },
                            child: CuisineCardWidget(
                              image: cuisineController.cuisineModel!.cuisines![index].imageFullUrl ?? '',
                              name: cuisineController.cuisineModel!.cuisines![index].name ?? '',
                              fromCuisinesPage: true,
                            ),
                          );
                        },
                      )
                    : const Center(child: CircularProgressIndicator());
              },
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeDefault),
        ],
      ),
    );
  }
}
