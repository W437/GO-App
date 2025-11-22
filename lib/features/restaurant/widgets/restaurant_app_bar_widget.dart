import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/common/widgets/shared/text/animated_text_transition.dart';

class RestaurantAppBarWidget extends StatefulWidget {
  final RestaurantController restController;
  final double backgroundOpacity;
  final dynamic restaurant;
  final double scrollOffset;
  const RestaurantAppBarWidget({
    super.key,
    required this.restController,
    this.backgroundOpacity = 0,
    this.restaurant,
    this.scrollOffset = 0.0,
  });

  @override
  State<RestaurantAppBarWidget> createState() => _RestaurantAppBarWidgetState();
}

class _RestaurantAppBarWidgetState extends State<RestaurantAppBarWidget> {
  String _cachedDisplayText = 'Search';

  @override
  Widget build(BuildContext context) {
    // Morph the display text at 400px scroll offset - only update cache when it actually changes
    final String newDisplayText = widget.scrollOffset > 400
        ? (widget.restaurant?.name ?? 'Search')
        : 'Search';

    if (newDisplayText != _cachedDisplayText) {
      _cachedDisplayText = newDisplayText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          // Back Button
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Get.back(),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Search Pill with morphing content
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.search,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedTextTransition(
                        value: _cachedDisplayText,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        textAlign: TextAlign.left,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Favorite Button
          GetBuilder<FavouriteController>(builder: (favouriteController) {
            final restaurantId = widget.restController.restaurant?.id ?? widget.restaurant?.id;
            if (restaurantId == null) return const SizedBox.shrink();

            bool isWished = favouriteController.wishRestIdList.contains(restaurantId);
            return CustomInkWellWidget(
              onTap: () {
                if(AuthHelper.isLoggedIn()) {
                  isWished ? favouriteController.removeFromFavouriteList(restaurantId, true)
                      : favouriteController.addToFavouriteList(null, restaurantId, true);
                }else {
                  showCustomSnackBar('you_are_not_logged_in'.tr);
                }
              },
              radius: 50,
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWished ? Icons.favorite : Icons.favorite_border,
                  color: isWished ? Theme.of(context).primaryColor : Colors.white,
                  size: 24,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
