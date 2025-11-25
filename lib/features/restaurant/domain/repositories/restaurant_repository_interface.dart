import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/home/domain/models/home_feed_model.dart';
import 'package:godelivery_user/features/restaurant/domain/models/recommended_product_model.dart';
import 'package:godelivery_user/interface/repository_interface.dart';

abstract class RestaurantRepositoryInterface extends RepositoryInterface {
  @override
  Future<Restaurant?> get(String? id, {String slug = '', String? languageCode});
  @override
  Future<RestaurantModel?> getList({int? offset, String? filterBy, int? topRated, int? discount, int? veg, int? nonVeg, bool fromMap = false});
  Future<List<Restaurant>?> getRestaurantList({String? type, bool isRecentlyViewed = false, bool isOrderAgain = false, bool isPopular = false, bool isLatest = false});
  Future<RecommendedProductModel?> getRestaurantRecommendedItemList(int? restaurantId);
  Future<List<Product>?> getCartRestaurantSuggestedItemList(int? restaurantID);
  Future<ProductModel?> getRestaurantProductList(int? restaurantID, int offset, int? categoryID, String type);
  Future<ProductModel?> getRestaurantSearchProductList(String searchText, String? storeID, int offset, String type);
  Future<HomeFeedModel?> getHomeFeed();
  Future<HomeFeedSectionResponse?> getHomeFeedSection(String section, {int? categoryId, int offset = 1});
}
