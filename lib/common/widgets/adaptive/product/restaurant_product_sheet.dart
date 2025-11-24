/// Restaurant Product Sheet for detailed product view and cart interactions
/// Displays product details, variations, add-ons, and add to cart functionality

import 'package:godelivery_user/common/widgets/shared/text/animated_text_transition.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:godelivery_user/common/widgets/adaptive/custom_favourite_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/shared/text/custom_tool_tip.dart';
import 'package:godelivery_user/common/widgets/adaptive/discount_tag_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/discount_tag_without_image_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/product/product_bottom_sheet_shimmer.dart';
import 'package:godelivery_user/common/widgets/adaptive/quantity_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/rating_bar_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/checkout/screens/checkout_screen.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/checkout/domain/models/place_order_body_model.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/features/product/controllers/product_controller.dart';
import 'package:godelivery_user/helper/business_logic/cart_helper.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/adaptive/dialogs/confirmation_dialog_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RestaurantProductSheet extends StatefulWidget {
  final Product? product;
  final bool isCampaign;
  final CartModel? cart;
  final int? cartIndex;
  final bool inRestaurantPage;
  final bool? fromReview;
  const RestaurantProductSheet({super.key, required this.product, this.isCampaign = false, this.cart, this.cartIndex, this.inRestaurantPage = false, this.fromReview = false});

  @override
  State<RestaurantProductSheet> createState() => _RestaurantProductSheetState();
}

class _RestaurantProductSheetState extends State<RestaurantProductSheet> {

  JustTheController tooTipController = JustTheController();

  final ScrollController scrollController = ScrollController();

  Product? product;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();

