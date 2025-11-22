import 'dart:ui';
import 'dart:async';

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
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
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
  final int? scrollToProductId;
  const RestaurantScreen({super.key, required this.restaurant, this.slug = '', this.fromDineIn = false, this.scrollToProductId});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> with TickerProviderStateMixin {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<int, GlobalKey> _categorySectionKeys = {};
  int? _highlightedProductId;
  int? _activeCategoryId = 0; // Default to "All" category
  bool _isManualScrolling = false;

  static const double _logoSize = 120.0;
  static const double _expandedHeight = 210.0; // Reduced to create 40px overlap
  static const double _sectionOverlap = 40.0; // White section overlaps cover by 40px
  static const double _logoCenterOffset = 5.0; // Additional offset to center between sections
  double _logoTopPosition = _expandedHeight - (_logoSize / 2) + _logoCenterOffset; // Position centered between sections
  double _logoOpacity = 1.0; // Initial opacity
  double _logoScale = 1.0; // Initial scale

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _hasBouncedOnReturn = false;
  double _previousScrollOffset = 0.0;

  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  static const double _categoryBarHeight = 50.0; // lane height; chips are slightly shorter

  // Cart widget animation delay
  bool _showCartWidget = false;
  Timer? _cartWidgetTimer;
  int _previousCartCount = 0;

  @override
  void initState() {
    super.initState();

    scrollController.addListener(_onScroll);
    _initDataCall();

    // Initialize bounce animation with smooth continuous spring
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.02)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_bounceController);

    // Initialize press animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _bounceController.dispose();
    _pressController.dispose();
    _cartWidgetTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDataCall() async {
    final restController = Get.find<RestaurantController>();
    final categoryController = Get.find<CategoryController>();
    final couponController = Get.find<CouponController>();

    if(restController.isSearching) {
      restController.changeSearchStatus(isUpdate: false);
    }

    // Check if we already have cached data for this restaurant
    final bool isSameRestaurant = restController.restaurant?.id == widget.restaurant!.id;
    final bool hasProducts = restController.restaurantProducts != null;
    final bool hasRestaurantDetails = restController.restaurant != null &&
                                     restController.restaurant!.schedules != null;

    // Parallel loading strategy: Only fetch what's needed
    List<Future> parallelCalls = [];

    // Only fetch restaurant details if it's a different restaurant or we don't have full details
    if (!isSameRestaurant || !hasRestaurantDetails) {
      parallelCalls.add(
        restController.getRestaurantDetails(Restaurant(id: widget.restaurant!.id), slug: widget.slug)
      );
    }

    // Only fetch categories if not loaded
    if(categoryController.categoryList == null) {
      parallelCalls.add(categoryController.getCategoryList(true));
    }

    // Only fetch products/coupons/recommended if different restaurant or no products
    if (!isSameRestaurant || !hasProducts) {
      final restaurantId = widget.restaurant!.id ?? restController.restaurant!.id!;
      parallelCalls.add(restController.getRestaurantProductList(restaurantId, 1, 'all', false));
      parallelCalls.add(couponController.getRestaurantCouponList(restaurantId: restaurantId));
      parallelCalls.add(restController.getRestaurantRecommendedItemList(restaurantId, false));
    }

    // Execute all calls in parallel
    if (parallelCalls.isNotEmpty) {
      await Future.wait(parallelCalls);
    }

    // Scroll to product if specified
    if (widget.scrollToProductId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToProduct(widget.scrollToProductId!);
      });
    }
  }

  void _onScroll() {
    if(!scrollController.hasClients) return;

    // Update logo position, opacity, and scale based on scroll offset
    final double offset = scrollController.offset;
    const double animationThreshold = 50.0; // Start animations after 100px scroll
    const double animationRange = 100.0; // Complete animation over 150px

    setState(() {
      _logoTopPosition = (_expandedHeight - (_logoSize / 2) + _logoCenterOffset) - offset;

      // Only start fade/scale after threshold
      final double animationOffset = (offset - animationThreshold).clamp(0.0, animationRange);

      // Fade out: Start fading at 200px, fully transparent at 350px scroll
      _logoOpacity = (1.0 - (animationOffset / animationRange)).clamp(0.0, 1.0);

      // Scale down: Start at 1.0, scale to 0.35 over animation range
      _logoScale = (1.0 - (animationOffset / animationRange) * 0.65).clamp(0.35, 1.0);
    });

    // Trigger bounce animation when scrolling up and hitting the top
    final bool isScrollingUp = offset < _previousScrollOffset;
    final bool isAtTop = offset <= 10.0; // At or near the top

    if (isScrollingUp && isAtTop && !_hasBouncedOnReturn) {
      _hasBouncedOnReturn = true;
      _bounceController.forward(from: 0.0);
    } else if (!isAtTop) {
      _hasBouncedOnReturn = false;
    }

    _previousScrollOffset = offset;

    // Logic to detect active category based on scroll position
    // Skip auto-detection during manual/programmatic scrolls (prevents flickering)
    if (!_isManualScrolling) {
      // Check if we're at the top - activate "All" category
      if (offset <= 100.0) {
        if (_activeCategoryId != 0) {
          setState(() {
            _activeCategoryId = 0; // "All" category
          });
        }
      } else {
        // Calculate 50% viewport trigger point (middle of screen)
        final double viewportHeight = MediaQuery.of(context).size.height;
        final double midpoint = viewportHeight / 2;
        const double tolerance = 50.0; // Tolerance range for activation

        // We iterate through keys and check which one is at the midpoint
        for (var entry in _categorySectionKeys.entries) {
          final key = entry.value;
          final context = key.currentContext;
          if (context != null) {
            final box = context.findRenderObject() as RenderBox;
            final position = box.localToGlobal(Offset.zero);
            // Check if the section is near the viewport midpoint (50%)
            if (position.dy >= (midpoint - tolerance) && position.dy <= (midpoint + tolerance)) {
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
    }
  }

  void _handleCategoryTap(int categoryId) async {
    setState(() {
      _activeCategoryId = categoryId;
      _isManualScrolling = true;
    });

    if (scrollController.hasClients) {
      // Special handling for "All" category - scroll to top
      if (categoryId == 0) {
        await scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      } else {
        // Regular category - scroll to section and center in viewport
        final key = _categorySectionKeys[categoryId];
        if(key?.currentContext != null) {
          final box = key!.currentContext!.findRenderObject() as RenderBox;
          final position = box.localToGlobal(Offset.zero);

          // Calculate viewport center
          final double viewportHeight = MediaQuery.of(context).size.height;
          final double appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
          final double availableHeight = viewportHeight - appBarHeight;

          // Center the section in the viewport, accounting for sticky category bar
          final double targetOffset = (scrollController.offset + position.dy) - (availableHeight / 2) + (_categoryBarHeight / 2);
          final double clampedTarget = targetOffset.clamp(0, scrollController.position.maxScrollExtent).toDouble();

          await scrollController.animateTo(
            clampedTarget,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
          );
        }
      }

      setState(() {
        _isManualScrolling = false;
      });
    }
  }

  void _scrollToProduct(int productId) async {
    if (!scrollController.hasClients) return;

    // Find the category containing this product
    final restController = Get.find<RestaurantController>();
    final products = restController.restaurantProducts;
    if (products == null) return;

    // Find the product
    final product = products.firstWhereOrNull((p) => p.id == productId);
    if (product == null) {
      print('⚠️ Product not found for ID: $productId');
      return;
    }

    // Get the first category ID for this product
    final categoryId = product.categoryId;
    if (categoryId == null) {
      print('⚠️ Product has no category');
      return;
    }

    // Scroll to the category section
    _handleCategoryTap(categoryId);

    // Trigger highlight animation for the product
    setState(() {
      _highlightedProductId = productId;
    });

    // Remove highlight after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _highlightedProductId = null;
        });
      }
    });
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
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Padding(
                      padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault, top: 8, bottom: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          border: _highlightedProductId == product.id
                              ? Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: RestaurantHorizontalProductCard(
                          product: product,
                        ),
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

  List<Widget> _buildMenuShimmer() {
    return [
      SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).hintColor,
          ),
        ),
      ),
    ];
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
            final bool hasProductsData = restController.restaurantProducts != null && categoryController.categoryList != null;

            // Use widget.restaurant for initial data, fallback to controller data when loaded
            final Restaurant activeRestaurant = restController.restaurant ?? widget.restaurant!;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: scrollController,
                    clipBehavior: Clip.none,
                    slivers: [
                      // Cover Image & App Bar
                      RestaurantInfoSectionWidget(
                        restaurant: activeRestaurant,
                        restController: restController,
                        hasCoupon: hasCoupon,
                        scrollOffset: scrollController.hasClients ? scrollController.offset : 0.0,
                      ),

                      // Restaurant Details (Card overlay effect)
                      RestaurantDetailsSectionWidget(
                        restaurant: activeRestaurant,
                        restController: restController,
                      ),

                      // Sticky categories (only show when categories are loaded)
                      if (categoryController.categoryList != null)
                        SliverAppBar(
                          pinned: true,
                          primary: false,
                          automaticallyImplyLeading: false,
                          backgroundColor: Theme.of(context).cardColor,
                          elevation: 0,
                          toolbarHeight: _categoryBarHeight + 1, // Extra 1px for separator
                          titleSpacing: 0,
                          title: Column(
                            children: [
                              SizedBox(
                                height: _categoryBarHeight,
                                child: RestaurantStickyHeaderWidget(
                                  restController: restController,
                                  activeCategoryId: _activeCategoryId,
                                  onCategorySelected: _handleCategoryTap,
                                ),
                              ),
                              Container(
                                height: 1,
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ],
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
                                  key: ValueKey('menu-${hasProductsData ? 'loaded' : 'loading'}'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: hasProductsData
                                      ? _buildMenuSections(context, restController)
                                      : _buildMenuShimmer(),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Restaurant Logo - Top Layer (renders above all elements)
              Positioned(
                    top: _logoTopPosition, // Dynamic position that moves with scroll
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Opacity(
                        opacity: _logoOpacity, // Fade out as we scroll
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_bounceAnimation, _pressAnimation]),
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoScale * _bounceAnimation.value * _pressAnimation.value, // Combine scroll, bounce, and press scales
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTapDown: (_) {
                              _pressController.forward();
                            },
                            onTapUp: (_) {
                              _pressController.reverse();
                            },
                            onTapCancel: () {
                              _pressController.reverse();
                            },
                            onTap: () {
                              _bounceController.forward(from: 0.0);
                            },
                            child: Container(
                              height: _logoSize,
                              width: _logoSize,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(149, 157, 165, 0.2),
                                    blurRadius: 24,
                                    spreadRadius: 0,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                                child: CustomImageWidget(
                                  image: '${activeRestaurant.logoFullUrl}',
                                  height: _logoSize,
                                  width: _logoSize,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
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
          final currentCartCount = cartController.cartList.length;

          // Detect when cart goes from empty to having items
          if (currentCartCount > 0 && _previousCartCount == 0) {
            // Cart just got its first item - start delay timer
            _showCartWidget = false;
            _cartWidgetTimer?.cancel();
            _cartWidgetTimer = Timer(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _showCartWidget = true;
                });
              }
            });
          } else if (currentCartCount == 0 && _previousCartCount > 0) {
            // Cart just became empty - hide immediately
            _showCartWidget = false;
            _cartWidgetTimer?.cancel();
          }

          _previousCartCount = currentCartCount;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Slide animation only
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.0, 1.0), // Start from bottom
                end: Offset.zero, // End at position
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic, // Smooth, fluid motion
              ));

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            child: _showCartWidget && cartController.cartList.isNotEmpty && !isDesktop
                ? BottomCartWidget(
                    key: const ValueKey('cart-widget'),
                    restaurantId: cartController.cartList[0].product!.restaurantId!,
                    fromDineIn: widget.fromDineIn,
                  )
                : const SizedBox(key: ValueKey('empty-cart')),
          );
        })
    );
  }
}


