import 'package:get/get.dart';
import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';
import 'package:godelivery_user/features/story/domain/repositories/story_repository_interface.dart';
import 'package:godelivery_user/features/story/domain/services/story_service_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoryService implements StoryServiceInterface {
  final StoryRepositoryInterface storyRepositoryInterface;
  final SharedPreferences sharedPreferences;

  StoryService({
    required this.storyRepositoryInterface,
    required this.sharedPreferences,
  });

  @override
  Future<List<StoryCollectionModel>?> getStoryList(
      ) async {
    List<StoryCollectionModel>? storyCollections =
        await storyRepositoryInterface.getList();

    if (storyCollections != null) {
      // Update hasUnseen flag based on local seen state
      for (var collection in storyCollections) {
        if (collection.restaurant?.id != null) {
          collection.hasUnseen = !isRestaurantStorySeen(collection.restaurant!.id!);
        }
      }

      // Filter out collections with no stories
      storyCollections = storyCollections
          .where((collection) => collection.hasStories)
          .toList();
    }

    return storyCollections;
  }

  @override
  Future<bool> markStoryViewed(int storyId, bool completed) async {
    return await storyRepositoryInterface.markStoryViewed(storyId, completed);
  }

  @override
  bool isRestaurantStorySeen(int restaurantId) {
    String key = '${AppConstants.storySeenPrefix}_$restaurantId';
    return sharedPreferences.getBool(key) ?? false;
  }

  @override
  void markRestaurantStorySeen(int restaurantId) {
    String key = '${AppConstants.storySeenPrefix}_$restaurantId';
    sharedPreferences.setBool(key, true);
  }

  @override
  void clearSeenState() {
    // Get all keys and remove story seen keys
    Set<String> keys = sharedPreferences.getKeys();
    for (String key in keys) {
      if (key.startsWith(AppConstants.storySeenPrefix)) {
        sharedPreferences.remove(key);
      }
    }
  }
}