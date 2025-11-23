import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';
import 'package:godelivery_user/interface/repository_interface.dart';

abstract class StoryRepositoryInterface extends RepositoryInterface {
  @override
  Future<List<StoryCollectionModel>?> getList(
      {int? offset});

  Future<bool> markStoryViewed(int storyId, bool completed);
}