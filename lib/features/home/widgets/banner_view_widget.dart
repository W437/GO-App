import 'package:carousel_slider/carousel_slider.dart';
import 'package:godelivery_user/features/home/controllers/home_controller.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/product/domain/models/basic_campaign_model.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/custom_image_widget.dart';
import 'package:godelivery_user/common/widgets/product_bottom_sheet_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class BannerViewWidget extends StatelessWidget {
  const BannerViewWidget({super.key});

  @override
  Widget build(BuildContext context) {

    return GetBuilder<HomeController>(builder: (homeController) {
      return (homeController.bannerImageList != null && homeController.bannerImageList!.isEmpty) ? const SizedBox() : Container(
        width: MediaQuery.of(context).size.width,
        height: GetPlatform.isDesktop ? 500 : 185,
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        child: homeController.bannerImageList != null ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CarouselSlider.builder(
                options: CarouselOptions(
                  viewportFraction: 1.0,
                  enlargeFactor: 0.0,
                  autoPlay: true,
                  enlargeCenterPage: false,
                  disableCenter: false,
                  padEnds: true,
                  autoPlayInterval: const Duration(seconds: 7),
                  autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                  autoPlayCurve: Curves.easeInOutCubic,
                  onPageChanged: (index, reason) {
                    homeController.setCurrentIndex(index, true);
                  },
                ),
                itemCount: homeController.bannerImageList!.isEmpty ? 1 : homeController.bannerImageList!.length,
                itemBuilder: (context, index, _) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            spreadRadius: 0,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if(homeController.bannerDataList![index] is Product) {
                              Product? product = homeController.bannerDataList![index];
                              ResponsiveHelper.isMobile(context) ? showModalBottomSheet(
                                context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                                builder: (con) => ProductBottomSheetWidget(product: product),
                              ) : showDialog(context: context, builder: (con) => Dialog(
                                  child: ProductBottomSheetWidget(product: product)),
                              );
                            }else if(homeController.bannerDataList![index] is Restaurant) {
                              Restaurant restaurant = homeController.bannerDataList![index];
                              Get.toNamed(
                                RouteHelper.getRestaurantRoute(restaurant.id),
                                arguments: RestaurantScreen(restaurant: restaurant),
                              );
                            }else if(homeController.bannerDataList![index] is BasicCampaignModel) {
                              BasicCampaignModel campaign = homeController.bannerDataList![index];
                              Get.toNamed(RouteHelper.getBasicCampaignRoute(campaign));
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GetBuilder<SplashController>(builder: (splashController) {
                              return CustomImageWidget(
                                image: '${homeController.bannerImageList![index]}',
                                fit: BoxFit.cover,
                              );
                            },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: homeController.bannerImageList!.map((bnr) {
                int index = homeController.bannerImageList!.indexOf(bnr);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 8,
                  width: index == homeController.currentIndex ? 24 : 8,
                  decoration: BoxDecoration(
                    color: index == homeController.currentIndex
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
          ],
        ) : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).cardColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Shimmer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).shadowColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

}
