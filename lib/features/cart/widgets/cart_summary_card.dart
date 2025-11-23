import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:godelivery_user/common/widgets/shared/modals/animated_modal_widget.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class CartSummaryCard extends StatelessWidget {
  final String restaurantName;
  final String restaurantLogo;
  final String? deliveryTime;
  final double subtotal;
  final List<String> itemImages;
  final VoidCallback onViewCart;
  final VoidCallback? onAddMore; // Navigate to restaurant menu
  final VoidCallback? onDeleteCart; // Delete entire cart
  final String buttonText;
  final bool isOffline;

  const CartSummaryCard({
    super.key,
    required this.restaurantName,
    required this.restaurantLogo,
    this.deliveryTime,
    required this.subtotal,
    required this.itemImages,
    required this.onViewCart,
    this.onAddMore,
    this.onDeleteCart,
    this.buttonText = 'View cart',
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  child: CustomImageWidget(
                    image: restaurantLogo,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurantName,
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOffline ? 'Temporarily offline' : 'Delivery in $deliveryTime',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: isOffline ? Theme.of(context).disabledColor : Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu button
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Theme.of(context).primaryColor),
                  onPressed: () => _showCartMenu(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Items Preview
          if (itemImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: itemImages.length,
                  separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: CustomImageWidget(
                        image: itemImages[index],
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Subtotal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Row(
              children: [
                Text(
                  'Item subtotal: ',
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
                Text(
                  PriceConverter.convertPrice(subtotal),
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
            child: CustomButtonWidget(
              buttonText: buttonText,
              onPressed: onViewCart,
              height: 45,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              textColor: Theme.of(context).primaryColor,
              radius: Dimensions.radiusDefault,
              isBold: false,
            ),
          ),
        ],
      ),
    );
  }

  /// Show cart menu with actions
  void _showCartMenu(BuildContext context) {
    AnimatedModalWidget.show(
      context: context,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.4),
              blurRadius: 4,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              blurRadius: 13,
              spreadRadius: -3,
              offset: Offset(0, 7),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.2),
              blurRadius: 0,
              spreadRadius: 0,
              offset: Offset(0, -3),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 1.0),
              blurRadius: 0,
              spreadRadius: 0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeDefault,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add more items
              if (onAddMore != null) ...[
                CustomButtonWidget(
                  buttonText: 'Add more items',
                  icon: Icons.add_circle_outline,
                  color: Theme.of(context).disabledColor.withOpacity(0.1),
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                  iconColor: Theme.of(context).primaryColor,
                  radius: Dimensions.radiusDefault,
                  onPressed: () {
                    Get.back();
                    onAddMore?.call();
                  },
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
              ],

              // Delete cart
              if (onDeleteCart != null) ...[
                CustomButtonWidget(
                  buttonText: 'Delete cart',
                  icon: CupertinoIcons.delete,
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  textColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                  radius: Dimensions.radiusDefault,
                  onPressed: () {
                    Get.back();
                    _showDeleteConfirmation(context);
                  },
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
              ],

              // Cancel
              CustomButtonWidget(
                buttonText: 'Cancel',
                icon: Icons.close,
                color: Theme.of(context).disabledColor.withOpacity(0.1),
                textColor: Theme.of(context).hintColor,
                iconColor: Theme.of(context).hintColor,
                radius: Dimensions.radiusDefault,
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show confirmation dialog before deleting cart
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete cart?'),
        content: Text(
          'Are you sure you want to delete all items from $restaurantName?',
          style: robotoRegular,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onDeleteCart?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
