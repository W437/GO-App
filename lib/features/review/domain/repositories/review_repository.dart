import 'dart:convert';


import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/models/response_model.dart';
import 'package:godelivery_user/common/models/review_model.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/features/product/domain/models/review_body_model.dart';
import 'package:godelivery_user/features/review/domain/repositories/review_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:get/get.dart';

class ReviewRepository implements ReviewRepositoryInterface {
  final ApiClient apiClient;
  final CacheManager cacheManager;
  ReviewRepository({required this.apiClient, required this.cacheManager});

  @override
  Future<ResponseModel> submitReview(ReviewBodyModel reviewBody, bool isProduct) async {
    if(isProduct) {
      return _submitReview(reviewBody);
    } else {
      return _submitDeliveryManReview(reviewBody);
    }
  }

  @override
  Future<List<Product>?> getList({int? offset, String? type, DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.reviewedProductUri,
      params: {'type': type},
      schemaVersion: 1,
    );

    return await cacheManager.get<List<Product>>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData('${AppConstants.reviewedProductUri}?type=$type');
        if (response.statusCode == 200) {
          List<Product> reviewedProductList = [];
          reviewedProductList.addAll(ProductModel.fromJson(response.body).products!);
          return reviewedProductList;
        }
        return null;
      },
      ttl: CacheConfig.defaultTTL,
      deserializer: (json) {
        return ProductModel.fromJson(jsonDecode(json)).products!;
      },
    );
  }

  Future<ResponseModel> _submitReview(ReviewBodyModel reviewBody) async {
    Response response = await apiClient.postData(AppConstants.reviewUri, reviewBody.toJson(), handleError: false);
    if (response.statusCode == 200) {
      return ResponseModel(true, 'review_submitted_successfully'.tr);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  Future<ResponseModel> _submitDeliveryManReview(ReviewBodyModel reviewBody) async {
    Response response = await apiClient.postData(AppConstants.deliveryManReviewUri, reviewBody.toJson(), handleError: false);
    if (response.statusCode == 200) {
      return ResponseModel(true, 'review_submitted_successfully'.tr);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<List<ReviewModel>?> getRestaurantReviewList(String? restaurantID) async {
    List<ReviewModel>? restaurantReviewList;
    Response response = await apiClient.getData('${AppConstants.restaurantReviewUri}?restaurant_id=$restaurantID');
    if (response.statusCode == 200) {
      restaurantReviewList = [];
      response.body.forEach((review) => restaurantReviewList!.add(ReviewModel.fromJson(review)));
    }
    return restaurantReviewList;
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