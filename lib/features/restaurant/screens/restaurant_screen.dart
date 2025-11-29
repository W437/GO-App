import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/footer_view_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/paginated_list_view_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/product/product_view_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/bottom_cart_widget.dart';
import 'package:godelivery_user/common/widgets/web/web_menu_bar.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_product_horizontal_card.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_sticky_header_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_details_section_widget.dart';
import 'package:godelivery_user/features/restaurant/mixins/restaurant_scroll_mixin.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_app_bar_widget.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class RestaurantScreen extends StatefulWidget {
  final int restaurantId;
  final String slug;
  final bool fromDineIn;
  final int? scrollToProductId;

  const RestaurantScreen({
    super.key,
    required this.restaurantId,
    this.slug = '',
    this.fromDineIn = false,
    this.scrollToProductId,
  });

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen>
    with TickerProviderStateMixin, RestaurantScrollMixin {
  final ScrollController scrollController = ScrollController();
  final Map<int, GlobalKey> _categorySectionKeys = {};
  final Map<int, ScrollController> _horizontalScrollControllers = {};
  final Map<int, AnimationController> _wiggleControllers = {};
  final Map<int, AnimationController> _overlayControllers = {};
  final Map<int, Animation<double>> _wiggleAnimations = {};
  final Map<int, Animation<double>> _overlayAnimations = {};

  // Implement mixin requirement
  @override
  Map<int, GlobalKey> get categorySectionKeys => _categorySectionKeys;

  // Logo state
  late AnimationController _logoBounceController;
  late Animation<double> _logoBounceAnimation;
  bool _hasBouncedOnReturn = false;
  double _previousScrollOffset = 0.0;
  double _scrollOffset = 0.0;
  double _logoOpacity = 1.0;
  double _logoScale = 1.0;

  // Cart widget animation delay
  bool _showCartWidget = false;
  Timer? _cartWidgetTimer;
  int _previousCartCount = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);

    // Initialize logo bounce animation
    _logoBounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoBounceAnimation = TweenSequence<double>([
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
    ]).animate(_logoBounceController);

    // Initialize cart visibility based on current state
    _initCartVisibility();

    // Listen to cart changes for visibility updates
    Get.find<CartController>().addListener(_onCartChanged);

    // Defer data loading to after the first frame to avoid calling update()
    // during the build phase when cached data triggers a synchronous update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initDataCall();
    });
  }

  void _initCartVisibility() {
    final cartController = Get.find<CartController>();
    final currentCount = cartController.cartList.length;
    _previousCartCount = currentCount;

    // If cart already has items for this restaurant, show cart after delay
    if (currentCount > 0) {
      final firstItem = cartController.cartList.first;
      if (firstItem.product?.restaurantId == widget.restaurantId) {
        _cartWidgetTimer = Timer(const Duration(milliseconds: 350), () {
          if (mounted) {
            setState(() => _showCartWidget = true);
          }
        });
      }
    }
  }

  void _onCartChanged() {
    if (!mounted) return;

    final cartController = Get.find<CartController>();
    final currentCount = cartController.cartList.length;

    // Detect cart becoming non-empty
    if (currentCount > 0 && _previousCartCount == 0) {
      _showCartWidget = false;
      _cartWidgetTimer?.cancel();
      _cartWidgetTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() => _showCartWidget = true);
        }
      });
    }
    // Detect cart becoming empty
    else if (currentCount == 0 && _previousCartCount > 0) {
      _cartWidgetTimer?.cancel();
      setState(() => _showCartWidget = false);
    }

    _previousCartCount = currentCount;
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _cartWidgetTimer?.cancel();
    _logoBounceController.dispose();

    // Remove cart listener
    Get.find<CartController>().removeListener(_onCartChanged);

    // Dispose all horizontal scroll controllers
    for (var controller in _horizontalScrollControllers.values) {
      controller.dispose();
    }

    // Dispose all wiggle controllers
    for (var controller in _wiggleControllers.values) {
      controller.dispose();
    }

    // Dispose all overlay controllers
    for (var controller in _overlayControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _initDataCall() async {
    final restController = Get.find<RestaurantController>();
    final restaurantId = widget.restaurantId;

    // Reset scroll position and clear search state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    });

    if (restController.isSearching) {
      restController.changeSearchStatus(isUpdate: false);
    }

    // Controller handles all caching and parallel loading
    await restController.loadRestaurant(restaurantId, slug: widget.slug);

    // Extract coupons from restaurant details
    if (restController.restaurant?.coupons != null) {
      Get.find<CouponController>().setCouponsFromRestaurant(
        restController.restaurant!.coupons
      );
    }

    // Scroll to product if specified
    if (widget.scrollToProductId != null) {
      _scheduleScrollToProduct(widget.scrollToProductId!);
    }
  }

  void _scheduleScrollToProduct(int productId) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for cart widget animation delay + layout
      await Future.delayed(const Duration(milliseconds: 550));
      if (mounted) {
        _scrollToProduct(productId);
      }
    });
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final double offset = scrollController.offset;
    const double animationThreshold = 50.0;
    const double animationRange = 100.0;

    // Update logo position, opacity, and scale
    setState(() {
      _scrollOffset = offset.clamp(0.0, double.infinity);

      final double animationOffset = (offset - animationThreshold).clamp(0.0, animationRange);
      _logoOpacity = (1.0 - (animationOffset / animationRange)).clamp(0.0, 1.0);
      _logoScale = (1.0 - (animationOffset / animationRange) * 0.65).clamp(0.35, 1.0);
    });

    // Trigger bounce animation when scrolling up and hitting the top
    final bool isScrollingUp = offset < _previousScrollOffset;
    final bool isAtTop = offset <= 10.0;

    if (isScrollingUp && isAtTop && !_hasBouncedOnReturn) {
      _hasBouncedOnReturn = true;
      _logoBounceController.forward(from: 0.0);
    } else if (!isAtTop) {
      _hasBouncedOnReturn = false;
    }

    _previousScrollOffset = offset;

    // Detect active section using mixin
    final restController = Get.find<RestaurantController>();
    if (!restController.isManualScrolling) {
      final viewportHeight = MediaQuery.of(context).size.height;
      final viewportCenter = viewportHeight / 2;
      final detectedSection = detectActiveSectionOnScroll(viewportHeight, viewportCenter);

      if (detectedSection != null && restController.activeSectionId != detectedSection) {
        restController.setActiveSectionId(detectedSection);
      }
    }
  }

  // Handle section tap (menu sections)
  Future<void> _handleSectionTap(int sectionId) async {
    final restController = Get.find<RestaurantController>();
    restController.setActiveSectionId(sectionId);
    restController.setManualScrolling(true);

    if (scrollController.hasClients) {
      final key = _categorySectionKeys[sectionId];
      if (key?.currentContext != null) {
        final box = key!.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);

        final screenHeight = MediaQuery.of(context).size.height;
        final centerOffset = screenHeight / 2 - box.size.height / 2;
        final targetPosition = scrollController.offset + position.dy - centerOffset;

        await scrollController.animateTo(
          targetPosition.clamp(0.0, scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      restController.setManualScrolling(false);
    });
  }

  void _scrollToProduct(int productId) async {
    if (!scrollController.hasClients) return;

    final restController = Get.find<RestaurantController>();
    final section = restController.findSectionForProduct(productId);

    if (section == null) {
      // Data not loaded yet, retry
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _scrollToProduct(productId);
      return;
    }

    await _handleSectionTap(section.id!);

    // Trigger wiggle and overlay animations
    if (mounted) {
      _wiggleControllers[productId]?.forward(from: 0.0);
      _overlayControllers[productId]?.forward(from: 0.0);
    }
  }

  /// Build menu sections using the new section-based API structure
  List<Widget> _buildMenuSectionsNew(BuildContext context, RestaurantController restController) {
    final widgets = <Widget>[];
    final menuSections = restController.visibleMenuSections ?? [];

    if (menuSections.isEmpty) {
      widgets.add(
        SizedBox(
          height: 220,
          child: Center(
            child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
          ),
        ),
      );
      return widgets;
    }

    // Set first section as active if not set
    if (restController.activeSectionId == null && menuSections.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          restController.setActiveSectionId(menuSections.first.id);
        }
      });
    }

    for (final section in menuSections) {
      if (section.products == null || section.products!.isEmpty) continue;

      // Store section key for scrolling
      final sectionId = section.id!;
      _categorySectionKeys.putIfAbsent(sectionId, () => GlobalKey());
      _horizontalScrollControllers.putIfAbsent(sectionId, () => ScrollController());

      final horizontalController = _horizontalScrollControllers[sectionId]!;

      // Create wiggle and overlay controllers for products in this section
      for (final product in section.products!) {
        if (product.id != null) {
          _wiggleControllers.putIfAbsent(
            product.id!,
            () => AnimationController(
              duration: const Duration(milliseconds: 400),
              vsync: this,
            ),
          );
          _overlayControllers.putIfAbsent(
            product.id!,
            () => AnimationController(
              duration: const Duration(milliseconds: 200),
              vsync: this,
            ),
          );

          _wiggleAnimations.putIfAbsent(
            product.id!,
            () => TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.05), weight: 25),
              TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 25),
              TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 25),
              TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 25),
            ]).animate(_wiggleControllers[product.id!]!),
          );

          _overlayAnimations.putIfAbsent(
            product.id!,
            () => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _overlayControllers[product.id!]!,
                curve: Curves.easeOut,
              ),
            ),
          );
        }
      }

      // Section Header (regular widget, not sliver)
      widgets.add(
        Padding(
          key: _categorySectionKeys[sectionId],
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeExtraLarge, // More spacing between sections
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  section.name ?? '',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
              Text(
                '${section.products!.length} ${'items'.tr}',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        ),
      );

      // Section Products - Horizontal Scroll (regular widget, not sliver)
      widgets.add(
        SizedBox(
          height: 220, // Card height ~200 + padding for shadows
          child: ListView.builder(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none, // Allow shadows to render outside bounds
            padding: const EdgeInsets.only(
              left: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
              bottom: Dimensions.paddingSizeSmall, // Bottom padding for shadow
            ),
            itemCount: section.products!.length,
            itemBuilder: (context, index) {
              final product = section.products![index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < section.products!.length - 1 ? Dimensions.paddingSizeDefault : 0,
                ),
                child: SizedBox(
                  height: 200, // Smaller, more compact card height
                  child: RestaurantProductHorizontalCard(
                    product: product,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Empty state
    if (widgets.isEmpty) {
      widgets.add(
        SizedBox(
          height: 220,
          child: Center(
            child: Text(
              'no_items_found'.tr,
              style: robotoMedium.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildMenuSections(BuildContext context, RestaurantController restController) {
    return _buildMenuSectionsNew(context, restController);
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

  /// Build the stretchable header with cover image (logo is separate overlay)
  Widget _buildStretchableHeader(BuildContext context, Restaurant restaurant, RestaurantController restController) {
    return SliverAppBar(
      expandedHeight: RestaurantScrollMixin.expandedHeight,
      toolbarHeight: kToolbarHeight,
      pinned: true, // Keep the app bar pinned for back button visibility
      floating: false,
      stretch: true,
      elevation: 0,
      backgroundColor: Theme.of(context).cardColor,
      automaticallyImplyLeading: false,
      leading: const SizedBox(),
      leadingWidth: 0,
      stretchTriggerOffset: 100,
      // Pinned title bar with back button, search, and favorite
      title: RestaurantAppBarWidget(
        restController: restController,
        restaurant: restaurant,
        scrollOffset: _scrollOffset,
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Clear image (bottom layer)
            BlurhashImageWidget(
              imageUrl: restaurant.coverPhotoFullUrl ?? '',
              blurhash: restaurant.coverPhotoBlurhash,
              fit: BoxFit.cover,
            ),

            // Blurred image with gradient mask (blur at bottom)
            ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                  ],
                  stops: [0.4, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: BlurhashImageWidget(
                  imageUrl: restaurant.coverPhotoFullUrl ?? '',
                  blurhash: restaurant.coverPhotoBlurhash,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Top gradient overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the floating logo that sits on top of everything
  Widget _buildFloatingLogo(BuildContext context, Restaurant restaurant) {
    return Positioned(
      top: RestaurantScrollMixin.expandedHeight - (RestaurantScrollMixin.logoSize / 2) + RestaurantScrollMixin.logoCenterOffset - _scrollOffset,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: _logoOpacity < 0.3,
        child: Center(
          child: Opacity(
            opacity: _logoOpacity,
            child: AnimatedBuilder(
              animation: _logoBounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScale * _logoBounceAnimation.value,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: () => _logoBounceController.forward(from: 0.0),
                child: Container(
                  height: RestaurantScrollMixin.logoSize,
                  width: RestaurantScrollMixin.logoSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08),
                      width: 2.0,
                    ),
                    boxShadow: const [
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
        ),
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

            // Use loaded data, or search cache, or create minimal restaurant
            final Restaurant activeRestaurant = restController.restaurant ??
                                                restController.getCachedRestaurant(widget.restaurantId) ??
                                                Restaurant(id: widget.restaurantId);

            // Check if menu sections data exists
            final bool hasProductsData = restController.visibleMenuSections != null &&
                                          restController.visibleMenuSections!.isNotEmpty &&
                                          !restController.isTransitioning;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Main scrollable content
                CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  controller: scrollController,
                  slivers: [
                    // 1. Stretchable Cover Image
                    _buildStretchableHeader(context, activeRestaurant, restController),

                    // 2. Restaurant Details Section
                    RestaurantDetailsSectionWidget(
                      restaurant: activeRestaurant,
                      restController: restController,
                    ),

                    // 3. Sticky section header (shows immediately when metadata loads)
                    if (restController.isUsingSections)
                      SliverAppBar(
                        pinned: true,
                        primary: false,
                        automaticallyImplyLeading: false,
                        backgroundColor: Theme.of(context).cardColor,
                        elevation: 0,
                        toolbarHeight: RestaurantScrollMixin.categoryBarHeight + 1,
                        titleSpacing: 0,
                        title: Column(
                          children: [
                            SizedBox(
                              height: RestaurantScrollMixin.categoryBarHeight,
                              child: RestaurantStickyHeaderWidget(
                                restController: restController,
                                activeSectionId: restController.activeSectionId,
                                onSectionSelected: _handleSectionTap,
                              ),
                            ),
                            Container(
                              height: 1,
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ],
                        ),
                      ),

                    // 4. Content (Menu or Search Results)
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

                // Floating logo on top of everything
                _buildFloatingLogo(context, activeRestaurant),
              ],
            );
          });
        });
      }),

      bottomNavigationBar: GetBuilder<CartController>(builder: (cartController) {
        // Check if cart has items for this restaurant (no side effects in build!)
        final bool hasCartForThisRestaurant = cartController.cartList.isNotEmpty &&
            cartController.cartList.first.product?.restaurantId == widget.restaurantId;

        final bool showCart = _showCartWidget && hasCartForThisRestaurant && !isDesktop;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Gradient fade overlay - positioned above the cart
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).cardColor.withValues(alpha: 0.0),
                        Theme.of(context).cardColor,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Cart widget
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ));

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
              child: showCart
                  ? BottomCartWidget(
                      key: const ValueKey('cart-widget'),
                      restaurantId: widget.restaurantId,
                      fromDineIn: widget.fromDineIn,
                    )
                  : const SizedBox(key: ValueKey('empty-cart')),
            ),
          ],
        );
      })
    );
  }
}
