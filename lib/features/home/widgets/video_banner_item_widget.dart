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
  final bool isActive; // Whether this video is currently visible

  const VideoBannerItemWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.thumbnailBlurhash,
    required this.onVideoEnd,
    required this.borderRadius,
    this.isActive = true,
  });

  @override
  State<VideoBannerItemWidget> createState() => _VideoBannerItemWidgetState();
}

class _VideoBannerItemWidgetState extends State<VideoBannerItemWidget>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _hasCompletedOnce = false;
  Duration _lastPosition = Duration.zero;
  bool _wasDisposed = false;

  @override
  bool get wantKeepAlive => true;

  bool get _shouldPlay =>
      widget.isActive &&
      _isInitialized &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Only initialize if widget is active from the start
    if (widget.isActive) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(VideoBannerItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle visibility changes - dispose/reinitialize based on isActive
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        // Becoming active - initialize video
        _initializeVideo();
      } else {
        // Becoming inactive - dispose to release all resources
        _disposeController();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state != AppLifecycleState.resumed && _controller != null) {
      // App going to background - dispose controller
      _disposeController();
    } else if (state == AppLifecycleState.resumed && widget.isActive && _controller == null) {
      // App coming back and widget is active - reinitialize
      _initializeVideo();
    }
  }

  void _disposeController() {
    if (_controller != null) {
      // Save current position before disposing
      if (_controller!.value.isInitialized && !_controller!.value.isLooping) {
        _lastPosition = _controller!.value.position;
      }
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
      _controller = null;
      _isInitialized = false;
      _wasDisposed = true;
    }
  }

  Future<void> _initializeVideo() async {
    // Don't reinitialize if already initialized
    if (_controller != null && _isInitialized) return;

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // Enable automatic looping
      _controller!.setLooping(true);

      // Restore position if this was previously disposed
      if (_wasDisposed && _lastPosition != Duration.zero) {
        await _controller!.seekTo(_lastPosition);
        _wasDisposed = false;
      }

      // Only play if this video should be playing (active + app in foreground)
      if (_shouldPlay) {
        _controller!.play();
      }

      // Listen for video events (for future features if needed)
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

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    // Trigger slide change only once when video completes first playthrough
    if (!_hasCompletedOnce &&
        position >= duration - const Duration(milliseconds: 500) &&
        position <= duration) {
      _hasCompletedOnce = true;

      // Optional: Auto-advance to next slide after first loop
      // Uncomment if you want videos to advance to next banner
      // Future.delayed(const Duration(milliseconds: 300), () {
      //   if (mounted) {
      //     widget.onVideoEnd();
      //   }
      // });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
      // Show thumbnail with blurhash while video is loading (no spinner)
      if (widget.thumbnailUrl != null || widget.thumbnailBlurhash != null) {
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
                  : const SizedBox(),
        );
      }

      // Fallback: just card color (no spinner)
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: widget.borderRadius,
        ),
      );
    }

    // Keep thumbnail as background to prevent black flicker on loop
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background layer: thumbnail (shows through any gaps/flickers)
          if (widget.thumbnailUrl != null || widget.thumbnailBlurhash != null)
            widget.thumbnailUrl != null
                ? BlurhashImageWidget(
                    imageUrl: widget.thumbnailUrl!,
                    blurhash: widget.thumbnailBlurhash,
                    fit: BoxFit.cover,
                    borderRadius: widget.borderRadius,
                  )
                : widget.thumbnailBlurhash != null
                    ? BlurHash(hash: widget.thumbnailBlurhash!, imageFit: BoxFit.cover)
                    : const SizedBox(),

          // Foreground layer: video player (fill entire space, no letterboxing)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ],
      ),
    );
  }
}
