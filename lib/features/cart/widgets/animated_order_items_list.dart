import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:godelivery_user/features/cart/widgets/order_item_widget.dart';

/// Animated list wrapper for order items
/// Handles smooth removal animations when items are deleted
class AnimatedOrderItemsList extends StatefulWidget {
  const AnimatedOrderItemsList({super.key});

  @override
  State<AnimatedOrderItemsList> createState() => _AnimatedOrderItemsListState();
}

class _AnimatedOrderItemsListState extends State<AnimatedOrderItemsList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<_CachedCartItem> _cachedList = [];
  bool _isSyncing = false;
  int _lastCartLength = 0;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<CartController>();
    _cachedList = List.generate(
      controller.cartList.length,
      (i) => _CachedCartItem(
        cart: controller.cartList[i],
        addOns: controller.addOnsList.length > i
            ? List<AddOns>.from(controller.addOnsList[i])
            : <AddOns>[],
      ),
    );
    _lastCartLength = controller.cartList.length;
  }

  void _syncWithCart(CartController cartController) {
    if (_isSyncing) return;

    final newList = cartController.cartList;

    // Only sync if count actually changed
    if (newList.length == _lastCartLength) return;

    _isSyncing = true;
    _lastCartLength = newList.length;

    // Find removed items (iterate backwards to maintain indices)
    for (int i = _cachedList.length - 1; i >= 0; i--) {
      final oldItem = _cachedList[i];
      final stillExists = newList.any((item) =>
          item.product?.id == oldItem.cart.product?.id &&
          item.variations?.hashCode == oldItem.cart.variations?.hashCode &&
          item.addOnIds?.hashCode == oldItem.cart.addOnIds?.hashCode);

      if (!stillExists) {
        // Capture the item to remove with its data
        final removedItem = _cachedList[i];

        // Remove from cached list first
        _cachedList.removeAt(i);

        // Then trigger animation
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildRemovedItem(removedItem, animation),
          duration: const Duration(milliseconds: 300),
        );

        // Only handle one removal at a time, then exit
        _isSyncing = false;
        return;
      }
    }

    // Find added items
    for (int i = 0; i < newList.length; i++) {
      final newItem = newList[i];
      final alreadyExists = _cachedList.any((item) =>
          item.cart.product?.id == newItem.product?.id &&
          item.cart.variations?.hashCode == newItem.variations?.hashCode &&
          item.cart.addOnIds?.hashCode == newItem.addOnIds?.hashCode);

      if (!alreadyExists) {
        // Item was added - animate it in
        final addOns = cartController.addOnsList.length > i
            ? List<AddOns>.from(cartController.addOnsList[i])
            : <AddOns>[];
        _cachedList.insert(i, _CachedCartItem(cart: newItem, addOns: addOns));
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 300));
        _isSyncing = false;
        return;
      }
    }

    _isSyncing = false;
  }

  Widget _buildRemovedItem(
    _CachedCartItem item,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: OrderItemWidget(
            key: ValueKey('removed_${item.cart.product?.id}_${DateTime.now().millisecondsSinceEpoch}'),
            cart: item.cart,
            cartIndex: 0, // Index doesn't matter for removed item
            addOns: item.addOns,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        // Sync animations with cart state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _syncWithCart(cartController);
          }
        });

        return AnimatedList(
          key: _listKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: _cachedList.length,
          itemBuilder: (context, index, animation) {
            if (index >= _cachedList.length) {
              return const SizedBox.shrink();
            }

            final item = _cachedList[index];

            return SizeTransition(
              sizeFactor: animation,
              child: FadeTransition(
                opacity: animation,
                child: OrderItemWidget(
                  key: ValueKey('${item.cart.product?.id}_${item.cart.variations?.hashCode}_${item.cart.addOnIds?.hashCode}'),
                  cart: item.cart,
                  cartIndex: index,
                  addOns: item.addOns,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Helper class to cache cart items with their add-ons
class _CachedCartItem {
  final CartModel cart;
  final List<AddOns> addOns;

  _CachedCartItem({
    required this.cart,
    required this.addOns,
  });
}
