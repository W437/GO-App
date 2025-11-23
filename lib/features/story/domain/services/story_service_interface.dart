import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';

abstract class StoryServiceInterface {
  Future<List<StoryCollectionModel>?> getStoryList(
      );

  Future<bool> markStoryViewed(int storyId, bool completed);

  bool isRestaurantStorySeen(int restaurantId);

  void markRestaurantStorySeen(int restaurantId);

  void clearSeenState();
}