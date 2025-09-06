import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/features/interest/domain/repositories/interest_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:get/get_connect/http/src/response/response.dart';

class InterestRepository implements InterestRepositoryInterface{
  final ApiClient apiClient;
  InterestRepository({required this.apiClient});

  @override
  Future<bool> saveUserInterests(List<int?> interests) async {
    Response response = await apiClient.postData(AppConstants.interestUri, {"interest": interests});
    return response.statusCode == 200;
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
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

}