import 'dart:convert';

import 'package:godelivery_user/api/api_client.dart';

import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/features/notification/domain/models/notification_model.dart';
import 'package:godelivery_user/features/notification/domain/repository/notification_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:get/get_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationRepository implements NotificationRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  final CacheManager cacheManager;
  NotificationRepository({required this.apiClient, required this.sharedPreferences, required this.cacheManager});

  @override
  void saveSeenNotificationCount(int count) {
    sharedPreferences.setInt(AppConstants.notificationCount, count);
  }

  @override
  int? getSeenNotificationCount() {
    return sharedPreferences.getInt(AppConstants.notificationCount);
  }

  @override
  List<int> getNotificationIdList() {
    List<String>? list = [];
    if(sharedPreferences.containsKey(AppConstants.notificationIdList)) {
      list = sharedPreferences.getStringList(AppConstants.notificationIdList);
    }
    List<int> notificationIdList = [];
    for (var id in list!) {
      notificationIdList.add(jsonDecode(id));
    }
    return notificationIdList;
  }

  @override
  void addSeenNotificationIdList(List<int> notificationList) {
    List<String> list = [];
    for (int id in notificationList) {
      list.add(jsonEncode(id));
    }
    sharedPreferences.setStringList(AppConstants.notificationIdList, list);
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
  Future<List<NotificationModel>?> getList({int? offset, DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.notificationUri,
      schemaVersion: 1,
    );

    return await cacheManager.get<List<NotificationModel>>(
      cacheKey,
      fetcher: () async {
        Response response = await apiClient.getData(AppConstants.notificationUri);
        if (response.statusCode == 200) {
          List<NotificationModel> notificationList = [];
          response.body.forEach((notification) {
            notificationList.add(NotificationModel.fromJson(notification));
          });
          return notificationList;
        }
        return null;
      },
      ttl: CacheConfig.defaultTTL,
      deserializer: (json) {
        List<NotificationModel> list = [];
        jsonDecode(json).forEach((notification) {
          list.add(NotificationModel.fromJson(notification));
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