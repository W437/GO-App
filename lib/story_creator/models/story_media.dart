import 'dart:io';

enum StoryMediaType { image, video }

class StoryMedia {
  StoryMedia({
    required this.file,
    required this.type,
    this.duration,
    this.thumbnailPath,
  });

  final File file;
  final StoryMediaType type;
  final Duration? duration;
  final String? thumbnailPath;
}
