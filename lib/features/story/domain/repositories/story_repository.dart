import 'dart:convert';
import 'package:get/get.dart';
import 'package:godelivery_user/api/api_client.dart';

import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';
import 'package:godelivery_user/features/story/domain/repositories/story_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';

class StoryRepository implements StoryRepositoryInterface {
  final ApiClient apiClient;
  final CacheManager cacheManager;
  StoryRepository({required this.apiClient, required this.cacheManager});

  @override
  Future<List<StoryCollectionModel>?> getList(
      {int? offset, DataSourceEnum? source}) async {
    final cacheKey = CacheKey(
      endpoint: AppConstants.storyFeedUri,
      schemaVersion: 1,
    );

    // If source is CLIENT, invalidate cache first to force fresh fetch
    if (source == DataSourceEnum.client) {
      await cacheManager.invalidate(cacheKey);
      print('📖 [STORY REPO] Cache invalidated, fetching fresh data');
    }

    // Use cache-first strategy (or fetch fresh if cache was just invalidated)
    return await cacheManager.get<List<StoryCollectionModel>>(
      cacheKey,
      fetcher: () async {
        print('📖 [STORY REPO] Calling API: ${AppConstants.storyFeedUri}');
        Response response = await apiClient.getData(AppConstants.storyFeedUri);
        print('📖 [STORY REPO] API Response - Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          List<StoryCollectionModel> storyList = [];
          // API returns {data: [...]} structure
          if (response.body is Map && response.body['data'] != null) {
            final dataList = response.body['data'] as List;
            dataList.forEach((data) {
              storyList.add(StoryCollectionModel.fromJson(data));
            });
          } else if (response.body is List) {
            response.body.forEach((data) {
              storyList.add(StoryCollectionModel.fromJson(data));
            });
          }
          return storyList;
        }
        return null;
      },

      deserializer: (json) {
        List<StoryCollectionModel> list = [];
        final decoded = jsonDecode(json);
        if (decoded is Map && decoded['data'] != null) {
          (decoded['data'] as List).forEach((data) {
            list.add(StoryCollectionModel.fromJson(data));
          });
        } else if (decoded is List) {
          decoded.forEach((data) {
            list.add(StoryCollectionModel.fromJson(data));
          });
        }
        return list;
      },
    );
  }

  @override
  Future<bool> markStoryViewed(int storyId, bool completed) async {
    final sessionKey = await _getOrCreateSessionKey();

    Response response = await apiClient.postData(
      '${AppConstants.storyViewUri}/$storyId/view',
      {
        'session_key': sessionKey,
        'completed': completed,
      },
    );

    print('📖 [STORY VIEW] Tracked view for story $storyId - completed: $completed, session: ${sessionKey.substring(0, 20)}...');
    return response.statusCode == 200;
  }

  /// Generate or retrieve a persistent session key for view tracking
  /// Session key is stored and regenerated daily for privacy
  Future<String> _getOrCreateSessionKey() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final storedDate = prefs.getString('story_session_date');
    final storedKey = prefs.getString('story_session_key');

    // Return existing key if it's from today
    if (storedDate == today && storedKey != null) {
      return storedKey;
    }

    // Generate new session key
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = Platform.operatingSystem;
    final random = DateTime.now().microsecondsSinceEpoch;

    // Create a unique session key: app_{platform}_{timestamp}_{hash}
    final rawKey = '$platform-$timestamp-$random';
    final hash = md5.convert(utf8.encode(rawKey)).toString().substring(0, 8);
    final sessionKey = 'app_${platform}_${timestamp}_$hash';

    // Store for future use (valid for 24 hours)
    await prefs.setString('story_session_key', sessionKey);
    await prefs.setString('story_session_date', today);

    print('📖 [STORY SESSION] Generated new session key: $sessionKey');
    return sessionKey;
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