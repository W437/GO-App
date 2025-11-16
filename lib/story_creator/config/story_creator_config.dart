/// Configuration for the story creator flow.
class StoryCreatorConfig {
  StoryCreatorConfig({
    required this.authToken,
    required this.userId,
    required this.baseApiUrl,
    this.mediaUploadPath = '/stories/upload',
    this.storyCreatePath = '/stories',
  }) : assert(baseApiUrl.isNotEmpty, 'baseApiUrl cannot be empty');

  final String authToken;
  final String userId;
  final String baseApiUrl;
  final String mediaUploadPath;
  final String storyCreatePath;

  Uri buildUploadUri() {
    return Uri.parse('$baseApiUrl$mediaUploadPath');
  }

  Uri buildCreateStoryUri() {
    return Uri.parse('$baseApiUrl$storyCreatePath');
  }

  StoryCreatorConfig copyWith({
    String? authToken,
    String? userId,
    String? baseApiUrl,
    String? mediaUploadPath,
    String? storyCreatePath,
  }) {
    return StoryCreatorConfig(
      authToken: authToken ?? this.authToken,
      userId: userId ?? this.userId,
      baseApiUrl: baseApiUrl ?? this.baseApiUrl,
      mediaUploadPath: mediaUploadPath ?? this.mediaUploadPath,
      storyCreatePath: storyCreatePath ?? this.storyCreatePath,
    );
  }

  @override
  String toString() {
    return 'StoryCreatorConfig(userId: $userId, baseApiUrl: $baseApiUrl)';
  }
}
