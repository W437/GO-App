import 'dart:convert';


import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/features/restaurant/domain/models/recommended_product_model.dart';
import 'package:godelivery_user/features/restaurant/domain/repositories/restaurant_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:get/get_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestaurantRepository implements RestaurantRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  final CacheManager cacheManager;
  RestaurantRepository({required this.apiClient, required this.sharedPreferences, required this.cacheManager});

  @override
  Future<RecommendedProductModel?> getRestaurantRecommendedItemList(int? restaurantId) async {
    RecommendedProductModel? recommendedProductModel;
    Response response = await apiClient.getData('${AppConstants.restaurantRecommendedItemUri}?restaurant_id=$restaurantId&offset=1&limit=50');
    if (response.statusCode == 200) {
      recommendedProductModel = RecommendedProductModel.fromJson(response.body);
    }
    return recommendedProductModel;
  }

  @override
  Future<List<Product>?> getCartRestaurantSuggestedItemList(int? restaurantID) async {
    List<Product>? suggestedItems;
    Response response = await apiClient.getData('${AppConstants.cartRestaurantSuggestedItemsUri}?restaurant_id=$restaurantID');
    if (response.statusCode == 200) {
      suggestedItems =  [];
      response.body.forEach((product) {
        suggestedItems!.add(Product.fromJson(product));
      });
    }
    return suggestedItems;
  }

  @override
  Future<ProductModel?> getRestaurantProductList(int? restaurantID, int offset, int? categoryID, String type) async {
    ProductModel? productModel;
    Response response = await apiClient.getData(
      '${AppConstants.restaurantProductUri}?restaurant_id=$restaurantID&category_id=$categoryID&offset=$offset&limit=12&type=$type',
    );
    if (response.statusCode == 200) {
      productModel = ProductModel.fromJson(response.body);
    }
    return productModel;
  }

  @override
  Future<ProductModel?> getRestaurantSearchProductList(String searchText, String? storeID, int offset, String type) async {
    ProductModel? restaurantSearchProductModel;
    Response response = await apiClient.getData(
      '${AppConstants.searchUri}products/search?restaurant_id=$storeID&name=$searchText&offset=$offset&limit=10&type=$type',
    );
    if (response.statusCode == 200) {
      restaurantSearchProductModel = ProductModel.fromJson(response.body);
    }
    return restaurantSearchProductModel;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future<Restaurant?> get(String? id, {String slug = '', String? languageCode}) async {
    return await _getRestaurantDetails(id!, slug, languageCode);
  }

  Future<Restaurant?> _getRestaurantDetails(String restaurantID, String slug, String? languageCode) async {
    Restaurant? restaurant;
    Map<String, String>? header;
    if(slug.isNotEmpty){
      header = apiClient.updateHeader(
        sharedPreferences.getString(AppConstants.token), [],
        languageCode, '', '', setHeader: false,
      );
    }
    Response response = await apiClient.getData('${AppConstants.restaurantDetailsUri}${slug.isNotEmpty ? slug : restaurantID}', headers: header);
    if (response.statusCode == 200) {
      restaurant = Restaurant.fromJson(response.body);
    }
    return restaurant;
  }

  @override
  Future<RestaurantModel?> getList({int? offset, String? filterBy, int? topRated, int? discount, int? veg, int? nonVeg, bool fromMap = false, DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: '${AppConstants.restaurantUri}/list',
      params: {
        'offset': offset,
        'limit': fromMap ? 20 : 12,
        'filter_data': filterBy,
        'top_rated': topRated,
        'discount': discount,
        'veg': veg,
        'non_veg': nonVeg,
      },
      schemaVersion: 1,
    );

    return await cacheManager.get<RestaurantModel>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData('${AppConstants.restaurantUri}/all?offset=$offset&limit=${fromMap ? 20 : 12}&filter_data=$filterBy&top_rated=$topRated&discount=$discount&veg=$veg&non_veg=$nonVeg');
        if (response.statusCode == 200) {
          return RestaurantModel.fromJson(response.body);
        }
        return null;
      },

      deserializer: (json) => RestaurantModel.fromJson(jsonDecode(json)),
    );
  }

  @override
  Future<List<Restaurant>?> getRestaurantList({String? type, bool isRecentlyViewed = false, bool isOrderAgain = false, bool isPopular = false, bool isLatest = false, DataSourceEnum? source}) async {
    if(isRecentlyViewed) {
      return _getRecentlyViewedRestaurantList(type!, source: source);
    } else if(isOrderAgain) {
      return _getOrderAgainRestaurantList(source: source);
    } else if(isPopular) {
      return _getPopularRestaurantList(type!, source: source);
    } else if(isLatest) {
      return _getLatestRestaurantList(type!, source: source);
    }
    return null;
  }

  Future<List<Restaurant>?> _getLatestRestaurantList(String type, {DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.latestRestaurantUri,
      params: {'type': type},
      schemaVersion: 1,
    );

    return await cacheManager.get<List<Restaurant>>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData('${AppConstants.latestRestaurantUri}?type=$type');
        if (response.statusCode == 200) {
          List<Restaurant> latestRestaurantList = [];
          response.body.forEach((restaurant) {
            latestRestaurantList.add(Restaurant.fromJson(restaurant));
          });
          return latestRestaurantList;
        }
        return null;
      },

      deserializer: (json) {
        List<Restaurant> list = [];
        jsonDecode(json).forEach((restaurant) {
          list.add(Restaurant.fromJson(restaurant));
        });
        return list;
      },
    );
  }

  Future<List<Restaurant>?> _getPopularRestaurantList(String type, {DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.popularRestaurantUri,
      params: {'type': type},
      schemaVersion: 1,
    );

    return await cacheManager.get<List<Restaurant>>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData('${AppConstants.popularRestaurantUri}?type=$type');
        if (response.statusCode == 200) {
          List<Restaurant> popularRestaurantList = [];
          response.body.forEach((restaurant) {
            popularRestaurantList.add(Restaurant.fromJson(restaurant));
          });
          return popularRestaurantList;
        }
        return null;
      },

      deserializer: (json) {
        List<Restaurant> list = [];
        jsonDecode(json).forEach((restaurant) {
          list.add(Restaurant.fromJson(restaurant));
        });
        return list;
      },
    );
  }

  Future<List<Restaurant>?> _getRecentlyViewedRestaurantList(String type, {DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.recentlyViewedRestaurantUri,
      params: {'type': type},
      schemaVersion: 1,
    );

    return await cacheManager.get<List<Restaurant>>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData('${AppConstants.recentlyViewedRestaurantUri}?type=$type');
        if (response.statusCode == 200) {
          List<Restaurant> recentlyViewedRestaurantList = [];
          response.body.forEach((restaurant) {
            recentlyViewedRestaurantList.add(Restaurant.fromJson(restaurant));
          });
          return recentlyViewedRestaurantList;
        }
        return null;
      },

      deserializer: (json) {
        List<Restaurant> list = [];
        jsonDecode(json).forEach((restaurant) {
          list.add(Restaurant.fromJson(restaurant));
        });
        return list;
      },
    );
  }

  Future<List<Restaurant>?> _getOrderAgainRestaurantList({DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.orderAgainUri,
      schemaVersion: 1,
    );

    return await cacheManager.get<List<Restaurant>>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData(AppConstants.orderAgainUri);
        if (response.statusCode == 200) {
          List<Restaurant> orderAgainRestaurantList = [];
          response.body.forEach((restaurant) {
            orderAgainRestaurantList.add(Restaurant.fromJson(restaurant));
          });
          return orderAgainRestaurantList;
        }
        return null;
      },

      deserializer: (json) {
        List<Restaurant> list = [];
        jsonDecode(json).forEach((restaurant) {
          list.add(Restaurant.fromJson(restaurant));
        });
        return list;
      },
    );
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  
}