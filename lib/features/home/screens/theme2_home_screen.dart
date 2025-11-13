import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/home/screens/home_screen.dart';
import 'package:godelivery_user/features/home/widgets/bad_weather_widget.dart';
import 'package:godelivery_user/features/home/widgets/banner_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/best_review_item_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/cuisine_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/new_on_go_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/order_again_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/popular_foods_nearby_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/popular_restaurants_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/simple_app_bar_widget.dart';
import 'package:godelivery_user/features/home/widgets/simple_search_location_widget.dart';
import 'package:godelivery_user/features/home/widgets/today_trends_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/what_on_your_mind_view_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/splash/domain/models/config_model.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/story/widgets/story_strip_widget.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/product_view_widget.dart';
import 'package:godelivery_user/common/widgets/paginated_list_view_widget.dart';

class Theme2HomeScreen extends StatelessWidget {
  final ScrollController scrollController;
  const Theme2HomeScreen({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    ConfigModel configModel = Get.find<SplashController>().configModel!;
    bool isLogin = Get.find<AuthController>().isLoggedIn();

    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Simple App Bar (non-scrollable, always visible)
        SliverToBoxAdapter(
          child: const SimpleAppBarWidget(),
        ),

        // Search and Location (pinned below app bar)
        SliverToBoxAdapter(
          child: const SimpleSearchLocationWidget(),
        ),

        // Main Content
        SliverToBoxAdapter(
          child: Center(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BannerViewWidget(),
                  const BadWeatherWidget(),
                  const StoryStripWidget(),
                  const WhatOnYourMindViewWidget(),
                  const TodayTrendsViewWidget(),
                  const CuisineViewWidget(),

                  configModel.mostReviewedFoods == 1
                      ? const BestReviewItemViewWidget(isPopular: false)
                      : const SizedBox(),

                  isLogin ? const OrderAgainViewWidget() : const SizedBox(),

                  configModel.popularRestaurant == 1
                      ? const PopularRestaurantsViewWidget()
                      : const SizedBox(),

                  configModel.popularFood == 1
                      ? const PopularFoodNearbyViewWidget()
                      : const SizedBox(),

                  configModel.newRestaurant == 1
                      ? const NewOnGOViewWidget(isLatest: true)
                      : const SizedBox(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeDefault,
                      Dimensions.paddingSizeDefault,
                      Dimensions.paddingSizeDefault,
                      Dimensions.paddingSizeSmall,
                    ),
                    child: Text(
                      'all_restaurants'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                  ),

                  GetBuilder<RestaurantController>(
                    builder: (restaurantController) {
                      return PaginatedListViewWidget(
                        scrollController: scrollController,
                        totalSize: restaurantController.restaurantModel?.totalSize,
                        offset: restaurantController.restaurantModel?.offset,
                        onPaginate: (int? offset) async =>
                            await restaurantController.getRestaurantList(offset!, false),
                        productView: ProductViewWidget(
                          isRestaurant: true,
                          products: null,
                          restaurants: restaurantController.restaurantModel?.restaurants,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.isDesktop(context)
                                ? Dimensions.paddingSizeExtraSmall
                                : Dimensions.paddingSizeSmall,
                            vertical: ResponsiveHelper.isDesktop(context)
                                ? Dimensions.paddingSizeExtraSmall
                                : 0,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
