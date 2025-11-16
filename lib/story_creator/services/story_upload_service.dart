import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/story_creator_config.dart';
import '../models/story_media.dart';
import '../models/story_text_overlay.dart';

class StoryUploadResult {
  StoryUploadResult({required this.mediaUrl, this.thumbnailUrl});

  final String mediaUrl;
  final String? thumbnailUrl;
}

class StoryUploadException implements Exception {
  StoryUploadException(this.message);

  final String message;

  @override
  String toString() => 'StoryUploadException: $message';
}

class StoryUploadService {
  StoryUploadService({
    required this.config,
    http.Client? client,
  }) : client = client ?? http.Client();

  final StoryCreatorConfig config;
  final http.Client client;

  Future<StoryUploadResult> uploadMedia(StoryMedia media) async {
    final uri = config.buildUploadUri();
    final file = media.file;
    final mimeType = media.type == StoryMediaType.video
        ? MediaType('video', 'mp4')
        : MediaType('image', 'jpeg');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${config.authToken}'
      ..fields['userId'] = config.userId
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mimeType,
        filename: file.path.split(Platform.pathSeparator).last,
      ));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoryUploadException(
        'Media upload failed (${response.statusCode}) ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return StoryUploadResult(
      mediaUrl: decoded['mediaUrl'] as String,
      thumbnailUrl: decoded['thumbnailUrl'] as String?,
    );
  }

  Future<void> createStory({
    required StoryMedia media,
    required StoryUploadResult uploadResult,
    required List<StoryTextOverlay> overlays,
  }) async {
    final uri = config.buildCreateStoryUri();
    final payload = {
      'type': media.type.name,
      'mediaUrl': uploadResult.mediaUrl,
      'thumbnailUrl': uploadResult.thumbnailUrl,
      'durationSeconds': media.duration?.inMilliseconds == null
          ? null
          : media.duration!.inMilliseconds / 1000,
      'overlays': overlays.map((o) => o.toJson()).toList(),
    };

    final response = await client.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.authToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoryUploadException(
        'Create story failed (${response.statusCode}) ${response.body}',
      );
    }
  }

  Future<void> uploadAndCreate({
    required StoryMedia media,
    required List<StoryTextOverlay> overlays,
  }) async {
    final uploadResult = await uploadMedia(media);
    await createStory(
      media: media,
      uploadResult: uploadResult,
      overlays: overlays,
    );
  }

  void dispose() {
    client.close();
  }
}
