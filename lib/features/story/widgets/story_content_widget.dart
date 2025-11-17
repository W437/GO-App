import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:godelivery_user/features/story/domain/models/story_media_model.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:video_player/video_player.dart';

class StoryContentWidget extends StatefulWidget {
  final StoryMediaModel media;
  final VoidCallback? onVideoComplete;
  final VoidCallback? onVideoReady;
  final Function(bool)? onVideoPlaying;
  final VoidCallback? onImageLoaded;

  const StoryContentWidget({
    super.key,
    required this.media,
    this.onVideoComplete,
    this.onVideoReady,
    this.onVideoPlaying,
    this.onImageLoaded,
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

      return Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Blurhash (appears instantly, stays visible)
          if (widget.media.thumbnailBlurhash != null && widget.media.thumbnailBlurhash!.isNotEmpty)
            BlurHash(
              hash: widget.media.thumbnailBlurhash!,
              imageFit: BoxFit.cover,
            )
          else
            Container(color: Colors.black),

          // Layer 2: Image (fades in on top)
          CachedNetworkImage(
            imageUrl: widget.media.mediaPath!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            fadeInDuration: const Duration(milliseconds: 400),
            fadeOutDuration: Duration.zero,
            imageBuilder: (context, imageProvider) {
              // Call the callback when image is loaded
              if (widget.onImageLoaded != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onImageLoaded!();
                });
              }
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
            placeholder: (context, url) => const SizedBox(),
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
          ),
        ],
      );
    } else {
      // Video - Show blurhash -> thumbnail -> video
      return Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Blurhash (appears instantly, always visible in background)
          if (widget.media.thumbnailBlurhash != null && widget.media.thumbnailBlurhash!.isNotEmpty)
            BlurHash(
              hash: widget.media.thumbnailBlurhash!,
              imageFit: BoxFit.cover,
            )
          else
            Container(color: Colors.black),

          // Layer 2: Thumbnail (fades in while video loads)
          if (widget.media.thumbnailPath != null && widget.media.thumbnailPath!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.media.thumbnailPath!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              fadeInDuration: const Duration(milliseconds: 400),
              fadeOutDuration: Duration.zero,
              placeholder: (context, url) => const SizedBox(),
              errorWidget: (context, url, error) => const SizedBox(),
            ),

          // Layer 3: Video player (appears when ready)
          if (_isVideoInitialized && _chewieController != null)
            Chewie(controller: _chewieController!)
          else
            Container(
              color: Colors.transparent,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    }
  }

  void pause() {
    _videoController?.pause();
  }

  void play() {
    _videoController?.play();
  }
}