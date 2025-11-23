import 'dart:convert';
import 'package:godelivery_user/api/api_client.dart';

import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/features/cuisine/domain/models/cuisine_model.dart';
import 'package:godelivery_user/features/cuisine/domain/models/cuisine_restaurants_model.dart';
import 'package:godelivery_user/features/cuisine/domain/repositories/cuisine_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:get/get_connect/connect.dart';

class CuisineRepository implements CuisineRepositoryInterface {
  final ApiClient apiClient;
  final CacheManager cacheManager;
  CuisineRepository({required this.apiClient, required this.cacheManager});

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future<CuisineModel?> getList({int? offset, DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.cuisineUri,
      schemaVersion: 1,
    );

    // If source is CLIENT, invalidate cache first to force fresh fetch
    if (source == DataSourceEnum.client) {
      await cacheManager.invalidate(cacheKey);
    }

    // Use cache-first strategy (or fetch fresh if cache was just invalidated)
    return await cacheManager.get<CuisineModel>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData(AppConstants.cuisineUri);
        if (response.statusCode == 200) {
          return CuisineModel.fromJson(response.body);
        }
        return null;
      },

      deserializer: (json) => CuisineModel.fromJson(jsonDecode(json)),
    );
  }

  @override
  Future<CuisineRestaurantModel?> getRestaurantList(int offset, int cuisineId) async {
    CuisineRestaurantModel? cuisineRestaurantsModel;
    Response response = await apiClient.getData('${AppConstants.cuisineRestaurantUri}?cuisine_id=$cuisineId&offset=$offset&limit=10');
    if(response.statusCode == 200) {
      cuisineRestaurantsModel = CuisineRestaurantModel.fromJson(response.body);
    }
    return cuisineRestaurantsModel;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

}