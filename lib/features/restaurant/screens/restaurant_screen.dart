import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/home/widgets/arrow_icon_button_widget.dart';
import 'package:godelivery_user/features/home/widgets/item_card_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_info_section_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_screen_shimmer_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_sticky_header_widget.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/mobile/bottom_cart_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/footer_view_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/menu_drawer_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/paginated_list_view_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/product/product_view_widget.dart';
import 'package:godelivery_user/common/widgets/web/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RestaurantScreen extends StatefulWidget {
  final Restaurant? restaurant;
  final String slug;
  final bool fromDineIn;
  const RestaurantScreen({super.key, required this.restaurant, this.slug = '', this.fromDineIn = false});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _initDataCall();
  }

  @override
  void dispose() {
    super.dispose();

    scrollController.dispose();
  }

  Future<void> _initDataCall() async {
    if(Get.find<RestaurantController>().isSearching) {
      Get.find<RestaurantController>().changeSearchStatus(isUpdate: false);
    }
    await Get.find<RestaurantController>().getRestaurantDetails(Restaurant(id: widget.restaurant!.id), slug: widget.slug);
    if(Get.find<CategoryController>().categoryList == null) {
      Get.find<CategoryController>().getCategoryList(true);
    }
    Get.find<CouponController>().getRestaurantCouponList(restaurantId: widget.restaurant!.id ?? Get.find<RestaurantController>().restaurant!.id!);
    Get.find<RestaurantController>().getRestaurantRecommendedItemList(widget.restaurant!.id ?? Get.find<RestaurantController>().restaurant!.id!, false);
    Get.find<RestaurantController>().getRestaurantProductList(widget.restaurant!.id ?? Get.find<RestaurantController>().restaurant!.id!, 1, 'all', false);
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      appBar: isDesktop ? WebMenuBar(fromDineIn: widget.fromDineIn) : null,
      endDrawer: const MenuDrawerWidget(), endDrawerEnableOpenDragGesture: false,
      backgroundColor: Theme.of(context).cardColor,
      body: GetBuilder<RestaurantController>(builder: (restController) {
        return GetBuilder<CouponController>(builder: (couponController) {
          return GetBuilder<CategoryController>(builder: (categoryController) {
            Restaurant? restaurant;
            if (restController.restaurant != null && restController.restaurant!.name != null &&
                categoryController.categoryList != null) {
              restaurant = restController.restaurant;
            }
            restController.setCategoryList();
            bool hasCoupon = (couponController.couponList!= null && couponController.couponList!.isNotEmpty);

            return (restController.restaurant != null && restController.restaurant!.name != null && categoryController.categoryList != null) ? CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: scrollController,
              slivers: [

                RestaurantInfoSectionWidget(restaurant: restaurant!, restController: restController, hasCoupon: hasCoupon),

                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: Center(
                      child: Container(
                        width: Dimensions.webMaxWidth,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                Dimensions.paddingSizeLarge,
                                Dimensions.paddingSizeLarge,
                                Dimensions.paddingSizeLarge,
                                Dimensions.paddingSizeDefault,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (restaurant.cuisineNames != null && restaurant.cuisineNames!.isNotEmpty)
                                    Text(
                                      restaurant.cuisineNames!.map((c) => c.name).join(', '),
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        restaurant.avgRating!.toStringAsFixed(1),
                                        style: robotoMedium.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          color: Theme.of(context).textTheme.bodyLarge!.color,
                                        ),
                                      ),
                                      Text(
                                        ' (${restaurant.ratingCount ?? 0}+)',
                                        style: robotoRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                      const SizedBox(width: Dimensions.paddingSizeDefault),
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Icon(
                                          Icons.receipt_outlined,
                                          color: Theme.of(context).hintColor,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        restaurant.deliveryFee != null ? '${PriceConverter.convertPrice(restaurant.deliveryFee)} ${'fee'.tr}' : 'Free',
                                        style: robotoMedium.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          color: Theme.of(context).textTheme.bodyLarge!.color,
                                        ),
                                      ),
                                      const SizedBox(width: Dimensions.paddingSizeDefault),
                                      Icon(Icons.access_time_outlined, color: Theme.of(context).hintColor, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        restaurant.deliveryTime?.replaceAll('-min', ' min') ?? '30-40 min',
                                        style: robotoMedium.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          color: Theme.of(context).textTheme.bodyLarge!.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                Dimensions.paddingSizeLarge,
                                Dimensions.paddingSizeSmall,
                                Dimensions.paddingSizeLarge,
                                Dimensions.paddingSizeLarge,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (restaurant.discount != null)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            restaurant.discount!.discountType == 'percent'
                                                ? '${restaurant.discount!.discount}% ${'off'.tr}'
                                                : '${PriceConverter.convertPrice(restaurant.discount!.discount)} ${'off'.tr}',
                                            style: robotoMedium.copyWith(
                                              fontSize: Dimensions.fontSizeLarge,
                                              color: Theme.of(context).cardColor,
                                            ),
                                          ),
                                          Text(
                                            restaurant.discount!.discountType == 'percent'
                                                ? '${'enjoy'.tr} ${restaurant.discount!.discount}% ${'off_on_all_categories'.tr}'
                                                : '${'enjoy'.tr} ${PriceConverter.convertPrice(restaurant.discount!.discount)} ${'off_on_all_categories'.tr}',
                                            style: robotoMedium.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              color: Theme.of(context).cardColor,
                                            ),
                                          ),
                                          SizedBox(
                                            height: (restaurant.discount!.minPurchase != 0 || restaurant.discount!.maxDiscount != 0) ? 5 : 0,
                                          ),
                                          if (restaurant.discount!.minPurchase != 0)
                                            Text(
                                              '[ ${'minimum_purchase'.tr}: ${PriceConverter.convertPrice(restaurant.discount!.minPurchase)} ]',
                                              style: robotoRegular.copyWith(
                                                fontSize: Dimensions.fontSizeExtraSmall,
                                                color: Theme.of(context).cardColor,
                                              ),
                                            ),
                                          if (restaurant.discount!.maxDiscount != 0)
                                            Text(
                                              '[ ${'maximum_discount'.tr}: ${PriceConverter.convertPrice(restaurant.discount!.maxDiscount)} ]',
                                              style: robotoRegular.copyWith(
                                                fontSize: Dimensions.fontSizeExtraSmall,
                                                color: Theme.of(context).cardColor,
                                              ),
                                            ),
                                          Text(
                                            '[ ${'daily_time'.tr}: ${DateConverter.convertTimeToTime(restaurant.discount!.startTime!)} - ${DateConverter.convertTimeToTime(restaurant.discount!.endTime!)} ]',
                                            style: robotoRegular.copyWith(
                                              fontSize: Dimensions.fontSizeExtraSmall,
                                              color: Theme.of(context).cardColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (ResponsiveHelper.isMobile(context) && restaurant.announcementActive! && restaurant.announcementMessage != null)
                                    Container(
                                      width: double.infinity,
                                      decoration: const BoxDecoration(color: Colors.green),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: Dimensions.paddingSizeSmall,
                                        horizontal: Dimensions.paddingSizeLarge,
                                      ),
                                      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                                      child: Row(
                                        children: [
                                          Image.asset(Images.announcement, height: 26, width: 26),
                                          const SizedBox(width: Dimensions.paddingSizeSmall),
                                          Expanded(
                                            child: Text(
                                              restaurant.announcementMessage ?? '',
                                              style: robotoMedium.copyWith(
                                                fontSize: Dimensions.fontSizeSmall,
                                                color: Theme.of(context).cardColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (restController.recommendedProductModel != null &&
                                      restController.recommendedProductModel!.products!.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: Dimensions.paddingSizeLarge,
                                              left: Dimensions.paddingSizeLarge,
                                              bottom: Dimensions.paddingSizeSmall,
                                              right: Dimensions.paddingSizeLarge,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'recommend_for_you'.tr,
                                                        style: robotoMedium.copyWith(
                                                          fontSize: Dimensions.fontSizeLarge,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                                      Text(
                                                        'here_is_what_you_might_like_to_test'.tr,
                                                        style: robotoRegular.copyWith(
                                                          fontSize: Dimensions.fontSizeSmall,
                                                          color: Theme.of(context).disabledColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                ArrowIconButtonWidget(
                                                  onTap: () => Get.toNamed(
                                                    RouteHelper.getPopularFoodRoute(
                                                      false,
                                                      fromIsRestaurantFood: true,
                                                      restaurantId: widget.restaurant!.id ??
                                                          Get.find<RestaurantController>().restaurant!.id!,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: ResponsiveHelper.isDesktop(context) ? 307 : 305,
                                            width: double.infinity,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              scrollDirection: Axis.horizontal,
                                              itemCount: restController.recommendedProductModel!.products!.length,
                                              physics: const BouncingScrollPhysics(),
                                              padding: const EdgeInsets.only(
                                                top: Dimensions.paddingSizeExtraSmall,
                                                bottom: Dimensions.paddingSizeExtraSmall,
                                                right: Dimensions.paddingSizeDefault,
                                              ),
                                              itemBuilder: (context, index) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                                                  child: ItemCardWidget(
                                                    product: restController.recommendedProductModel!.products![index],
                                                    isBestItem: false,
                                                    isPopularNearbyItem: false,
                                                    width: ResponsiveHelper.isDesktop(context)
                                                        ? 200
                                                        : MediaQuery.of(context).size.width * 0.53,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: Dimensions.paddingSizeSmall),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                (restController.categoryList!.isNotEmpty) ? SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverDelegate(
                    height: 100,
                    child: Center(
                      child: Container(
                        width: Dimensions.webMaxWidth,
                        color: Theme.of(context).cardColor,
                        child: RestaurantStickyHeaderWidget(
                          restController: restController,
                          searchController: _searchController,
                        ),
                      ),
                    ),
                  ),
                ) : const SliverToBoxAdapter(child: SizedBox()),

                SliverToBoxAdapter(
                  child: FooterViewWidget(
                    child: Center(
                      child: Container(
                        width: Dimensions.webMaxWidth,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                        ),
                        child: PaginatedListViewWidget(
                          scrollController: scrollController,
                          onPaginate: (int? offset) {
                            if (restController.isSearching) {
                              restController.getRestaurantSearchProductList(
                                restController.searchText, Get.find<RestaurantController>().restaurant!.id.toString(), offset!, restController.type,
                              );
                            } else {
                              restController.getRestaurantProductList(Get.find<RestaurantController>().restaurant!.id, offset!, restController.type, false);
                            }
                          },
                          totalSize: restController.isSearching ? restController.restaurantSearchProductModel?.totalSize : restController.restaurantProducts != null ? restController.foodPageSize : null,
                          offset: restController.isSearching ? restController.restaurantSearchProductModel?.offset : restController.restaurantProducts != null ? restController.foodPageOffset : null,
                          productView: ProductViewWidget(
                            isRestaurant: false,
                            restaurants: null,
                            products: restController.isSearching ? restController.restaurantSearchProductModel?.products : restController.categoryList!.isNotEmpty ? restController.restaurantProducts : null,
                            inRestaurantPage: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ) : const RestaurantScreenShimmerWidget();
          });
        });
      }),

      bottomNavigationBar: GetBuilder<CartController>(builder: (cartController) {
          return cartController.cartList.isNotEmpty && !isDesktop ? BottomCartWidget(restaurantId: cartController.cartList[0].product!.restaurantId!, fromDineIn: widget.fromDineIn) : const SizedBox();
        })
    );
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;

  SliverDelegate({required this.child, this.height = 100});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height || oldDelegate.minExtent != height || child != oldDelegate.child;
  }
}

// class CategoryProduct {
//   CategoryModel category;
//   List<Product> products;
//   CategoryProduct(this.category, this.products);
// }
