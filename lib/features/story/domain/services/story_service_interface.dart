import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';

abstract class StoryServiceInterface {
  Future<List<StoryCollectionModel>?> getStoryList(
      {required DataSourceEnum source});

  Future<bool> markStoryViewed(int storyId, bool completed);

  bool isRestaurantStorySeen(int restaurantId);

  void markRestaurantStorySeen(int restaurantId);

  void clearSeenState();
}