    scrollController.addListener(_onScroll);
    _initCall();
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = scrollController.offset;
    });
  }

  double _calculateTopPosition() {
    const double initialTop = 260.0;
    const double minTop = 100.0; // Maximum slide up position
    const double scrollThreshold = 50.0; // Start sliding after scrolling 50 pixels (20% threshold)

    if (_scrollOffset < scrollThreshold) {
      return initialTop;
    }

    // Calculate slide amount after threshold
    double slideAmount = (_scrollOffset - scrollThreshold) * 0.5; // Slide at 50% of scroll speed
    double newTop = initialTop - slideAmount;

    // Clamp between minTop and initialTop
    return newTop.clamp(minTop, initialTop);
  }

  Future<void> _initCall() async {
    if(widget.fromReview! || widget.inRestaurantPage) {
      // Use the product data directly without fetching
      product = widget.product!;
      Get.find<ProductController>().initializeProductData(product!, cart: widget.cart);
    } else {
      await Get.find<ProductController>().getProductDetails(widget.product!.id!, widget.cart, isCampaign: widget.isCampaign);
      product = Get.find<ProductController>().product;
    }

    String? warning = Get.find<ProductController>().checkOutOfStockVariationSelected(product?.variations);
    if(warning != null) {
      showCustomSnackBar(warning);
    }
    if(product != null && product!.variations!.isEmpty) {
      final cartIndex = Get.find<ProductController>().setExistInCart(product!);
      print('🛒 [PRODUCT SHEET] setExistInCart called - cartIndex: $cartIndex');
      print('   Product ID: ${product!.id}');
      print('   Cart count: ${Get.find<CartController>().cartList.length}');
      if (cartIndex != -1) {
        print('   ✅ Found in cart! Quantity: ${Get.find<ProductController>().quantity}');
      } else {
        print('   ❌ Not in cart - will show Add to Cart');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      width: 550,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: GetBuilder<ProductController>(builder: (productController) {
        product = productController.product;
        if(productController.product == null) {
          return const ProductBottomSheetShimmer();
        }
        double price = product!.price!;
        double? discount = product!.discount;
        String? discountType = product!.discountType;
        double variationPrice = _getVariationPrice(product!, productController);
        double variationPriceWithDiscount = _getVariationPriceWithDiscount(product!, productController, discount, discountType);
        double priceWithDiscountForView = PriceConverter.convertWithDiscount(price, discount, discountType)!;
        double priceWithDiscount = PriceConverter.convertWithDiscount(price, discount, discountType)!;

        double addonsCost = _getAddonCost(product!, productController);
        List<AddOn> addOnIdList = _getAddonIdList(product!, productController);
        List<AddOns> addOnsList = _getAddonList(product!, productController);

        double priceWithAddonsVariationWithDiscount = addonsCost + (PriceConverter.convertWithDiscount(variationPrice + price , discount, discountType)! * productController.quantity!);
        double priceWithAddonsVariation = ((price + variationPrice) * productController.quantity!) + addonsCost;
        double priceWithVariation = price + variationPrice;
        bool isAvailable = DateConverter.isAvailable(product!.availableTimeStarts, product!.availableTimeEnds);

        return Stack(
          children: [
            // 1. Cover Image Background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BlurhashImageWidget(
                      imageUrl: '${product!.imageFullUrl}',
                      blurhash: product!.imageBlurhash,
                      fit: BoxFit.cover,
                    ),
                    // Gradient overlay for text visibility if needed, or just style
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4],
                        ),
                      ),
                    ),
                  ],
                ),
            ),

            // 2. Close Button
            Positioned(
              top: Dimensions.paddingSizeDefault,
              left: Dimensions.paddingSizeDefault,
              child: CircularBackButtonWidget(
                icon: Icons.keyboard_arrow_down,
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                iconColor: Colors.black,
                size: 36,
                iconSize: 20,
                onPressed: () => Get.back(),
              ),
            ),

            // Like Button (top right)
            Positioned(
              top: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
              child: InkWell(
                onTap: () async {
                  if (!Get.find<AuthController>().isLoggedIn()) {
                    showCustomSnackBar('please_login_to_like'.tr);
                    return;
                  }

                  try {
                    final response = await Get.find<ApiClient>().postData(
                      '${AppConstants.productLikeUri}${product!.id}/like',
                      {},
                    );

                    if (response.statusCode == 200) {
                      // Update local like count
                      setState(() {
                        product!.likeCount = response.body['like_count'];
                      });

                      showCustomSnackBar(
                        response.body['message'],
                        isError: false,
                      );
                    }
                  } catch (e) {
                    print('❌ Like error: $e');
                    showCustomSnackBar('failed_to_like_product'.tr);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      AnimatedTextTransition(
                        value: product!.likeCount ?? 0,
                        style: robotoBold.copyWith(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Scrollable Content
            Positioned.fill(
              top: _calculateTopPosition(), // Dynamic position based on scroll
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle Bar
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Title & Price
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product!.name ?? '',
                                    style: robotoBold.copyWith(fontSize: 24),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: Dimensions.paddingSizeSmall),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      PriceConverter.convertPrice(priceWithDiscountForView),
                                      style: robotoBold.copyWith(fontSize: 24, color: Theme.of(context).primaryColor),
                                    ),
                                    if (price > priceWithDiscountForView)
                                      Text(
                                        PriceConverter.convertPrice(price),
                                        style: robotoRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context).disabledColor,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),

                            // Tags (Spicy, Veg, etc.)
                            Wrap(
                              spacing: Dimensions.paddingSizeSmall,
                              children: [
                                if (product!.isRestaurantHalalActive! && product!.isHalalFood!)
                                  _buildTag('Halal', Icons.verified_user_outlined, Colors.green),
                                if (Get.find<SplashController>().configModel!.toggleVegNonVeg!)
                                  _buildTag(
                                    product!.veg == 1 ? 'veg'.tr : 'non_veg'.tr,
                                    Icons.eco,
                                    product!.veg == 1 ? Colors.green : Colors.red,
                                  ),
                              ],
                            ),
                            const SizedBox(height: Dimensions.paddingSizeDefault),

                            // Description & Nutrition Buttons
                            Row(
                              children: [
                                if (product!.description != null && product!.description!.isNotEmpty)
                                  _buildInfoButton('Description', () {
                                    // Toggle description visibility or show dialog
                                    // For now, we can just show it inline below or keep it simple
                                  }),
                                const SizedBox(width: Dimensions.paddingSizeSmall),
                                if (product!.nutritionsName != null && product!.nutritionsName!.isNotEmpty)
                                  _buildInfoButton('Nutrition Information', () {}),
                              ],
                            ),
                            
                            if (product!.description != null && product!.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                                child: Text(
                                  product!.description!,
                                  style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                            const SizedBox(height: Dimensions.paddingSizeLarge),

                            // Variations (Visual Cards)
                            if (product!.variations != null)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: product!.variations!.length,
                                itemBuilder: (context, index) {
                                  return _buildVariationSection(product!.variations![index], index, productController);
                                },
                              ),

                            // Addons (Visual Cards)
                            if (product!.addOns != null && product!.addOns!.isNotEmpty)
                              _buildAddonsSection(product!, productController),

                            const SizedBox(height: 100), // Space for bottom bar
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Bar (Sticky)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Quantity Controls with Circular Buttons
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        child: Row(
                          children: [
                            CircularBackButtonWidget(
                              icon: Icons.remove,
                              size: 40,
                              iconSize: 20,
                              onPressed: () async {
                                if (productController.quantity! > 1) {
                                  productController.setQuantity(false, product!.cartQuantityLimit, product!.stockType, product!.itemStock, widget.isCampaign);
                                } else if (productController.quantity == 1 && productController.cartIndex != -1) {
                                  // Remove item from cart when quantity is 1
                                  final cartCtrl = Get.find<CartController>();
                                  final cartItem = cartCtrl.cartList[productController.cartIndex];
                                  await cartCtrl.removeCartItemOnline(cartItem.id!);
                                  Get.back(); // Close the bottom sheet
                                  showCustomSnackBar('item_removed_from_cart'.tr, isError: false);
                                }
                              },
                            ),
                            SizedBox(
                              width: 40,
                              child: AnimatedTextTransition(
                                value: productController.quantity!,
                                duration: const Duration(milliseconds: 320),
                                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            CircularBackButtonWidget(
                              icon: Icons.add,
                              size: 40,
                              iconSize: 20,
                              onPressed: () => productController.setQuantity(true, product!.cartQuantityLimit, product!.stockType, product!.itemStock, widget.isCampaign),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),

                      // Add to Order Button with Price
                      Expanded(
                        child: GetBuilder<CartController>(
                          builder: (cartController) {
                            final isDisabled = ((!product!.scheduleOrder! && !isAvailable) || (widget.isCampaign && !isAvailable)) ||
                                               (widget.cart != null && productController.checkOutOfStockVariationSelected(product?.variations) != null);

                            String buttonText = ((!product!.scheduleOrder! && !isAvailable) || (widget.isCampaign && !isAvailable)) ? 'not_available_now'.tr
                                : widget.isCampaign ? 'order_now'.tr : (widget.cart != null || productController.cartIndex != -1) ? 'update_in_order'.tr : 'add_to_order'.tr;

                            return Material(
                              color: isDisabled ? Theme.of(context).disabledColor : Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              child: InkWell(
                                onTap: isDisabled ? null : () async {
                                  _onButtonPressed(productController, cartController, priceWithVariation, priceWithDiscount, price, discount, discountType, addOnIdList, addOnsList, priceWithAddonsVariation);
                                },
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault,
                                    vertical: Dimensions.paddingSizeDefault,
                                  ),
                                  child: cartController.isLoading
                                    ? Center(
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Button text (left)
                                          Text(
                                            buttonText,
                                            style: robotoBold.copyWith(
                                              color: Colors.white,
                                              fontSize: Dimensions.fontSizeDefault,
                                            ),
                                          ),
                                          // Animated price (right)
                                          AnimatedTextTransition(
                                            value: PriceConverter.convertPrice(priceWithAddonsVariationWithDiscount),
                                            style: robotoBold.copyWith(
                                              color: Colors.white,
                                              fontSize: Dimensions.fontSizeDefault,
                                            ),
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Text(text, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium!.color)),
      ),
    );
  }

  Widget _buildVariationSection(Variation variation, int index, ProductController productController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(variation.name ?? '', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              if (variation.required!)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Text('Required', style: robotoRegular.copyWith(fontSize: 10, color: Theme.of(context).primaryColor)),
                ),
            ],
          ),
        ),
        Text(
          variation.multiSelect! ? 'Select up to ${variation.max}' : 'Select 1',
          style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        
        // Grid of Options
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: Dimensions.paddingSizeSmall,
            mainAxisSpacing: Dimensions.paddingSizeSmall,
          ),
          itemCount: variation.variationValues!.length,
          itemBuilder: (context, i) {
            final value = variation.variationValues![i];
            final isSelected = productController.selectedVariations[index][i]!;
            
            return InkWell(
              onTap: () {
                productController.setCartVariationIndex(index, i, product, variation.multiSelect!);
                productController.setExistInCartForBottomSheet(product!, productController.selectedVariations);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Placeholder for Option Image (if available in future)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          child: Image.asset(Images.placeholder, fit: BoxFit.cover), // Using placeholder for now
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        value.level ?? '',
                        style: isSelected ? robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall) : robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (value.optionPrice! > 0)
                    Text(
                      '+${PriceConverter.convertPrice(value.optionPrice!)}',
                      style: robotoRegular.copyWith(fontSize: 10, color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ],
    );
  }

  Widget _buildAddonsSection(Product product, ProductController productController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Toppings', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        Text(
          'Optional - Choose up to ${product.addOns!.length}',
          style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: Dimensions.paddingSizeSmall,
            mainAxisSpacing: Dimensions.paddingSizeSmall,
          ),
          itemCount: product.addOns!.length,
          itemBuilder: (context, index) {
            final addon = product.addOns![index];
            final isSelected = productController.addOnActiveList[index];
            
            return InkWell(
              onTap: () {
                 if (!productController.addOnActiveList[index]) {
                    productController.addAddOn(true, index, addon.stockType, addon.addonStock);
                  } else if (productController.addOnQtyList[index] == 1) {
                    productController.addAddOn(false, index, addon.stockType, addon.addonStock);
                  }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          child: Image.asset(Images.placeholder, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        addon.name ?? '',
                        style: isSelected ? robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall) : robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${PriceConverter.convertPrice(addon.price)}',
                      style: robotoRegular.copyWith(fontSize: 10, color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _onButtonPressed(
      ProductController productController, CartController cartController, double priceWithVariation, double priceWithDiscount,
      double price, double? discount, String? discountType, List<AddOn> addOnIdList, List<AddOns> addOnsList,
      double priceWithAddonsVariation,
      ) async {

    // If editing existing cart item, check if anything actually changed
    if (productController.cartIndex != -1 && widget.cart != null) {
      final originalCart = widget.cart!;

      // Check quantity
      final bool quantityChanged = productController.quantity != originalCart.quantity;

      // Check addons (compare actual IDs, not just count)
      final bool addonsChanged = !_areAddonListsEqual(addOnIdList, originalCart.addOnIds!);

      // Check variations (compare selected variations)
      final bool variationsChanged = !_areVariationsEqual(productController.selectedVariations, originalCart.variations!);

      if (!quantityChanged && !addonsChanged && !variationsChanged) {
        // Nothing changed, just close without API call
        print('✅ No changes detected - closing without API call');
        Get.back();
        return;
      }

      print('📝 Changes detected - Quantity: $quantityChanged, Addons: $addonsChanged, Variations: $variationsChanged');
    }

    _processVariationWarning(productController);

    if(productController.canAddToCartProduct) {
      CartModel cartModel = CartModel(
        null, priceWithVariation, priceWithDiscount, (price - PriceConverter.convertWithDiscount(price, discount, discountType)!),
        productController.quantity, addOnIdList, addOnsList, widget.isCampaign, product, productController.selectedVariations,
        product!.cartQuantityLimit, productController.variationsStock,
      );

      OnlineCart onlineCart = await _processOnlineCart(productController, cartController, addOnIdList, addOnsList, priceWithAddonsVariation);

      debugPrint('-------checkout online cart body : ${onlineCart.toJson()}');
      debugPrint('-------checkout cart : ${cartModel.toJson()}');

      if(widget.isCampaign) {
        Get.find<CheckoutController>().updateFirstTime();
        Get.find<CartController>().setNeedExtraPackage(false);
        Get.back();
        Get.toNamed(RouteHelper.getCheckoutRoute('campaign'), arguments: CheckoutScreen(
          fromCart: false, cartList: [cartModel],
        ));
      }else {
        await _executeActions(cartController, productController, cartModel, onlineCart);
      }
    }
  }

  void _processVariationWarning(ProductController productController) {
    if(product!.variations != null && product!.variations!.isNotEmpty){
      for(int index=0; index<product!.variations!.length; index++) {
        if(!product!.variations![index].multiSelect! && product!.variations![index].required!
            && !productController.selectedVariations[index].contains(true)) {
          showCustomSnackBar('${'choose_a_variation_from'.tr} ${product!.variations![index].name}');
          productController.changeCanAddToCartProduct(false);
          return;
        }else if(product!.variations![index].multiSelect! && (product!.variations![index].required!
            || productController.selectedVariations[index].contains(true)) && product!.variations![index].min!
            > productController.selectedVariationLength(productController.selectedVariations, index)) {
          showCustomSnackBar('${'you_need_to_select_minimum'.tr} ${product!.variations![index].min} '
              '${'to_maximum'.tr} ${product!.variations![index].max} ${'options_from'.tr} ${product!.variations![index].name} ${'variation'.tr}');
          productController.changeCanAddToCartProduct(false);
          return;
        } else {
          productController.changeCanAddToCartProduct(true);
        }
      }
    } else if( !widget.isCampaign && product!.variations!.isEmpty && product!.stockType != 'unlimited' && product!.itemStock! <= 0) {
      showCustomSnackBar('product_is_out_of_stock'.tr);
      productController.changeCanAddToCartProduct(false);
      return;
    }
  }

  Future<OnlineCart> _processOnlineCart(ProductController productController, CartController cartController, List<AddOn> addOnIdList, List<AddOns> addOnsList, double priceWithAddonsVariation) async {
    List<OrderVariation> variations = CartHelper.getSelectedVariations(
      productVariations: product!.variations, selectedVariations: productController.selectedVariations,
    ).$1;
    List<int?> optionsIdList = CartHelper.getSelectedVariations(
      productVariations: product!.variations, selectedVariations: productController.selectedVariations,
    ).$2;
    List<int?> listOfAddOnId = CartHelper.getSelectedAddonIds(addOnIdList: addOnIdList);
    List<int?> listOfAddOnQty = CartHelper.getSelectedAddonQtnList(addOnIdList: addOnIdList);

    OnlineCart onlineCart = OnlineCart(
        (widget.cart != null || productController.cartIndex != -1) ? widget.cart?.id ?? cartController.cartList[productController.cartIndex].id : null,
        widget.isCampaign ? null : product!.id, widget.isCampaign ? product!.id : null,
        priceWithAddonsVariation.toString(), variations,
        productController.quantity, listOfAddOnId, addOnsList, listOfAddOnQty, 'Food', variationOptionIds: optionsIdList
    );
    return onlineCart;
  }

  Future<void> _executeActions(CartController cartController, ProductController productController, CartModel cartModel, OnlineCart onlineCart) async {
    if (cartController.existAnotherRestaurantProduct(cartModel.product!.restaurantId)) {
      Get.dialog(ConfirmationDialogWidget(
        icon: Images.warning,
        title: 'are_you_sure_to_reset'.tr,
        description: 'if_you_continue'.tr,
        onYesPressed: () {
          Get.back();
          cartController.clearCartOnline().then((success) async {
            if(success) {
              await cartController.addToCartOnline(onlineCart, existCartData: widget.cart, fromDirectlyAdd: true);
              Get.back();
            }
          });

        },
      ), barrierDismissible: false);
    } else {
      if(widget.cart != null || productController.cartIndex != -1) {
        await cartController.updateCartOnline(onlineCart, existCartData: widget.cart, fromDirectlyAdd: true);
      } else {
        await cartController.addToCartOnline(onlineCart, existCartData: widget.cart, fromDirectlyAdd: true);
      }
      Get.back();
    }
  }

  double _getVariationPriceWithDiscount(Product product, ProductController productController, double? discount, String? discountType) {
    double variationPrice = 0;
    if(product.variations != null){
      for(int index = 0; index< product.variations!.length; index++) {
        for(int i=0; i<product.variations![index].variationValues!.length; i++) {
          if(productController.selectedVariations[index].isNotEmpty && productController.selectedVariations[index][i]!) {
            variationPrice += PriceConverter.convertWithDiscount(product.variations![index].variationValues![i].optionPrice!, discount, discountType)!;
          }
        }
      }
    }
    return variationPrice;
  }

  double _getVariationPrice(Product product, ProductController productController) {
    double variationPrice = 0;
    if(product.variations != null){
      for(int index = 0; index< product.variations!.length; index++) {
        for(int i=0; i<product.variations![index].variationValues!.length; i++) {
          if(productController.selectedVariations[index].isNotEmpty && productController.selectedVariations[index][i]!) {
            variationPrice += PriceConverter.convertWithDiscount(product.variations![index].variationValues![i].optionPrice!, 0, 'none')!;
          }
        }
      }
    }
    return variationPrice;
  }

  double _getAddonCost(Product product, ProductController productController) {
    double addonsCost = 0;

    for (int index = 0; index < product.addOns!.length; index++) {
      if (productController.addOnActiveList[index]) {
        addonsCost = addonsCost + (product.addOns![index].price! * productController.addOnQtyList[index]!);
      }
    }

    return addonsCost;
  }

  List<AddOn> _getAddonIdList(Product product, ProductController productController) {
    List<AddOn> addOnIdList = [];
    for (int index = 0; index < product.addOns!.length; index++) {
      if (productController.addOnActiveList[index]) {
        addOnIdList.add(AddOn(id: product.addOns![index].id, quantity: productController.addOnQtyList[index]));
      }
    }

    return addOnIdList;
  }

  List<AddOns> _getAddonList(Product product, ProductController productController) {
    List<AddOns> addOnsList = [];
    for (int index = 0; index < product.addOns!.length; index++) {
      if (productController.addOnActiveList[index]) {
        addOnsList.add(product.addOns![index]);
      }
    }

    return addOnsList;
  }

  // Compare addon lists for equality
  bool _areAddonListsEqual(List<AddOn> list1, List<AddOn> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      final addon1 = list1[i];
      final addon2 = list2.firstWhereOrNull((a) => a.id == addon1.id);
      if (addon2 == null || addon1.quantity != addon2.quantity) {
        return false;
      }
    }
    return true;
  }

  // Compare variation selections for equality
  bool _areVariationsEqual(List<List<bool?>> variations1, List<List<bool?>> variations2) {
    if (variations1.length != variations2.length) return false;

    for (int i = 0; i < variations1.length; i++) {
      if (variations1[i].length != variations2[i].length) return false;

      for (int j = 0; j < variations1[i].length; j++) {
        if (variations1[i][j] != variations2[i][j]) return false;
      }
    }
    return true;
  }

}


