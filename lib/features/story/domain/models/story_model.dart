import 'package:godelivery_user/features/story/domain/models/story_media_model.dart';

class StoryModel {
  int? id;
  int? restaurantId;
  String? title;
  String? status;
  String? publishAt;
  String? expireAt;
  String? createdAt;
  List<StoryMediaModel>? media;

  StoryModel({
    this.id,
    this.restaurantId,
    this.title,
    this.status,
    this.publishAt,
    this.expireAt,
    this.createdAt,
    this.media,
  });

  StoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    restaurantId = json['restaurant_id'];
    title = json['title'];
    status = json['status'];
    publishAt = json['publish_at'];
    expireAt = json['expire_at'];
    createdAt = json['created_at'];
    if (json['media'] != null) {
      media = <StoryMediaModel>[];
      json['media'].forEach((v) {
        media!.add(StoryMediaModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['restaurant_id'] = restaurantId;
    data['title'] = title;
    data['status'] = status;
    data['publish_at'] = publishAt;
    data['expire_at'] = expireAt;
    data['created_at'] = createdAt;
    if (media != null) {
      data['media'] = media!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  bool get isActive => status == 'published';
  bool get hasMedia => media != null && media!.isNotEmpty;
}