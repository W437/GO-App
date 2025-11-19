import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/restaurant/widgets/coupon_view_widget.dart';
import 'package:godelivery_user/common/widgets/shared/layout/customizable_space_bar_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/info_view_widget.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marquee/marquee.dart';

class RestaurantInfoSectionWidget extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantController restController;
  final bool hasCoupon;
  const RestaurantInfoSectionWidget({super.key, required this.restaurant, required this.restController, required this.hasCoupon});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    final double xyz = MediaQuery.of(context).size.width-1170;
    final double realSpaceNeeded = xyz/2;

    return SliverAppBar(
      expandedHeight: isDesktop ? 350 : 280,
      toolbarHeight: isDesktop ? 150 : 70,
      pinned: true, floating: false, elevation: 0,
      backgroundColor: Theme.of(context).cardColor,
      leading: const SizedBox(),
      leadingWidth: 0,

      flexibleSpace: GetBuilder<CouponController>(
        builder: (couponController) {
          bool hasCoupons = couponController.couponList != null && couponController.couponList!.isNotEmpty;
          return Container(
            margin: isDesktop ? EdgeInsets.symmetric(horizontal: realSpaceNeeded) : EdgeInsets.zero,
            child: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              centerTitle: true,
              expandedTitleScale: isDesktop ? 1 : 1.0,
              title: CustomizableSpaceBarWidget(
                builder: (context, scrollingRate) {
                  return !isDesktop ? Stack(
                    children: [
                      // Floating back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: Dimensions.paddingSizeDefault,
                        child: CircularBackButtonWidget(
                          showText: true,
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ) : Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      height: restaurant.announcementActive! ? 200 : 160,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 1))],
                      ),
                      margin: EdgeInsets.symmetric(horizontal: hasCoupons ? Dimensions.paddingSizeDefault : 200, vertical: Dimensions.paddingSizeSmall),
                      child: Column(
                        children: [
                          restaurant.announcementActive != null && restaurant.announcementActive! && restaurant.announcementMessage != null ? Container(
                            height: 40 - (scrollingRate * 40),
                            padding: EdgeInsets.only(
                              left: Get.find<LocalizationController>().isLtr ? 250 : 20,
                              right: Get.find<LocalizationController>().isLtr ? 20 : 250,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusDefault), topRight: Radius.circular(Dimensions.radiusDefault)),
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Image.asset(Images.announcement, height: 26, width: 26),
                              const SizedBox(width: Dimensions.paddingSizeSmall),
                              Flexible(
                                child: Marquee(
                                  text: restaurant.announcementMessage!,
                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).cardColor),
                                  blankSpace: 20.0,
                                  velocity: 100.0,
                                  accelerationDuration: const Duration(seconds: 5),
                                  decelerationDuration: const Duration(milliseconds: 500),
                                  accelerationCurve: Curves.linear,
                                  decelerationCurve: Curves.easeOut,
                                ),
                              ),
                            ]),
                          ) : const SizedBox(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Row(children: [
                                  SizedBox(width: 250 /*(context.width * 0.17)*/ - (scrollingRate * 90)),
                                  Expanded(child: InfoViewWidget(restaurant: restaurant, restController: restController, scrollingRate: scrollingRate)),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                  hasCoupons ? Expanded(child: CouponViewWidget(scrollingRate: scrollingRate)) : const SizedBox(),
                                ]),
                                Positioned(left: Get.find<LocalizationController>().isLtr ? 30 : null, right: Get.find<LocalizationController>().isLtr ? null : 30, top: - 80 + (scrollingRate * 77), child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).cardColor,
                                    border: Border.all(color: Theme.of(context).primaryColor, width: 0.2),
                                    boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 10)]
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Stack(children: [
                                      SizedBox(
                                        height: 200 - (scrollingRate * 90),
                                        width: 200 - (scrollingRate * 90),
                                        child: BlurhashImageWidget(
                                          imageUrl: '${restaurant.logoFullUrl}',
                                          blurhash: restaurant.logoBlurhash,
                                          fit: BoxFit.cover,
                                          borderRadius: BorderRadius.circular(500),
                                        ),
                                      ),
                                      restController.isRestaurantOpenNow(restaurant.active!, restaurant.schedules) ? const SizedBox() : Positioned(
                                        left: 0, right: 0, bottom: 0,
                                        child: Container(
                                          height: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusSmall)),
                                            color: Colors.black.withValues(alpha: 0.6),
                                          ),
                                          child: Text(
                                            'closed_now'.tr, textAlign: TextAlign.center,
                                            style: robotoRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                                          ),
                                        ),
                                      ),
                                    ]),
                                ),
                              ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              background: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Hero Image
                  Container(
                    height: isDesktop ? 350 : 280,
                    width: double.infinity,
                    child: BlurhashImageWidget(
                      imageUrl: '${restaurant.coverPhotoFullUrl}',
                      blurhash: restaurant.coverPhotoBlurhash,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient Overlay for text readability
                  Container(
                    height: isDesktop ? 350 : 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Restaurant Name Overlay
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Text(
                      restaurant.name ?? '',
                      style: robotoBold.copyWith(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
      actions: const [SizedBox()],
    );
  }
}