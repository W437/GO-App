import 'package:get/get.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/features/home/domain/models/advertisement_model.dart';
import 'package:godelivery_user/features/home/domain/repositories/advertisement_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';

class AdvertisementRepository implements AdvertisementRepositoryInterface {
  final ApiClient apiClient;
  AdvertisementRepository({required this.apiClient});

  @override
  Future<List<AdvertisementModel>?> getList({int? offset}) async {
    Response response = await apiClient.getData(AppConstants.advertisementListUri);
    if (response.statusCode == 200) {
      List<AdvertisementModel> advertisementList = [];
      response.body.forEach((data) {
        advertisementList.add(AdvertisementModel.fromJson(data));
      });
      return advertisementList;
    }
    return null;
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
