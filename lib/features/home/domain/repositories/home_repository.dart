import 'dart:convert';
import 'package:godelivery_user/api/api_client.dart';

import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/features/home/domain/models/banner_model.dart';
import 'package:godelivery_user/features/home/domain/models/cashback_model.dart';
import 'package:godelivery_user/features/home/domain/repositories/home_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:get/get_connect.dart';

class HomeRepository implements HomeRepositoryInterface {
  final ApiClient apiClient;
  final CacheManager cacheManager;
  HomeRepository({required this.apiClient, required this.cacheManager});

  @override
  Future<BannerModel?> getList({int? offset, DataSourceEnum? source}) async {
    return await _getBannerList(source: source!);
  }

  Future<BannerModel?> _getBannerList({required DataSourceEnum source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.bannerUri,
      schemaVersion: 1,
    );

    // If source is CLIENT, invalidate cache first to force fresh fetch
    if (source == DataSourceEnum.client) {
      await cacheManager.invalidate(cacheKey);
    }

    // Use cache-first strategy (or fetch fresh if cache was just invalidated)
    return await cacheManager.get<BannerModel>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData(AppConstants.bannerUri);
        if (response.statusCode == 200) {
          print('🔍 BANNER API RESPONSE: ${response.body}');
          return BannerModel.fromJson(response.body);
        }
        return null;
      },

      deserializer: (json) => BannerModel.fromJson(jsonDecode(json)),
    );
  }

  @override
  Future<List<CashBackModel>?> getCashBackOfferList({DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.cashBackOfferListUri,
      schemaVersion: 1,
    );

    return await cacheManager.get<List<CashBackModel>>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData(AppConstants.cashBackOfferListUri);
        if (response.statusCode == 200) {
          List<CashBackModel> cashBackModelList = [];
          response.body.forEach((data) {
            cashBackModelList.add(CashBackModel.fromJson(data));
          });
          return cashBackModelList;
        }
        return null;
      },

      deserializer: (json) {
        List<CashBackModel> list = [];
        jsonDecode(json).forEach((data) {
          list.add(CashBackModel.fromJson(data));
        });
        return list;
      },
    );
  }

  @override
  Future<CashBackModel?> getCashBackData(double amount) async {
    CashBackModel? cashBackModel;
    Response response = await apiClient.getData('${AppConstants.getCashBackAmountUri}?amount=$amount');
    if(response.statusCode == 200) {
      cashBackModel = CashBackModel.fromJson(response.body);
    }
    return cashBackModel;
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