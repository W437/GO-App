import 'dart:convert';
import 'package:get/get.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/api/local_client.dart';
import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';
import 'package:godelivery_user/features/story/domain/repositories/story_repository_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';

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
        Response response = await apiClient.getData(AppConstants.storyFeedUri);
        print('Stories API Response - Status: ${response.statusCode}');
        print('Stories API Response - Body type: ${response.body.runtimeType}');
        if (response.statusCode == 200) {
          storyList = [];
          if (response.body is List) {
            response.body.forEach((data) {
              storyList?.add(StoryCollectionModel.fromJson(data));
            });
            LocalClient.organize(DataSourceEnum.client, cacheId,
                jsonEncode(response.body), apiClient.getHeader());
          } else {
            print('Stories API returned non-list data: ${response.body}');
          }
        } else {
          print('Stories API error: ${response.statusText} - ${response.body}');
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
    Response response = await apiClient.postData(
      '${AppConstants.storyViewUri}/$storyId/view',
      {'completed': completed},
    );
    return response.statusCode == 200;
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