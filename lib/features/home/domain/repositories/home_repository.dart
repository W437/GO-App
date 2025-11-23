import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/features/home/domain/models/banner_model.dart';
import 'package:godelivery_user/features/home/domain/models/cashback_model.dart';
import 'package:godelivery_user/features/home/domain/repositories/home_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:get/get_connect.dart';

class HomeRepository implements HomeRepositoryInterface {
  final ApiClient apiClient;
  HomeRepository({required this.apiClient});

  @override
  Future<BannerModel?> getList({int? offset}) async {
    Response response = await apiClient.getData(AppConstants.bannerUri);
    if (response.statusCode == 200) {
      return BannerModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<List<CashBackModel>?> getCashBackOfferList() async {
    Response response = await apiClient.getData(AppConstants.cashBackOfferListUri);
    if (response.statusCode == 200) {
      List<CashBackModel> cashBackModelList = [];
      response.body.forEach((data) {
        cashBackModelList.add(CashBackModel.fromJson(data));
      });
      return cashBackModelList;
    }
    return null;
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
