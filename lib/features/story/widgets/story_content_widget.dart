import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:godelivery_user/features/story/domain/models/story_media_model.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:video_player/video_player.dart';

class StoryContentWidget extends StatefulWidget {
  final StoryMediaModel media;
  final VoidCallback? onVideoComplete;
  final VoidCallback? onVideoReady;
  final Function(bool)? onVideoPlaying;

  const StoryContentWidget({
    super.key,
    required this.media,
    this.onVideoComplete,
    this.onVideoReady,
    this.onVideoPlaying,
  });

  @override
  State<StoryContentWidget> createState() => StoryContentWidgetState();
}

class StoryContentWidgetState extends State<StoryContentWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.media.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      // Validate video URL before initializing
      if (widget.media.mediaPath?.isEmpty ?? true) {
        print('Error: Video path is empty or null');
        return;
      }

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.media.mediaPath!),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControls: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: false,
        allowMuting: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  'Video failed to load',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      );

      _videoController!.addListener(() {
        if (_videoController!.value.isPlaying) {
          widget.onVideoPlaying?.call(true);
        } else {
          widget.onVideoPlaying?.call(false);
        }

        if (_videoController!.value.position >= _videoController!.value.duration) {
          widget.onVideoComplete?.call();
        }
      });

      setState(() {
        _isVideoInitialized = true;
      });

      widget.onVideoReady?.call();
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isImage) {
      // Validate image URL before loading
      if (widget.media.mediaPath?.isEmpty ?? true) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.white, size: 48),
                SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  'Image failed to load',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }

      return CachedNetworkImage(
        imageUrl: widget.media.mediaPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.white, size: 48),
                SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  'Image failed to load',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Video
      if (!_isVideoInitialized || _chewieController == null) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }

      return Chewie(controller: _chewieController!);
    }
  }

  void pause() {
    _videoController?.pause();
  }

  void play() {
    _videoController?.play();
  }
}