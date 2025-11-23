import 'dart:convert';
import 'package:get/get.dart';
import 'package:godelivery_user/api/api_client.dart';

import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/features/home/domain/models/advertisement_model.dart';
import 'package:godelivery_user/features/home/domain/repositories/advertisement_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';

class AdvertisementRepository implements AdvertisementRepositoryInterface {
  final ApiClient apiClient;
  final CacheManager cacheManager;
  AdvertisementRepository({required this.apiClient, required this.cacheManager});

  @override
  Future<List<AdvertisementModel>?> getList({int? offset, DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.advertisementListUri,
      schemaVersion: 1,
    );

    // If source is CLIENT, invalidate cache first to force fresh fetch
    if (source == DataSourceEnum.client) {
      await cacheManager.invalidate(cacheKey);
    }

    // Use cache-first strategy (or fetch fresh if cache was just invalidated)
    return await cacheManager.get<List<AdvertisementModel>>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData(AppConstants.advertisementListUri);
        if (response.statusCode == 200) {
          List<AdvertisementModel> advertisementList = [];
          response.body.forEach((data) {
            advertisementList.add(AdvertisementModel.fromJson(data));
          });
          return advertisementList;
        }
        return null;
      },

      deserializer: (json) {
        List<AdvertisementModel> list = [];
        jsonDecode(json).forEach((data) {
          list.add(AdvertisementModel.fromJson(data));
        });
        return list;
      },
    );
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
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

}