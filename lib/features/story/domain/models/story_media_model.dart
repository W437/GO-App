import 'story_overlay_model.dart';

class StoryMediaModel {
  int? id;
  int? storyId;
  int? sequence;
  String? mediaType;
  String? mediaPath;
  String? thumbnailPath;
  int? durationSeconds;
  String? caption;
  String? ctaLabel;
  String? ctaUrl;
  List<StoryOverlayModel>? overlays;

  StoryMediaModel({
    this.id,
    this.storyId,
    this.sequence,
    this.mediaType,
    this.mediaPath,
    this.thumbnailPath,
    this.durationSeconds,
    this.caption,
    this.ctaLabel,
    this.ctaUrl,
  });

  StoryMediaModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storyId = json['story_id'];
    sequence = json['sequence'];
    // Backend sends 'type' but we store as 'mediaType'
    mediaType = json['type'] ?? json['media_type'];
    // Backend sends 'media_url' but we store as 'mediaPath'
    mediaPath = json['media_url'] ?? json['media_path'];
    // Backend sends 'thumbnail_url' but we store as 'thumbnailPath'
    thumbnailPath = json['thumbnail_url'] ?? json['thumbnail_path'];
    durationSeconds = json['duration_seconds'] ?? 5;
    caption = json['caption'];
    ctaLabel = json['cta_label'];
    ctaUrl = json['cta_url'];
    final overlayJson = json['overlays'];
    if (overlayJson is List) {
      overlays = overlayJson
          .whereType<Map<String, dynamic>>()
          .map(StoryOverlayModel.fromJson)
          .toList()
        ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    } else {
      overlays = const [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['story_id'] = storyId;
    data['sequence'] = sequence;
    data['media_type'] = mediaType;
    data['media_path'] = mediaPath;
    data['thumbnail_path'] = thumbnailPath;
    data['duration_seconds'] = durationSeconds;
    data['caption'] = caption;
    data['cta_label'] = ctaLabel;
    data['cta_url'] = ctaUrl;
    return data;
  }

  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';
}
