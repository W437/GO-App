import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/story/domain/models/story_model.dart';

class StoryCollectionModel {
  Restaurant? restaurant;
  List<StoryModel>? stories;
  bool? hasUnseen;

  StoryCollectionModel({
    this.restaurant,
    this.stories,
    this.hasUnseen,
  });

  StoryCollectionModel.fromJson(Map<String, dynamic> json) {
    restaurant = json['restaurant'] != null
        ? Restaurant.fromJson(json['restaurant'])
        : null;
    if (json['stories'] != null) {
      stories = <StoryModel>[];
      json['stories'].forEach((v) {
        stories!.add(StoryModel.fromJson(v));
      });
    }
    hasUnseen = json['has_unseen'] ?? true;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (restaurant != null) {
      data['restaurant'] = restaurant!.toJson();
    }
    if (stories != null) {
      data['stories'] = stories!.map((v) => v.toJson()).toList();
    }
    data['has_unseen'] = hasUnseen;
    return data;
  }

  int get totalMediaCount {
    if (stories == null) return 0;
    return stories!.fold(
        0, (sum, story) => sum + (story.media?.length ?? 0));
  }

  bool get hasStories => stories != null && stories!.isNotEmpty;
}