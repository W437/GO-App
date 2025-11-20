import 'dart:ui';

import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/footer_view_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/paginated_list_view_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/product/product_view_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/bottom_cart_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/menu_drawer_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_horizontal_product_card.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_app_bar_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_details_section_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_info_section_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_screen_shimmer_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_sticky_header_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
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
  final Map<int, GlobalKey> _categorySectionKeys = {};
  int? _activeCategoryId;

  static const double _categoryBarHeight = 50.0; // lane height; chips are slightly shorter

  @override
  void initState() {
    super.initState();

    scrollController.addListener(_onScroll);
    _initDataCall();
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
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

  void _onScroll() {
    if(!scrollController.hasClients) return;
    
    // Logic to detect active category based on scroll position
    // We iterate through keys and check which one is at the top
    final double headerLimit = _categoryBarHeight + 120; // Adjusted for new header
    for (var entry in _categorySectionKeys.entries) {
      final key = entry.value;
      final context = key.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        // Check if the section is near the top (accounting for header height)
        if (position.dy >= 0 && position.dy <= headerLimit) {
          if (_activeCategoryId != entry.key) {
            setState(() {
              _activeCategoryId = entry.key;
            });
          }
          break;
        }
      }
    }
  }

  void _handleCategoryTap(int categoryId) {
    setState(() {
      _activeCategoryId = categoryId;
    });
    final key = _categorySectionKeys[categoryId];
    if(key?.currentContext != null && scrollController.hasClients) {
      final box = key!.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      final double targetOffset = (scrollController.offset + position.dy) - (_categoryBarHeight + 50);
      final double clampedTarget = targetOffset.clamp(0, scrollController.position.maxScrollExtent).toDouble();

      scrollController.animateTo(
        clampedTarget,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Map<int, List<Product>> _groupProductsByCategory(List<Product>? products) {
    final Map<int, List<Product>> categorized = {};
    if(products == null) {
      return categorized;
    }
    for (final product in products) {
      final Set<int> ids = {};
      if(product.categoryIds != null && product.categoryIds!.isNotEmpty) {
        for (final cat in product.categoryIds!) {
          final id = int.tryParse(cat.id ?? '');
          if(id != null) {
            ids.add(id);
          }
        }
      }
      if(ids.isEmpty && product.categoryId != null) {
        ids.add(product.categoryId!);
      }
      for (final id in ids) {
        categorized.putIfAbsent(id, () => []);
        categorized[id]!.add(product);
      }
    }
    return categorized;
  }

  List<Widget> _buildMenuSections(BuildContext context, RestaurantController restController) {
    final sections = <Widget>[];
    final categories = restController.categoryList ?? [];
    if(restController.restaurantProducts == null) {
      sections.add(
        SizedBox(
          height: 220,
          child: Center(
            child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
          ),
        ),
      );
      return sections;
    }
    if(categories.isEmpty) {
      return sections;
    }
    final groupedProducts = _groupProductsByCategory(restController.restaurantProducts);
    
    for (final category in categories) {
      if(category.id == null) continue;
      final products = groupedProducts[category.id] ?? [];
      if(products.isEmpty) {
        continue;
      }
      
      _categorySectionKeys.putIfAbsent(category.id!, () => GlobalKey());
      _activeCategoryId ??= category.id;

      sections.add(
        Container(
          key: _categorySectionKeys[category.id!],
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Text(
                  category.name ?? '',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              
              // Horizontal List of Products
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault, bottom: 5),
                      child: RestaurantHorizontalProductCard(
                        product: products[index],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if(sections.isEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge),
          child: Center(
            child: Text(
              'no_items_found'.tr,
              style: robotoMedium.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
        ),
      );
    }
    return sections;
  }

  Widget _buildSearchResults(RestaurantController restController) {
    return PaginatedListViewWidget(
      scrollController: scrollController,
      onPaginate: (int? offset) {
        if(restController.isSearching) {
          restController.getRestaurantSearchProductList(
            restController.searchText,
            Get.find<RestaurantController>().restaurant!.id.toString(),
            offset!,
            restController.type,
          );
        }
      },
      totalSize: restController.restaurantSearchProductModel?.totalSize,
      offset: restController.restaurantSearchProductModel?.offset,
      productView: ProductViewWidget(
        isRestaurant: false,
        restaurants: null,
        products: restController.restaurantSearchProductModel?.products,
        inRestaurantPage: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      appBar: isDesktop ? WebMenuBar(fromDineIn: widget.fromDineIn) : null,

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
            final bool hasData = restController.restaurant != null && restController.restaurant!.name != null && categoryController.categoryList != null;
            
            if(!hasData) {
              return const RestaurantScreenShimmerWidget();
            }
            
            final Restaurant activeRestaurant = restaurant ?? restController.restaurant!;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: scrollController,
                    clipBehavior: Clip.none, // Allow logo to overflow
                    slivers: [
                      // Cover Image & App Bar (Pinned SliverAppBar)
                      RestaurantInfoSectionWidget(
                        restaurant: activeRestaurant,
                        restController: restController,
                        hasCoupon: hasCoupon,
                      ),

                      // Restaurant Details (Overlaps the cover image)
                      RestaurantDetailsSectionWidget(
                        restaurant: activeRestaurant,
                        restController: restController,
                      ),

                  // Sticky categories (Secondary Pinned SliverAppBar)
                  SliverAppBar(
                    pinned: true,
                    primary: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Theme.of(context).cardColor,
                    elevation: 0,
                    toolbarHeight: _categoryBarHeight,
                    titleSpacing: 0,
                    title: SizedBox(
                      height: _categoryBarHeight,
                      child: RestaurantStickyHeaderWidget(
                        restController: restController,
                        activeCategoryId: _activeCategoryId,
                        onCategorySelected: _handleCategoryTap,
                      ),
                    ),
                  ),

                  // 3. Content (Menu or Search Results)
                  SliverToBoxAdapter(
                    child: FooterViewWidget(
                      child: Center(
                        child: Container(
                          width: Dimensions.webMaxWidth,
                          padding: const EdgeInsets.only(
                            top: Dimensions.paddingSizeLarge,
                            bottom: Dimensions.paddingSizeExtraLarge,
                          ),
                          child: restController.isSearching
                              ? _buildSearchResults(restController)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildMenuSections(context, restController),
                                ),
                        ),
                      ),
                    ),
                  ),
                    ],
                  ),
                  // Restaurant Logo - Top Layer (renders above all elements)
                  Positioned(
                    top: 190, // 250px (expanded height) - 60px (bottom offset)
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                          child: CustomImageWidget(
                            image: '${activeRestaurant.logoFullUrl}',
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            });
          });
        }),


      bottomNavigationBar: GetBuilder<CartController>(builder: (cartController) {
          return cartController.cartList.isNotEmpty && !isDesktop ? BottomCartWidget(restaurantId: cartController.cartList[0].product!.restaurantId!, fromDineIn: widget.fromDineIn) : const SizedBox();
        })
    );
  }
}


