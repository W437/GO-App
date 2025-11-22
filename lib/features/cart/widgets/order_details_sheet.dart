import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
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
                    'Special instructions',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Allergies, preferences, or prep requests',
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusDefault),
            ),
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

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
                onPressed: () {
                  // TODO: Save to CheckoutController session
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
              ),
            ],
          ),
        ),
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

    return Column(
      children: [
        // Unavailable notice
        Container(
          margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Column(
            children: [
              Icon(
                CupertinoIcons.time,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                'Restaurant Currently Closed',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Opens at ',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    TextSpan(
                      text: openingTime,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Remove from cart button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: CustomButtonWidget(
            buttonText: cartController.cartList.length > 1
                ? 'remove_all_from_cart'.tr
                : 'remove_from_cart'.tr,
            onPressed: () => cartController.clearCartOnline(),
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            textColor: Theme.of(context).colorScheme.error,
            icon: CupertinoIcons.delete,
            isLoading: cartController.isClearCartLoading,
          ),
        ),
      ],
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
              return OrderItemWidget(
                cart: cartController.cartList[index],
                cartIndex: index,
                addOns: cartController.addOnsList[index],
              );
            },
          ),
        ],
      ),
    );
  }
}
