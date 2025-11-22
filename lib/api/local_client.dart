/// Local data storage and caching client
/// Manages offline data persistence using Drift database for mobile and SharedPreferences for web
/// Provides unified interface for storing and retrieving cached API responses
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/data_source/cache_response.dart';
import 'package:godelivery_user/helper/utilities/db_helper.dart';

class LocalClient {

  /// Check if cached data is expired based on TTL (Time-To-Live) in seconds
  /// Returns true if cache is expired or doesn't exist
  static Future<bool> isCacheExpired(String cacheId, int ttlSeconds) async {
    try {
      if (GetPlatform.isWeb) {
        SharedPreferences sharedPreferences = Get.find();
        String? timestampStr = sharedPreferences.getString('${cacheId}_timestamp');
        if (timestampStr == null) return true;

        DateTime cachedAt = DateTime.parse(timestampStr);
        DateTime now = DateTime.now();
        int ageInSeconds = now.difference(cachedAt).inSeconds;

        return ageInSeconds > ttlSeconds;
      } else {
        final CacheResponseData? cacheData = await database.getCacheResponseById(cacheId);
        if (cacheData == null || cacheData.createdAt == null) return true;

        DateTime now = DateTime.now();
        int ageInSeconds = now.difference(cacheData.createdAt!).inSeconds;

        return ageInSeconds > ttlSeconds;
      }
    } catch (e) {
      if (kDebugMode) {
        print('=====error checking cache expiry: $e');
      }
      return true; // Treat errors as expired
    }
  }

  static Future<String?> organize(DataSourceEnum source, String cacheId, String? responseBody, Map<String, String>? header) async {
    SharedPreferences sharedPreferences = Get.find();
    switch(source) {
      case DataSourceEnum.client:
        try{
          if(GetPlatform.isWeb) {
            await sharedPreferences.setString(cacheId, responseBody??'');
            await sharedPreferences.setString('${cacheId}_timestamp', DateTime.now().toIso8601String());
          } else {
            DbHelper.insertOrUpdate(
              id: cacheId,
              data: CacheResponseCompanion(
                endPoint: drift.Value(cacheId),
                header: drift.Value(header.toString()),
                response: drift.Value(responseBody??''),
              ),
            );
          }
        } catch(e) {
          if (kDebugMode) {
            print('=====error occure in repo add api data: $e');
          }
        }
      case DataSourceEnum.local:
        try {
          if(GetPlatform.isWeb) {
            String? cacheData = sharedPreferences.getString(cacheId);
            return cacheData;
          } else {
            final CacheResponseData? cacheResponseData = await database.getCacheResponseById(cacheId);
            return cacheResponseData?.response;
          }

        } catch (e) {
          if (kDebugMode) {
            print('=====error occur in get local data repo: $e');
          }
        }
    }
    return null;
  }
}