import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';

class RestaurantAppBarWidget extends StatefulWidget {
  final RestaurantController restController;
  final double backgroundOpacity;
  const RestaurantAppBarWidget({
    super.key,
    required this.restController,
    this.backgroundOpacity = 0,
  });

  @override
  State<RestaurantAppBarWidget> createState() => _RestaurantAppBarWidgetState();
}

class _RestaurantAppBarWidgetState extends State<RestaurantAppBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
          
          // Search Pill
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (String query) {
                        if(widget.restController.isSearching) {
                          widget.restController.changeSearchStatus();
                        }
                        widget.restController.initSearchData();
                        widget.restController.getRestaurantProductList(widget.restController.restaurant!.id, 1, widget.restController.type, true);
                      },
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
                        prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 24),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if(_searchController.text.isNotEmpty)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.clear, color: Colors.white, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        widget.restController.initSearchData();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Favorite Button
          GetBuilder<FavouriteController>(builder: (favouriteController) {
            bool isWished = favouriteController.wishRestIdList.contains(widget.restController.restaurant!.id);
            return CustomInkWellWidget(
              onTap: () {
                if(AuthHelper.isLoggedIn()) {
                  isWished ? favouriteController.removeFromFavouriteList(widget.restController.restaurant!.id, true)
                      : favouriteController.addToFavouriteList(null, widget.restController.restaurant!.id, true);
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
