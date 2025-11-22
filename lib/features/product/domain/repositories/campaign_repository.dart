import 'dart:convert';


import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/features/product/domain/models/basic_campaign_model.dart';
import 'package:godelivery_user/features/product/domain/repositories/campaign_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:get/get_connect.dart';

class CampaignRepository implements CampaignRepositoryInterface {
  final ApiClient apiClient;
  final CacheManager cacheManager;

  CampaignRepository({required this.apiClient, required this.cacheManager});

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future<BasicCampaignModel?> get(String? id) {
    return _getCampaignDetails(id!);
  }

  Future<BasicCampaignModel?> _getCampaignDetails(String campaignID) async {
    BasicCampaignModel? campaign;
    Response response = await apiClient.getData('${AppConstants.basicCampaignDetailsUri}$campaignID');
    if (response.statusCode == 200) {
      campaign = BasicCampaignModel.fromJson(response.body);
    }
    return campaign;
  }

  @override
  Future<dynamic> getList({int? offset, bool basicCampaign = false, DataSourceEnum? source}) {
   if(basicCampaign) {
     return _getBasicCampaignList();
   } else {
     return _getItemCampaignList(source: source);
   }
  }
  Future<List<BasicCampaignModel>?> _getBasicCampaignList() async {
    List<BasicCampaignModel>? basicCampaignList;
    Response response = await apiClient.getData(AppConstants.basicCampaignUri);
    if (response.statusCode == 200) {
      basicCampaignList = [];
      response.body.forEach((campaign) => basicCampaignList!.add(BasicCampaignModel.fromJson(campaign)));
    }
    return basicCampaignList;
  }

  Future<List<Product>?> _getItemCampaignList({DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.itemCampaignUri,
      schemaVersion: 1,
    );

    return await cacheManager.get<List<Product>>(
      cacheKey,
      fetcher: () async {
        print('🍔 Fetching item campaigns with headers: ${apiClient.getHeader()}');
        print('🍔 API URL: ${AppConstants.itemCampaignUri}');
        Response response = await apiClient.getData(AppConstants.itemCampaignUri);
        print('🍔 Item campaign response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          List<Product> itemCampaignList = [];
          if (response.body != null && response.body is List) {
            print('🍔 Processing ${(response.body as List).length} campaign items...');
            response.body.forEach((campaign) {
              try {
                Product product = Product.fromJson(campaign);
                itemCampaignList.add(product);
                print('✅ Added product: ${product.name} (ID: ${product.id})');
              } catch (e) {
                print('❌ Error parsing campaign item: $e');
              }
            });
          }
          print('🍔 Item campaigns loaded: ${itemCampaignList.length} items');
          return itemCampaignList;
        } else {
          print('⚠️ Item campaign API failed: ${response.statusText}');
          return null;
        }
      },
      ttl: CacheConfig.defaultTTL,
      deserializer: (json) {
        List<Product> list = [];
        jsonDecode(json).forEach((campaign) {
          list.add(Product.fromJson(campaign));
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