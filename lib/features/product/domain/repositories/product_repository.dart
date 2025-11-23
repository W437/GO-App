import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/features/product/domain/repositories/product_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:get/get.dart';

class ProductRepository implements ProductRepositoryInterface {
  final ApiClient apiClient;
  ProductRepository({required this.apiClient});

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future<Product?> get(String? id, {bool isCampaign = false}) async {
    Product? product;
    Response response = await apiClient.getData('${AppConstants.productDetailsUri}$id${isCampaign ? '?campaign=true' : ''}');
    if (response.statusCode == 200) {
      product = Product.fromJson(response.body);
    }
    return product;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Product>?> getList({int? offset, String? type}) async {
    Response response = await apiClient.getData('${AppConstants.popularProductUri}?type=$type');
    if (response.statusCode == 200) {
      List<Product> popularProductList = [];
      popularProductList.addAll(ProductModel.fromJson(response.body).products!);
      return popularProductList;
    }
    return null;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }
}
