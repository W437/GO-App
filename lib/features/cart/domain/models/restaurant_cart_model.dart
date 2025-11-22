import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';

/// Model representing a cart for a specific restaurant
/// Groups cart items by restaurant for multi-restaurant cart support
class RestaurantCart {
  final int restaurantId;
  final Restaurant restaurant;
  final List<CartModel> items;
  final double subtotal;
  final String? specialInstructions;
  final bool isActive;

  RestaurantCart({
    required this.restaurantId,
    required this.restaurant,
    required this.items,
    required this.subtotal,
    this.specialInstructions,
    this.isActive = true,
  });

  /// Total number of items in cart (sum of all quantities)
  int get itemCount => items.fold(
        0,
        (sum, item) => sum + (item.quantity ?? 0),
      );

  /// Check if restaurant is currently available for ordering
  bool get canOrder => isActive && restaurant.open == 1;

  /// Create a copy with updated fields
  RestaurantCart copyWith({
    int? restaurantId,
    Restaurant? restaurant,
    List<CartModel>? items,
    double? subtotal,
    String? specialInstructions,
    bool? isActive,
  }) {
    return RestaurantCart(
      restaurantId: restaurantId ?? this.restaurantId,
      restaurant: restaurant ?? this.restaurant,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Clear special instructions
  RestaurantCart clearInstructions() {
    return copyWith(specialInstructions: null);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestaurantCart &&
          runtimeType == other.runtimeType &&
          restaurantId == other.restaurantId;

  @override
  int get hashCode => restaurantId.hashCode;
}
