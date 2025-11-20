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
  static const double _topActionBarHeight = 72.0;
  static const double _categoryBarHeight = 52.0; // lane height; chips are slightly shorter
  double _pinnedHeaderHeight = _topActionBarHeight + _categoryBarHeight;
  double _appBarOpacity = 0;
  double _fadeStart = 220;
  double _fadeEnd = 420;

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
    final double headerLimit = _pinnedHeaderHeight + 40;
    for (var entry in _categorySectionKeys.entries) {
      final key = entry.value;
      final context = key.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        // Check if the section is near the top (accounting for header height)
        // 150 is an approximation of the sticky header + app bar height
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

    // Fade in the top bar after scrolling past the cover/details
    double newOpacity = ((scrollController.offset - _fadeStart) / (_fadeEnd - _fadeStart)).clamp(0, 1);
    if ((newOpacity - _appBarOpacity).abs() > 0.02) {
      setState(() {
        _appBarOpacity = newOpacity;
      });
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
      final double targetOffset = (scrollController.offset + position.dy) - _pinnedHeaderHeight;
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
            final double screenHeight = MediaQuery.of(context).size.height;
            _fadeStart = screenHeight * 0.35;
            _fadeEnd = screenHeight * 0.7;

            _pinnedHeaderHeight = _topActionBarHeight + _categoryBarHeight;
            final double stickyHeaderHeight = _pinnedHeaderHeight;

            return Stack(
              children: [
                CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: scrollController,
                  slivers: [
                    // Cover Image (Unpinned, so it scrolls under the content)
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

                    // Sticky categories; top spacing shrinks as we scroll, bar is overlaid
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: SliverDelegate(
                        maxHeight: _topActionBarHeight + _categoryBarHeight,
                        minHeight: _categoryBarHeight,
                        builder: (shrinkOffset, overlapsContent) {
                          final double topPad = shrinkOffset.clamp(0, _topActionBarHeight);
                          return Container(
                            width: Dimensions.webMaxWidth,
                            color: Theme.of(context).cardColor,
                            padding: EdgeInsets.only(top: topPad),
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              height: _categoryBarHeight,
                              child: RestaurantStickyHeaderWidget(
                                restController: restController,
                                activeCategoryId: _activeCategoryId,
                                onCategorySelected: _handleCategoryTap,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 3. Content (Menu or Search Results)
                    SliverToBoxAdapter(
                      child: FooterViewWidget(
                        child: Center(
                          child: Container(
                            width: Dimensions.webMaxWidth,
                            padding: const EdgeInsets.only(
                              top: 0,
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

                // Fixed Top Action Bar (Back, Search, Heart)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: RestaurantAppBarWidget(
                    restController: restController,
                    backgroundOpacity: _appBarOpacity,
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

class SliverDelegate extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final Widget Function(double shrinkOffset, bool overlapsContent) builder;

  SliverDelegate({
    required this.maxHeight,
    required this.builder,
    double? minHeight,
  }) : minHeight = minHeight ?? maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: builder(shrinkOffset, overlapsContent));
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != maxHeight || oldDelegate.minExtent != minHeight;
  }
}
