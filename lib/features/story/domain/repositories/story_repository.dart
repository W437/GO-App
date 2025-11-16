import 'dart:convert';
import 'package:get/get.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/api/local_client.dart';
import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';
import 'package:godelivery_user/features/story/domain/repositories/story_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';

class StoryRepository implements StoryRepositoryInterface {
  final ApiClient apiClient;
  StoryRepository({required this.apiClient});

  @override
  Future<List<StoryCollectionModel>?> getList(
      {int? offset, DataSourceEnum? source}) async {
    List<StoryCollectionModel>? storyList;
    String cacheId = AppConstants.storyFeedUri;

    switch (source!) {
      case DataSourceEnum.client:
        print('📖 [STORY REPO] Calling API: ${AppConstants.storyFeedUri}');
        Response response = await apiClient.getData(AppConstants.storyFeedUri);
        print('📖 [STORY REPO] API Response - Status: ${response.statusCode}');
        print('📖 [STORY REPO] API Response - Body type: ${response.body.runtimeType}');

        if (response.statusCode == 200) {
          storyList = [];

          // API returns {data: [...]} structure
          if (response.body is Map && response.body['data'] != null) {
            final dataList = response.body['data'] as List;
            print('📖 [STORY REPO] ✅ Found ${dataList.length} story collections in data array');

            dataList.forEach((data) {
              final collection = StoryCollectionModel.fromJson(data);
              storyList?.add(collection);

              // Debug: Show how many stories per restaurant
              final restaurantName = collection.restaurant?.name ?? 'Unknown';
              final storiesCount = collection.stories?.length ?? 0;
              print('📖 [STORY REPO] Restaurant "$restaurantName" has $storiesCount stories');

              // Debug: Show each story's media count
              if (collection.stories != null) {
                for (int i = 0; i < collection.stories!.length; i++) {
                  final story = collection.stories![i];
                  final mediaCount = story.media?.length ?? 0;
                  print('   Story ${i + 1} (id: ${story.id}): "$story.title" - $mediaCount media items');
                }
              }
            });

            // Cache the data array for local storage
            LocalClient.organize(DataSourceEnum.client, cacheId,
                jsonEncode(response.body['data']), apiClient.getHeader());
          } else if (response.body is List) {
            // Fallback for direct array response
            print('📖 [STORY REPO] ✅ Body is a direct List with ${response.body.length} items');
            response.body.forEach((data) {
              storyList?.add(StoryCollectionModel.fromJson(data));
            });
            LocalClient.organize(DataSourceEnum.client, cacheId,
                jsonEncode(response.body), apiClient.getHeader());
          } else {
            print('📖 [STORY REPO] ❌ Unexpected response structure! Type: ${response.body.runtimeType}');
            print('📖 [STORY REPO] Body content: ${response.body}');
          }
        } else {
          print('📖 [STORY REPO] ❌ API error: ${response.statusText} - ${response.body}');
        }
      case DataSourceEnum.local:
        String? cacheResponseData =
            await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if (cacheResponseData != null) {
          storyList = [];
          jsonDecode(cacheResponseData).forEach((data) {
            storyList?.add(StoryCollectionModel.fromJson(data));
          });
        }
    }

    return storyList;
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