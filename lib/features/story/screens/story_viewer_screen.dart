import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/story/controllers/story_controller.dart';
import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';
import 'package:godelivery_user/features/story/domain/models/story_media_model.dart';
import 'package:godelivery_user/features/story/widgets/story_content_widget.dart';
import 'package:godelivery_user/features/story/widgets/story_progress_bar_widget.dart';
import 'package:godelivery_user/features/story/widgets/cube_page_transformer.dart';
import 'package:godelivery_user/features/story/widgets/circular_clipper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryCollectionModel> collections;
  final int initialIndex;
  final Offset? clickPosition;

  const StoryViewerScreen({
    super.key,
    required this.collections,
    required this.initialIndex,
    this.clickPosition,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late PageController _restaurantPageController;
  late AnimationController _animationController;
  int _currentRestaurantIndex = 0;
  int _currentMediaIndex = 0;
  bool _isPaused = false;
  Timer? _progressTimer;
  GlobalKey<StoryContentWidgetState> _contentKey = GlobalKey();

  // Drag-to-close state
  double _dragOffset = 0.0;
  bool _isDragging = false;
  late AnimationController _dragAnimationController;
  late Animation<double> _dragAnimation;

  @override
  void initState() {
    super.initState();
    _currentRestaurantIndex = widget.initialIndex;
    _restaurantPageController = PageController(initialPage: widget.initialIndex);

    _animationController = AnimationController(vsync: this);
    _animationController.addListener(() {
      setState(() {});
    });

    // Add status listener to handle animation completion
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isPaused) {
        _goToNextMedia();
      }
    });

    // Initialize drag animation controller for bounce-back effect
    _dragAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dragAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _dragAnimationController,
        curve: Curves.easeOut,
      ),
    )..addListener(() {
        setState(() {
          _dragOffset = _dragAnimation.value;
        });
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedia();
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _animationController.dispose();
    _dragAnimationController.dispose();
    _restaurantPageController.dispose();
    super.dispose();
  }

  void _loadMedia() {
    final collection = widget.collections[_currentRestaurantIndex];
    if (collection.stories == null || collection.stories!.isEmpty) {
      _goToNextRestaurant();
      return;
    }

    final story = collection.stories![0];
    if (story.media == null || story.media!.isEmpty) {
      _goToNextRestaurant();
      return;
    }

    final media = story.media![_currentMediaIndex];

    if (media.isImage) {
      _startImageProgress(media.durationSeconds ?? 5);
    }
    // Video progress is handled by the content widget's callbacks

    Get.find<StoryController>()
        .setCurrentIndices(_currentRestaurantIndex, _currentMediaIndex);
  }

  void _startImageProgress(int durationSeconds) {
    _animationController.duration = Duration(seconds: durationSeconds);
    _animationController.forward(from: 0);
    // Completion is handled by the status listener in initState
  }

  void _pauseProgress() {
    setState(() {
      _isPaused = true;
    });
    _animationController.stop();

    // Pause video if current media is a video
    _contentKey.currentState?.pause();
  }

  void _resumeProgress() {
    setState(() {
      _isPaused = false;
    });
    _animationController.forward();

    // Resume video if current media is a video
    _contentKey.currentState?.play();
  }

  void _goToNextMedia() {
    final collection = widget.collections[_currentRestaurantIndex];
    final totalMedia = collection.stories?[0].media?.length ?? 0;

    if (_currentMediaIndex < totalMedia - 1) {
      setState(() {
        _currentMediaIndex++;
        _contentKey = GlobalKey();
      });
      _animationController.reset();
      _loadMedia();
    } else {
      _markRestaurantSeen();
      _goToNextRestaurant();
    }
  }

  void _goToPreviousMedia() {
    // If progress < 10%, go to actual previous media
    // Otherwise, restart current media
    final currentProgress = _animationController.value;

    if (currentProgress < 0.1) {
      // Go to previous media or restaurant
      if (_currentMediaIndex > 0) {
        setState(() {
          _currentMediaIndex--;
          _contentKey = GlobalKey();
        });
        _animationController.reset();
        _loadMedia();
      } else {
        _goToPreviousRestaurant();
      }
    } else {
      // Restart current media
      _animationController.reset();
      _loadMedia();
    }
  }

  void _goToNextRestaurant() {
    if (_currentRestaurantIndex < widget.collections.length - 1) {
      _restaurantPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToPreviousRestaurant() {
    if (_currentRestaurantIndex > 0) {
      _restaurantPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _markRestaurantSeen() {
    final collection = widget.collections[_currentRestaurantIndex];
    if (collection.restaurant?.id != null) {
      Get.find<StoryController>()
          .markRestaurantStorySeen(collection.restaurant!.id!);
    }

    // Mark story as viewed on backend
    if (collection.stories != null && collection.stories!.isNotEmpty) {
      final storyId = collection.stories![0].id;
      if (storyId != null) {
        Get.find<StoryController>().markStoryViewed(storyId, true);
      }
    }
  }

  /// Format time elapsed since story was published (e.g., "5h", "23m", "2d")
  String _formatTimeElapsed(String? publishAt) {
    if (publishAt == null) return '';

    try {
      final publishTime = DateTime.parse(publishAt);
      final now = DateTime.now();
      final difference = now.difference(publishTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }

  // Drag-to-close handlers
  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _pauseProgress();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Only allow dragging down (positive delta)
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final threshold = screenHeight * 0.3; // 30% of screen height

    if (_dragOffset > threshold) {
      // Close the story viewer
      Navigator.of(context).pop();
    } else {
      // Bounce back to original position
      _dragAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _dragAnimationController,
          curve: Curves.easeOut,
        ),
      );
      _dragAnimationController.forward(from: 0).then((_) {
        setState(() {
          _isDragging = false;
          _dragOffset = 0.0;
        });
        _resumeProgress();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final clickPosition = widget.clickPosition ?? Offset(screenSize.width / 2, screenSize.height / 2);
    final maxRadius = calculateMaxRadius(screenSize, clickPosition);
    final initialRadius = 35.0;

    // Calculate current radius based on drag progress
    final dragProgress = (_dragOffset / screenSize.height).clamp(0.0, 1.0);
    final reverseProgress = 1.0 - dragProgress;
    final currentRadius = initialRadius + (maxRadius - initialRadius) * reverseProgress;

    final content = PageView.builder(
          controller: _restaurantPageController,
          onPageChanged: (index) {
            setState(() {
              _currentRestaurantIndex = index;
              _currentMediaIndex = 0;
              _contentKey = GlobalKey();
            });
            _animationController.reset();
            _loadMedia();
          },
          itemCount: widget.collections.length,
          itemBuilder: (context, restaurantIndex) {
            final collection = widget.collections[restaurantIndex];
            final restaurant = collection.restaurant;
            final story = collection.stories?[0];
            final mediaList = story?.media ?? [];

            if (mediaList.isEmpty) {
              return CubePageTransformer(
                controller: _restaurantPageController,
                pageIndex: restaurantIndex,
                child: const Center(
                  child: Text(
                    'No media available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            final currentMedia = mediaList[_currentMediaIndex];

            return CubePageTransformer(
              controller: _restaurantPageController,
              pageIndex: restaurantIndex,
              child: Stack(
              children: [
                // Media content
                Positioned.fill(
                  child: StoryContentWidget(
                    key: _contentKey,
                    media: currentMedia,
                    onVideoReady: () {
                      // Video will handle its own progress
                    },
                    onVideoComplete: () {
                      if (!_isPaused) {
                        _goToNextMedia();
                      }
                    },
                    onVideoPlaying: (isPlaying) {
                      // You can sync progress with video playback if needed
                    },
                  ),
                ),

                // Top gradient overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top +
                          Dimensions.paddingSizeSmall,
                      left: Dimensions.paddingSizeDefault,
                      right: Dimensions.paddingSizeDefault,
                      bottom: Dimensions.paddingSizeLarge,
                    ),
                    child: Column(
                      children: [
                        // Progress bars
                        StoryProgressBarWidget(
                          itemCount: mediaList.length,
                          currentIndex: _currentMediaIndex,
                          progress: _animationController.value,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        // Restaurant info
                        Row(
                          children: [
                            // Restaurant logo
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: (restaurant?.logoFullUrl?.isNotEmpty ?? false)
                                    ? NetworkImage(restaurant!.logoFullUrl!)
                                    : null,
                                child: (restaurant?.logoFullUrl?.isEmpty ?? true)
                                    ? const Icon(Icons.restaurant, size: 26)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Restaurant name and time
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          restaurant?.name ?? '',
                                          style: robotoMedium.copyWith(
                                            color: Colors.white,
                                            fontSize: Dimensions.fontSizeLarge,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (story?.publishAt != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatTimeElapsed(story!.publishAt),
                                          style: robotoRegular.copyWith(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: Dimensions.fontSizeDefault,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  // Rating
                                  if (restaurant?.avgRating != null && restaurant!.avgRating! > 0) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${restaurant.avgRating!.toStringAsFixed(1)} (${restaurant.ratingCount ?? 0})',
                                          style: robotoRegular.copyWith(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: Dimensions.fontSizeSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom caption and CTA
                if (currentMedia.caption != null ||
                    currentMedia.ctaLabel != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom +
                            Dimensions.paddingSizeDefault,
                        left: Dimensions.paddingSizeDefault,
                        right: Dimensions.paddingSizeDefault,
                        top: Dimensions.paddingSizeLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentMedia.caption != null)
                            Text(
                              currentMedia.caption!,
                              style: robotoRegular.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                          if (currentMedia.ctaLabel != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: Dimensions.paddingSizeSmall,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (currentMedia.ctaUrl != null) {
                                    // Navigate to restaurant or product
                                    if (restaurant?.id != null) {
                                      Get.back();
                                      Get.toNamed(RouteHelper.getRestaurantRoute(
                                          restaurant!.id));
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeLarge,
                                    vertical: Dimensions.paddingSizeSmall,
                                  ),
                                ),
                                child: Text(
                                  currentMedia.ctaLabel!,
                                  style: robotoBold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            );
          },
        );

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onLongPressStart: (_) => _pauseProgress(),
        onLongPressEnd: (_) => _resumeProgress(),
        onLongPressCancel: () => _resumeProgress(),
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            // Left third: Previous media or restart
            _goToPreviousMedia();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            // Right third: Next media
            _goToNextMedia();
          }
          // Middle third: No action (allows for accidental taps)
        },
        child: ClipPath(
          clipper: CircularClipper(
            center: clickPosition,
            radius: currentRadius,
          ),
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: content,
          ),
        ),
      ),
    );
  }
}