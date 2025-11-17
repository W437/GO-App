import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/util/images.dart';

class VideoBannerItemWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final String? thumbnailBlurhash;
  final VoidCallback onVideoEnd;
  final BorderRadius borderRadius;

  const VideoBannerItemWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.thumbnailBlurhash,
    required this.onVideoEnd,
    required this.borderRadius,
  });

  @override
  State<VideoBannerItemWidget> createState() => _VideoBannerItemWidgetState();
}

class _VideoBannerItemWidgetState extends State<VideoBannerItemWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _hasCompletedOnce = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // Start playing and loop the video
      _controller!.setLooping(true);
      _controller!.play();

      // Listen for video completion (when it reaches the end before looping)
      _controller!.addListener(_videoListener);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
    }
  }

  void _videoListener() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Check if video has reached the end (just before it loops)
    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    // When video reaches near the end (within 200ms), trigger slide change once
    if (!_hasCompletedOnce &&
        position >= duration - const Duration(milliseconds: 200) &&
        position <= duration) {
      _hasCompletedOnce = true;

      // Pause on the last frame briefly before advancing
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          widget.onVideoEnd();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      // Show error: thumbnail with blurhash, or just blurhash, or fallback icon
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: widget.thumbnailUrl != null
            ? BlurhashImageWidget(
                imageUrl: widget.thumbnailUrl!,
                blurhash: widget.thumbnailBlurhash,
                fit: BoxFit.cover,
                borderRadius: widget.borderRadius,
              )
            : widget.thumbnailBlurhash != null
                ? BlurHash(hash: widget.thumbnailBlurhash!, imageFit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: widget.borderRadius,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Theme.of(context).disabledColor,
                        size: 48,
                      ),
                    ),
                  ),
      );
    }

    if (!_isInitialized || _controller == null) {
      // Show thumbnail with blurhash while video is loading
      if (widget.thumbnailUrl != null || widget.thumbnailBlurhash != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: widget.borderRadius,
              child: widget.thumbnailUrl != null
                  ? BlurhashImageWidget(
                      imageUrl: widget.thumbnailUrl!,
                      blurhash: widget.thumbnailBlurhash,
                      fit: BoxFit.cover,
                      borderRadius: widget.borderRadius,
                    )
                  : widget.thumbnailBlurhash != null
                      ? BlurHash(hash: widget.thumbnailBlurhash!, imageFit: BoxFit.cover)
                      : const SizedBox(),
            ),
            Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                backgroundColor: Colors.black26,
              ),
            ),
          ],
        );
      }

      // Fallback: just loading indicator
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: widget.borderRadius,
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
