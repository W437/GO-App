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
import 'package:godelivery_user/features/restaurant/widgets/restaurant_product_horizontal_card.dart';
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
  final Map<int, ScrollController> _horizontalScrollControllers = {};
  final Map<int, AnimationController> _wiggleControllers = {};
  final Map<int, AnimationController> _overlayControllers = {};
  final Map<int, Animation<double>> _wiggleAnimations = {};
  final Map<int, Animation<double>> _overlayAnimations = {};
  int? _highlightedProductId;
  int? _activeCategoryId = 0; // Default to "All" category (legacy)
  int? _activeSectionId; // NEW: Active menu section ID
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
    final categoryController = Get.find<CategoryController>();
    final couponController = Get.find<CouponController>();

    if(restController.isSearching) {
      restController.changeSearchStatus(isUpdate: false);
    }

    // Check if we already have cached data for this restaurant
    final bool isSameRestaurant = restController.restaurant?.id == widget.restaurant!.id;
    // Check if products belong to THIS restaurant (not just if they exist)
    final bool hasCorrectProducts = restController.restaurantProducts != null &&
                                     restController.restaurantProducts!.isNotEmpty &&
                                     restController.restaurantProducts!.first.restaurantId == widget.restaurant!.id;
    final bool hasRestaurantDetails = restController.restaurant != null &&
                                     restController.restaurant!.schedules != null;

    // Step 1: Fetch lightweight menu sections first (fast, shows sticky header immediately)
    if (!isSameRestaurant) {
      final restaurantId = widget.restaurant!.id!;
      await restController.getMenuSections(restaurantId);
    }

    // Step 2: Parallel load restaurant details and products
    List<Future> parallelCalls = [];

    // Only fetch restaurant details if it's a different restaurant or we don't have full details
    if (!isSameRestaurant || !hasRestaurantDetails) {
      parallelCalls.add(
        restController.getRestaurantDetails(Restaurant(id: widget.restaurant!.id), slug: widget.slug)
      );
    }

    // Fetch products (with full section data)
    // Note: The new smart products endpoint includes recommended flags
    // and coupons are now included in restaurant details
    if (!isSameRestaurant || !hasCorrectProducts) {
      final restaurantId = widget.restaurant!.id ?? restController.restaurant!.id!;
      parallelCalls.add(restController.getRestaurantProductList(restaurantId, 0, 'all', false));
      // Coupons are now included in restaurant details, no separate call needed
      // Recommended products are now flagged in the products response
    }

    // Execute all calls in parallel
    if (parallelCalls.isNotEmpty) {
      await Future.wait(parallelCalls);
    }

    // Extract coupons from restaurant details (new optimization)
    if (restController.restaurant != null && restController.restaurant!.coupons != null) {
      couponController.setCouponsFromRestaurant(restController.restaurant!.coupons);
    }

    // Scroll to product if specified
    if (widget.scrollToProductId != null) {
      // Wait for cart widget to render (has 350ms delay) and layout to settle
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Wait for cart widget animation delay (350ms) + extra for layout
        await Future.delayed(const Duration(milliseconds: 550));
        if (mounted) {
          _scrollToProduct(widget.scrollToProductId!);
        }
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

  // NEW: Handle section tap (menu sections)
  Future<void> _handleSectionTap(int sectionId) async {
    print('📍 _handleSectionTap called with sectionId: $sectionId');

    setState(() {
      _activeSectionId = sectionId;
      _isManualScrolling = true;
    });

    if (scrollController.hasClients) {
      final key = _categorySectionKeys[sectionId];
      print('   Section key found: ${key != null}');
      print('   Key has context: ${key?.currentContext != null}');

      if(key?.currentContext != null) {
        final box = key!.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);

        // Calculate target position to center the section in viewport
        final screenHeight = MediaQuery.of(context).size.height;
        final centerOffset = screenHeight / 2 - box.size.height / 2;
        final targetPosition = scrollController.offset + position.dy - centerOffset;

        print('   Scrolling to section at offset: $targetPosition');
        await scrollController.animateTo(
          targetPosition.clamp(0.0, scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    }

    // Reset manual scrolling flag after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isManualScrolling = false;
        });
      }
    });
  }

  // LEGACY: Handle category tap
  Future<void> _handleCategoryTap(int categoryId) async {
    print('📍 _handleCategoryTap called with categoryId: $categoryId');

    setState(() {
      _activeCategoryId = categoryId;
      _isManualScrolling = true;
    });

    if (scrollController.hasClients) {
      // Special handling for "All" category - scroll to top
      if (categoryId == 0) {
        print('   Scrolling to top (All category)');
        await scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      } else {
        // Regular category - scroll to section and center in viewport
        final key = _categorySectionKeys[categoryId];
        print('   Category key found: ${key != null}');
        print('   Key has context: ${key?.currentContext != null}');

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

          print('   position.dy: ${position.dy}');
          print('   viewportHeight: $viewportHeight');
          print('   appBarHeight: $appBarHeight');
          print('   availableHeight: $availableHeight');
          print('   current scroll offset: ${scrollController.offset}');
          print('   targetOffset: $targetOffset');
          print('   clampedTarget: $clampedTarget');
          print('   maxScrollExtent: ${scrollController.position.maxScrollExtent}');

          await scrollController.animateTo(
            clampedTarget,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
          );
          print('   Scroll animation complete');
        }
      }

      setState(() {
        _isManualScrolling = false;
      });
    } else {
      print('⚠️ scrollController has no clients');
    }
  }

  void _scrollToProduct(int productId) async {
    print('🔍 _scrollToProduct called with productId: $productId');
    print('   scrollController.hasClients: ${scrollController.hasClients}');

    if (!scrollController.hasClients) {
      print('⚠️ scrollController has no clients yet');
      return;
    }

    // Find the category containing this product
    final restController = Get.find<RestaurantController>();
    final products = restController.restaurantProducts;

    print('   products loaded: ${products != null}');
    print('   products count: ${products?.length ?? 0}');

    if (products == null) {
      // Data not loaded yet, try again after a short delay
      print('⚠️ Products not loaded yet, retrying in 300ms...');
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _scrollToProduct(productId);
      return;
    }

    // Find the product
    final product = products.firstWhereOrNull((p) => p.id == productId);
    if (product == null) {
      print('⚠️ Product not found for ID: $productId');
      return;
    }

    // Get the first category ID for this product
    final categoryId = product.categoryId;
    print('   Found product: ${product.name}');
    print('   Category ID: $categoryId');

    if (categoryId == null) {
      print('⚠️ Product has no category');
      return;
    }

    print('✅ Calling _handleCategoryTap($categoryId)');

    // Scroll vertically to center the category section in the viewport
    await _handleCategoryTap(categoryId);

    print('✅ Category scroll complete, triggering wiggle for product $productId');

    // Trigger both wiggle and overlay animations for the product
    if (mounted) {
      if (_wiggleControllers.containsKey(productId)) {
        _wiggleControllers[productId]!.forward(from: 0.0);
      }
      if (_overlayControllers.containsKey(productId)) {
        _overlayControllers[productId]!.forward(from: 0.0);
      }
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

  /// NEW: Build menu sections using the new section-based API structure
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
    if (_activeSectionId == null && menuSections.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _activeSectionId = menuSections.first.id;
          });
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
            Dimensions.paddingSizeLarge,
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
          height: 280,
          child: ListView.builder(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: section.products!.length,
            itemBuilder: (context, index) {
              final product = section.products![index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < section.products!.length - 1 ? Dimensions.paddingSizeDefault : 0,
                ),
                child: RestaurantProductHorizontalCard(
                  product: product,
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
    final sections = <Widget>[];

    // NEW: Check if using menu sections (new API format)
    if (restController.isUsingSections) {
      return _buildMenuSectionsNew(context, restController);
    }

    // LEGACY: Category-based display
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
      _horizontalScrollControllers.putIfAbsent(category.id!, () => ScrollController());
      _activeCategoryId ??= category.id;

      final horizontalController = _horizontalScrollControllers[category.id!]!;

      // Create wiggle and overlay controllers for products in this category
      for (final product in products) {
        if (!_wiggleControllers.containsKey(product.id)) {
          // Wiggle controller (700ms)
          final wiggleController = AnimationController(
            duration: const Duration(milliseconds: 700),
            vsync: this,
          );
          _wiggleControllers[product.id!] = wiggleController;

          // Overlay controller (1000ms)
          final overlayController = AnimationController(
            duration: const Duration(milliseconds: 1000),
            vsync: this,
          );
          _overlayControllers[product.id!] = overlayController;

          // Wiggle animation (subtle)
          _wiggleAnimations[product.id!] = TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.02), weight: 1),
            TweenSequenceItem(tween: Tween(begin: 0.02, end: -0.02), weight: 2),
            TweenSequenceItem(tween: Tween(begin: -0.02, end: 0.02), weight: 2),
            TweenSequenceItem(tween: Tween(begin: 0.02, end: -0.02), weight: 2),
            TweenSequenceItem(tween: Tween(begin: -0.02, end: 0.0), weight: 1),
          ]).animate(CurvedAnimation(
            parent: wiggleController,
            curve: Curves.easeInOut,
          ));

          // Overlay opacity animation: 0 → 0.4 → 0 (1000ms)
          _overlayAnimations[product.id!] = TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 50),
            TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 50),
          ]).animate(CurvedAnimation(
            parent: overlayController,
            curve: Curves.easeInOut,
          ));
        }
      }

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
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final wiggleAnimation = _wiggleAnimations[product.id];
                    final overlayAnimation = _overlayAnimations[product.id];

                    return Padding(
                      padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault, top: 8, bottom: 8),
                      child: wiggleAnimation != null && overlayAnimation != null
                          ? AnimatedBuilder(
                              animation: Listenable.merge([wiggleAnimation, overlayAnimation]),
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: wiggleAnimation.value,
                                  child: Stack(
                                    children: [
                                      child!,
                                      // Blue overlay (ignores pointer events so it doesn't block taps)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor.withValues(
                                                  alpha: overlayAnimation.value,
                                                ),
                                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: RestaurantProductHorizontalCard(
                                product: product,
                              ),
                            )
                          : RestaurantProductHorizontalCard(
                              product: product,
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

            // Restaurant data is ready when details are loaded
            if (restController.restaurant != null && restController.restaurant!.name != null) {
              restaurant = restController.restaurant;
            }

            bool hasCoupon = (couponController.couponList!= null && couponController.couponList!.isNotEmpty);

            // Check if menu sections data exists
            final bool hasProductsData = restController.isUsingSections &&
                                          restController.visibleMenuSections != null &&
                                          restController.visibleMenuSections!.isNotEmpty;

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

                      // Sticky section header (shows immediately when metadata loads)
                      if (restController.isUsingSections)
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
                                  activeSectionId: _activeSectionId,
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
            _cartWidgetTimer = Timer(const Duration(milliseconds: 350), () {
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


