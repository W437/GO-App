import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';
import 'package:godelivery_user/interface/repository_interface.dart';

abstract class StoryRepositoryInterface extends RepositoryInterface {
  @override
  Future<List<StoryCollectionModel>?> getList(
      {int? offset, DataSourceEnum? source});

  Future<bool> markStoryViewed(int storyId, bool completed);
}