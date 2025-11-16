import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;

/// Custom refresh widget that shows a gradient overlay with video during pull-to-refresh
class VideoRefreshWidget extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double triggerDistance;
  final double maxDragDistance;

  const VideoRefreshWidget({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.triggerDistance = 100.0,
    this.maxDragDistance = 250.0,
  }) : super(key: key);

  @override
  State<VideoRefreshWidget> createState() => _VideoRefreshWidgetState();
}

class _VideoRefreshWidgetState extends State<VideoRefreshWidget>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;

  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  bool _isDragging = false;
  bool _videoInitialized = false;

  // Animation for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/video/notbad.mp4');
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.setVolume(0); // Mute the video

    if (mounted) {
      setState(() {
        _videoInitialized = true;
      });
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels < 0 && !_isRefreshing) {
        setState(() {
          _isDragging = true;
          _dragOffset = math.min(-notification.metrics.pixels, widget.maxDragDistance);
        });

        // Start playing video when drag begins
        if (_dragOffset > 30 && _videoController != null && !_videoController!.value.isPlaying) {
          _videoController!.play();
        }
      }
    } else if (notification is ScrollEndNotification) {
      if (_isDragging && !_isRefreshing) {
        if (_dragOffset >= widget.triggerDistance) {
          _startRefresh();
        } else {
          _cancelRefresh();
        }
      }
    }
    return false; // Allow notification to continue bubbling
  }

  Future<void> _startRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _isDragging = false;
    });

    // Keep video playing during refresh
    if (_videoController != null && !_videoController!.value.isPlaying) {
      _videoController!.play();
    }

    // Animate to hold position during refresh
    _offsetAnimation = Tween<double>(
      begin: _dragOffset,
      end: widget.triggerDistance + 50, // Hold a bit lower for better visibility
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _completeRefresh();
      }
    }
  }

  void _cancelRefresh() {
    // Animate back to hidden
    _offsetAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isDragging = false;
          _dragOffset = 0.0;
        });
        _videoController?.pause();
        _videoController?.seekTo(Duration.zero);
      }
    });
  }

  void _completeRefresh() {
    // Animate sliding back up
    _offsetAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isDragging = false;
          _dragOffset = 0.0;
        });
        _videoController?.pause();
        _videoController?.seekTo(Duration.zero);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content stays fixed
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),

        // Solid box with video that appears from top
        if (_videoInitialized && (_dragOffset > 0 || _isRefreshing))
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final offset = _animationController.isAnimating
                  ? _offsetAnimation.value
                  : _dragOffset;

              if (offset <= 0) return const SizedBox.shrink();

              // Calculate progress for animations
              final progress = (offset / widget.triggerDistance).clamp(0.0, 1.0);
              final videoOpacity = (progress * 1.2).clamp(0.0, 1.0);

              return Positioned(
                top: 120, // Position below header
                left: 0,
                right: 0,
                height: math.min(offset * 1.2, 200), // Larger height
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.shade500, // Solid purple color
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Video centered in the available space
                        AnimatedOpacity(
                          opacity: videoOpacity,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 100,
                            height: 100,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: _videoController != null && _videoController!.value.isInitialized
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _videoController!.value.size.width,
                                          height: _videoController!.value.size.height,
                                          child: VideoPlayer(_videoController!),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                          ),
                        ),

                        // Loading indicator when refreshing
                        if (_isRefreshing)
                          Positioned(
                            bottom: 20, // Position at bottom of box
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Refreshing...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animationController.dispose();
    super.dispose();
  }
}