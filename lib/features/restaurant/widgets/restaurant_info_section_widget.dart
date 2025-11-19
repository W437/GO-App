import 'package:godelivery_user/common/widgets/adaptive/custom_favourite_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/common/widgets/shared/layout/customizable_space_bar_widget.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marquee/marquee.dart';

class RestaurantInfoSectionWidget extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantController restController;
  final bool hasCoupon;
  final TextEditingController searchController;
  const RestaurantInfoSectionWidget({
    super.key,
    required this.restaurant,
    required this.restController,
    required this.hasCoupon,
    required this.searchController,
  });


  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    void submitSearch(String query) {
      final text = query.trim();
      if(text.isEmpty) return;
      restController.getRestaurantSearchProductList(
        text,
        restController.restaurant!.id.toString(),
        1,
        restController.type,
      );
    }

    void clearSearch() {
      if(searchController.text.isEmpty) return;
      searchController.clear();
      if(restController.isSearching) {
        restController.changeSearchStatus();
      }
      restController.initSearchData();
      restController.getRestaurantProductList(restController.restaurant!.id, 1, restController.type, true);
    }

    return SliverAppBar(
      expandedHeight: 250, // Reduced height as info is now separate
      toolbarHeight: 60,
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: Theme.of(context).cardColor, // Match theme
      leading: const SizedBox(),
      leadingWidth: 0,
      actions: const [],
      
      // Top Actions Bar (Pinned)
      title: Row(
        children: [
          CircularBackButtonWidget(
            showText: false,
            backgroundColor: Colors.black.withValues(alpha: 0.5),
            iconColor: Colors.white,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          
          // Search Pill
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: submitSearch,
                textAlignVertical: TextAlignVertical.center,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Colors.white70,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  prefixIcon: Icon(Icons.search, color: Colors.white70, size: 24),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Favourite Button
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: GetBuilder<FavouriteController>(builder: (favouriteController) {
                bool isWished = favouriteController.wishRestIdList.contains(restaurant.id);
                return CustomFavouriteWidget(
                  restaurant: restaurant,
                  restaurantId: restaurant.id,
                  isRestaurant: true,
                  isWished: isWished,
                  size: 20,
                );
              }),
            ),
          ),
        ],
      ),
      centerTitle: false,
      titleSpacing: Dimensions.paddingSizeDefault,

      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        centerTitle: true,
        expandedTitleScale: 1.1,
        background: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BlurhashImageWidget(
                    imageUrl: '${restaurant.coverPhotoFullUrl}',
                    blurhash: restaurant.coverPhotoBlurhash,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Logo (Moved here to be part of the header and fade on scroll)
            Positioned(
              bottom: -25, // Overlap the bottom edge slightly
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: BlurhashImageWidget(
                        imageUrl: restaurant.logoFullUrl ?? '',
                        blurhash: restaurant.logoBlurhash,
                        fit: BoxFit.cover,
                      ),
                    ),
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

