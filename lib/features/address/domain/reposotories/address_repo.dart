import 'dart:convert';

import 'package:godelivery_user/api/api_client.dart';

import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/common/models/response_model.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/address/domain/reposotories/address_repo_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:get/get.dart';

class AddressRepo implements AddressRepoInterface<AddressModel> {
  final ApiClient apiClient;
  final CacheManager cacheManager;

  AddressRepo({required this.apiClient, required this.cacheManager});

  @override
  Future<List<AddressModel>?> getList({int? offset, bool isLocal = false, DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.addressListUri,
      schemaVersion: 1,
    );

    return await cacheManager.get<List<AddressModel>>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData(AppConstants.addressListUri);
        if (response.statusCode == 200) {
          List<AddressModel> addressList = [];
          response.body['addresses'].forEach((address) {
            addressList.add(AddressModel.fromJson(address));
          });
          return addressList;
        }
        return null;
      },

      deserializer: (json) {
        List<AddressModel> list = [];
        jsonDecode(json).forEach((address) {
          list.add(AddressModel.fromJson(address));
        });
        return list;
      },
    );
  }

  @override
  Future add(AddressModel addressModel) async {
    Response response = await apiClient.postData(AppConstants.addAddressUri, addressModel.toJson(), handleError: false);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      String? message = response.body["message"];
      List<int> zoneIds = [];
      response.body['zone_ids'].forEach((z) => zoneIds.add(z));
      responseModel = ResponseModel(true, message, zoneIds: zoneIds);
    } else {
      responseModel = ResponseModel(false,
          response.statusText == 'Out of coverage!' ? 'service_not_available_in_this_area'.tr : response.statusText);
    }
    return responseModel;
  }

  @override
  Future<ResponseModel> update(Map<String, dynamic> body, int? addressId) async {
    Response response = await apiClient.putData('${AppConstants.updateAddressUri}$addressId', body, handleError: false);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }

  @override
  Future<ResponseModel> delete(int? id) async {
    ResponseModel responseModel;
    Response response = await apiClient.postData('${AppConstants.removeAddressUri}$id', {"_method": "delete"}, handleError: false);
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body['message']);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }
}
