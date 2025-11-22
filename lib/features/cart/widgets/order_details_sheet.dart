import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/widgets/cart_product_widget.dart';
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
          body: SafeArea(
            child: Column(
              children: [
                // ============================================================
                // HEADER: Back button + Restaurant name + Subtitle
                // ============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeDefault,
                  ),
                  child: Row(
                    children: [
                      // Circular back button with down arrow
                      CircularBackButtonWidget(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onPressed: () => Get.back(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              restaurantName,
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeOverLarge,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your order',
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).hintColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 44), // Balance for back button
                    ],
                  ),
                ),

                // ============================================================
                // CONTENT
                // ============================================================
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
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

                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ),

                // ============================================================
                // BOTTOM CHECKOUT BAR
                // ============================================================
                CheckoutButtonWidget(
                  cartController: cartController,
                  availableList: cartController.availableList,
                  isRestaurantOpen: isRestaurantOpen,
                  fromDineIn: widget.fromDineIn,
                ),
              ],
            ),
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
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a message for the restaurant',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Special requests, allergies, dietary restrictions?',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
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
    _messageController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message to restaurant'),
        content: TextField(
          controller: _messageController,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'E.g., No onions, extra spicy, allergies...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                Get.snackbar(
                  'Saved',
                  'Your message will be included with the order',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              }
              Get.back();
            },
            child: const Text('Save'),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'This restaurant is currently unavailable. It will be available at ',
                  style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                ),
                TextSpan(
                  text: restaurantController.restaurant!.restaurantOpeningTime == 'closed'
                      ? 'tomorrow'.tr
                      : DateConverter.timeStringToTime(
                          restaurantController.restaurant!.restaurantOpeningTime!),
                  style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          InkWell(
            onTap: () => cartController.clearCartOnline(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                border: Border.all(
                  width: 1,
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                ),
              ),
              child: cartController.isClearCartLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.delete_solid,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Text(
                          cartController.cartList.length > 1
                              ? 'remove_all_from_cart'.tr
                              : 'remove_from_cart'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(
    BuildContext context,
    CartController cartController,
    bool isRestaurantOpen,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order items',
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              TextButton(
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
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '+ Add more',
                  style: robotoMedium.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: cartController.cartList.length,
            itemBuilder: (context, index) {
              return CartProductWidget(
                cart: cartController.cartList[index],
                cartIndex: index,
                addOns: cartController.addOnsList[index],
                isAvailable: cartController.availableList[index],
                isRestaurantOpen: isRestaurantOpen,
              );
            },
          ),
        ],
      ),
    );
  }
}
