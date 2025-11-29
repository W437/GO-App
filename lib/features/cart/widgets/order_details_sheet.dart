import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_sheet.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/widgets/order_item_widget.dart';
import 'package:godelivery_user/features/cart/widgets/cart_suggested_item_view_widget.dart';
import 'package:godelivery_user/features/cart/widgets/checkout_button_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Order Details Sheet - Full-screen sheet showing one restaurant's cart
/// Slides up on top of ShoppingCartSheet when user taps "View cart"
class OrderDetailsSheet extends StatefulWidget {
  final bool fromReorder;
  final bool fromDineIn;
  const OrderDetailsSheet({super.key, this.fromReorder = false, this.fromDineIn = false});

  @override
  State<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<OrderDetailsSheet> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return GetBuilder<RestaurantController>(builder: (restaurantController) {
      return GetBuilder<CartController>(builder: (cartController) {
        bool isRestaurantOpen = true;
        if (restaurantController.restaurant != null) {
          isRestaurantOpen = restaurantController.isRestaurantOpenNow(
            restaurantController.restaurant!.active!,
            restaurantController.restaurant!.schedules,
          );
        }

        String restaurantName = restaurantController.restaurant?.name ?? 'Restaurant';

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              // ============================================================
              // CONTENT (Header removed - now handled by CustomFullSheetNavigator)
              // ============================================================
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // MESSAGE TO RESTAURANT SECTION
                        _buildMessageToRestaurantSection(context, cartController),

                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // RESTAURANT UNAVAILABLE NOTICE
                        if (!isRestaurantOpen && restaurantController.restaurant != null)
                          _buildRestaurantUnavailableNotice(
                            context,
                            restaurantController,
                            cartController,
                          ),

                        // Spacing before Order Items
                        if (!isRestaurantOpen && restaurantController.restaurant != null)
                          const SizedBox(height: Dimensions.paddingSizeLarge),

                        // ORDER ITEMS SECTION
                        _buildOrderItemsSection(
                          context,
                          cartController,
                          isRestaurantOpen,
                        ),

                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // RECOMMENDED ITEMS
                        if (!isDesktop)
                          CartSuggestedItemViewWidget(
                            cartList: cartController.cartList,
                          ),

                        const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                      ],
                    ),
                  ),
                ),
              ),

              // ============================================================
              // BOTTOM CHECKOUT BAR WITH GRADIENT BACKDROP
              // ============================================================
              CheckoutButtonWidget(
                cartController: cartController,
                availableList: cartController.availableList,
                isRestaurantOpen: isRestaurantOpen,
                fromDineIn: widget.fromDineIn,
                restaurantName: restaurantName,
              ),
            ],
          ),
        );
      });
    });
  }

  // ==========================================================================
  // UI SECTION BUILDERS
  // ==========================================================================

  /// Message to Restaurant Section
  Widget _buildMessageToRestaurantSection(
    BuildContext context,
    CartController cartController,
  ) {
    // Get saved special instructions
    String? savedInstructions;
    if (cartController.cartList.isNotEmpty) {
      final restaurantId = cartController.cartList[0].product?.restaurantId;
      if (restaurantId != null) {
        final restaurantCart = cartController.getCartForRestaurant(restaurantId);
        savedInstructions = restaurantCart?.specialInstructions;
      }
    }

    final bool hasInstructions = savedInstructions != null && savedInstructions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: InkWell(
        onTap: () => _showMessageDialog(context),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.chat_bubble_text,
              color: hasInstructions ? Colors.green : Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special instructions',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasInstructions
                      ? savedInstructions!
                      : 'Allergies, preferences, or prep requests',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: hasInstructions
                        ? Theme.of(context).textTheme.bodyMedium?.color
                        : Theme.of(context).hintColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).hintColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDialog(BuildContext context) {
    final cartController = Get.find<CartController>();

    // Load existing special instructions if any
    if (cartController.cartList.isNotEmpty) {
      final restaurantId = cartController.cartList[0].product?.restaurantId;
      if (restaurantId != null) {
        final restaurantCart = cartController.getCartForRestaurant(restaurantId);
        _messageController.text = restaurantCart?.specialInstructions ?? '';
      } else {
        _messageController.clear();
      }
    } else {
      _messageController.clear();
    }

    CustomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Text(
              'Special instructions',
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeExtraLarge,
              ),
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Description
          Text(
            'Let the kitchen know about allergies, preferences, or how you want your food prepared.',
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).hintColor,
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Text input field
          TextField(
            controller: _messageController,
            autofocus: true, // Auto-opens keyboard
            maxLength: 400,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type your message here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              counterStyle: robotoRegular.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Done button - Full width
          CustomButtonWidget(
            buttonText: 'Done',
            radius: Dimensions.radiusDefault,
            onPressed: () {
              final cartController = Get.find<CartController>();

              // Get restaurant ID from first cart item
              if (cartController.cartList.isNotEmpty) {
                final restaurantId = cartController.cartList[0].product?.restaurantId;
                if (restaurantId != null) {
                  // Save special instructions
                  cartController.setCartSpecialInstructions(
                    restaurantId,
                    _messageController.text.trim(),
                  );
                }
              }

              // Dismiss keyboard
              FocusScope.of(context).unfocus();

              // Close the dialog
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantUnavailableNotice(
    BuildContext context,
    RestaurantController restaurantController,
    CartController cartController,
  ) {
    final String openingTime = restaurantController.restaurant!.restaurantOpeningTime == 'closed'
        ? 'tomorrow'.tr
        : DateConverter.timeStringToTime(restaurantController.restaurant!.restaurantOpeningTime!);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeLarge,
          vertical: Dimensions.paddingSizeDefault + 6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.time,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'Restaurant Currently Closed',
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault + 1,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Opens at ',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall + 1,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  TextSpan(
                    text: openingTime,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall + 1,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection(
    BuildContext context,
    CartController cartController,
    bool isRestaurantOpen,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order items',
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete all button - only show when restaurant is closed
                  if (!isRestaurantOpen)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: cartController.isClearCartLoading ? null : () => cartController.clearCartOnline(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: cartController.isClearCartLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                )
                              : Icon(
                                  CupertinoIcons.trash,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                                ),
                        ),
                      ),
                    ),
                  if (!isRestaurantOpen)
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  // Add more button
                  CustomButtonWidget(
                    expand: false,
                    buttonText: '+ Add more',
                    onPressed: () {
                      if (isRestaurantOpen && cartController.cartList.isNotEmpty) {
                        Get.toNamed(
                          RouteHelper.getRestaurantRoute(
                            cartController.cartList[0].product!.restaurantId,
                          ),
                          arguments: RestaurantScreen(
                            restaurant: Restaurant(
                              id: cartController.cartList[0].product!.restaurantId,
                            ),
                          ),
                        );
                      }
                    },
                    height: 32,
                    width: 110,
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                    textColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Column(
            children: List.generate(
              cartController.cartList.length,
              (index) {
                return OrderItemWidget(
                  cart: cartController.cartList[index],
                  cartIndex: index,
                  addOns: cartController.addOnsList[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
