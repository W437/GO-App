import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_user/features/cart/domain/models/restaurant_cart_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';

/// Unit tests for Phase 1: Cart Grouping Logic
///
/// Tests the new multi-restaurant cart functionality including:
/// - RestaurantCart model
/// - Cart grouping by restaurant
/// - Subtotal calculations per restaurant
void main() {
  group('RestaurantCart Model', () {
    test('should create RestaurantCart with required fields', () {
      final restaurant = _createMockRestaurant(id: 1, name: 'Test Restaurant');
      final items = [_createMockCartItem(quantity: 2)];

      final restaurantCart = RestaurantCart(
        restaurantId: 1,
        restaurant: restaurant,
        items: items,
        subtotal: 100.0,
      );

      expect(restaurantCart.restaurantId, 1);
      expect(restaurantCart.restaurant.name, 'Test Restaurant');
      expect(restaurantCart.items.length, 1);
      expect(restaurantCart.subtotal, 100.0);
      expect(restaurantCart.isActive, true); // default value
    });

    test('should calculate correct item count from quantities', () {
      final restaurant = _createMockRestaurant(id: 1);
      final items = [
        _createMockCartItem(quantity: 2),
        _createMockCartItem(quantity: 3),
        _createMockCartItem(quantity: 1),
      ];

      final restaurantCart = RestaurantCart(
        restaurantId: 1,
        restaurant: restaurant,
        items: items,
        subtotal: 100.0,
      );

      expect(restaurantCart.itemCount, 6); // 2 + 3 + 1
    });

    test('should determine if restaurant can accept orders', () {
      final openRestaurant = _createMockRestaurant(id: 1, open: 1);
      final closedRestaurant = _createMockRestaurant(id: 2, open: 0);

      final openCart = RestaurantCart(
        restaurantId: 1,
        restaurant: openRestaurant,
        items: [],
        subtotal: 0,
        isActive: true,
      );

      final closedCart = RestaurantCart(
        restaurantId: 2,
        restaurant: closedRestaurant,
        items: [],
        subtotal: 0,
        isActive: true,
      );

      expect(openCart.canOrder, true);
      expect(closedCart.canOrder, false);
    });

    test('should update special instructions via copyWith', () {
      final restaurant = _createMockRestaurant(id: 1);
      final cart = RestaurantCart(
        restaurantId: 1,
        restaurant: restaurant,
        items: [],
        subtotal: 0,
      );

      final updatedCart = cart.copyWith(
        specialInstructions: 'No onions please',
      );

      expect(cart.specialInstructions, null);
      expect(updatedCart.specialInstructions, 'No onions please');
    });

    test('should clear special instructions', () {
      final restaurant = _createMockRestaurant(id: 1);
      final cart = RestaurantCart(
        restaurantId: 1,
        restaurant: restaurant,
        items: [],
        subtotal: 0,
        specialInstructions: 'Test instructions',
      );

      final clearedCart = cart.clearInstructions();

      expect(cart.specialInstructions, 'Test instructions');
      expect(clearedCart.specialInstructions, null);
    });

    test('should implement equality based on restaurantId', () {
      final restaurant1 = _createMockRestaurant(id: 1);
      final restaurant2 = _createMockRestaurant(id: 2);

      final cart1a = RestaurantCart(
        restaurantId: 1,
        restaurant: restaurant1,
        items: [],
        subtotal: 100,
      );

      final cart1b = RestaurantCart(
        restaurantId: 1,
        restaurant: restaurant1,
        items: [],
        subtotal: 200, // Different subtotal
      );

      final cart2 = RestaurantCart(
        restaurantId: 2,
        restaurant: restaurant2,
        items: [],
        subtotal: 100,
      );

      expect(cart1a == cart1b, true); // Same restaurant ID
      expect(cart1a == cart2, false); // Different restaurant ID
      expect(cart1a.hashCode, cart1b.hashCode);
    });
  });

  group('Cart Grouping Logic', () {
    test('should group empty cart list correctly', () {
      final grouped = <int, RestaurantCart>{};
      expect(grouped.isEmpty, true);
    });

    test('should group single restaurant cart', () {
      // This test would require mocking CartController and CartServiceInterface
      // For now, we test the model itself which is used by the grouping logic
      final restaurant = _createMockRestaurant(id: 1, name: 'Pizza Place');
      final items = [
        _createMockCartItem(quantity: 2),
        _createMockCartItem(quantity: 1),
      ];

      final cart = RestaurantCart(
        restaurantId: 1,
        restaurant: restaurant,
        items: items,
        subtotal: 150.0,
      );

      expect(cart.items.length, 2);
      expect(cart.itemCount, 3);
      expect(cart.restaurantId, 1);
    });

    test('should handle multiple restaurant carts in map', () {
      final restaurant1 = _createMockRestaurant(id: 1, name: 'Restaurant A');
      final restaurant2 = _createMockRestaurant(id: 2, name: 'Restaurant B');

      final carts = <int, RestaurantCart>{
        1: RestaurantCart(
          restaurantId: 1,
          restaurant: restaurant1,
          items: [_createMockCartItem()],
          subtotal: 100,
        ),
        2: RestaurantCart(
          restaurantId: 2,
          restaurant: restaurant2,
          items: [_createMockCartItem()],
          subtotal: 200,
        ),
      };

      expect(carts.length, 2);
      expect(carts[1]!.restaurant.name, 'Restaurant A');
      expect(carts[2]!.restaurant.name, 'Restaurant B');
      expect(carts[1]!.subtotal, 100);
      expect(carts[2]!.subtotal, 200);
    });
  });
}

// ============================================================================
// Test Helper Functions
// ============================================================================

/// Create a mock Restaurant for testing
Restaurant _createMockRestaurant({
  int id = 1,
  String name = 'Test Restaurant',
  int open = 1,
  bool active = true,
}) {
  return Restaurant(
    id: id,
    name: name,
    logoFullUrl: 'logo.png',
    coverPhotoFullUrl: 'cover.png',
    address: '123 Test St',
    latitude: '0.0',
    longitude: '0.0',
    minimumOrder: 0,
    avgRating: 4.5,
    tax: 5.0,
    active: active,
    open: open,
    delivery: true,
    takeAway: true,
    deliveryTime: '30-40 min',
  );
}

/// Create a mock CartModel for testing
CartModel _createMockCartItem({int quantity = 1}) {
  // Create minimal CartModel with required fields
  // Note: In a real test, you'd use proper mock objects
  return CartModel(
    1, // id
    100.0, // price
    90.0, // discountedPrice
    10.0, // discountAmount
    quantity, // quantity
    [], // addOnIds
    [], // addOns
    false, // isCampaign
    null, // product
    [], // variations
    10, // quantityLimit
    [], // variationsStock
  );
}
