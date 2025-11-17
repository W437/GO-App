import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/story/controllers/story_controller.dart';
import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';
import 'package:godelivery_user/features/story/domain/models/story_overlay_model.dart';
import 'package:godelivery_user/features/story/widgets/story_content_widget.dart';
import 'package:godelivery_user/features/story/widgets/story_progress_bar_widget.dart';
import 'package:godelivery_user/features/story/widgets/cube_page_transformer.dart';
import 'package:godelivery_user/features/story/widgets/circular_clipper.dart';
import 'package:godelivery_user/features/story/widgets/story_overlays_layer.dart';
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
  int _currentStoryIndex = 0; // Track story within current restaurant
  int _currentMediaIndex = 0;
  bool _isPaused = false;
  bool _isMediaLoaded = false; // Track if current media has loaded
  Timer? _progressTimer;
  GlobalKey<StoryContentWidgetState> _contentKey = GlobalKey();

  // Drag-to-close state
  double _dragOffset = 0.0;
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

    // Ensure story index is valid
    if (_currentStoryIndex >= collection.stories!.length) {
      _goToNextRestaurant();
      return;
    }

    final story = collection.stories![_currentStoryIndex];
    if (story.media == null || story.media!.isEmpty) {
      _goToNextStory();
      return;
    }

    // Ensure media index is valid
    if (_currentMediaIndex >= story.media!.length) {
      _goToNextStory();
      return;
    }

    // Reset media loaded state
    setState(() {
      _isMediaLoaded = false;
    });

    Get.find<StoryController>()
        .setCurrentIndices(_currentRestaurantIndex, _currentMediaIndex);
  }

  void _startImageProgress(int durationSeconds) {
    _animationController.duration = Duration(seconds: durationSeconds);
    _animationController.forward(from: 0);
    // Completion is handled by the status listener in initState
  }

  void _onImageLoaded() {
    if (!_isMediaLoaded) {
      setState(() {
        _isMediaLoaded = true;
      });

      // Start the timer now that the image has loaded
      final collection = widget.collections[_currentRestaurantIndex];
      final story = collection.stories![_currentStoryIndex];
      final media = story.media![_currentMediaIndex];

      if (media.isImage) {
        _startImageProgress(media.durationSeconds ?? 5);
      }
    }
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
    final currentStory = collection.stories?[_currentStoryIndex];
    final totalMedia = currentStory?.media?.length ?? 0;

    if (_currentMediaIndex < totalMedia - 1) {
      // More media in current story
      setState(() {
        _currentMediaIndex++;
        _contentKey = GlobalKey();
        _isMediaLoaded = false; // Reset for new media
      });
      _animationController.reset();
      _loadMedia();
    } else {
      // No more media in current story, try next story
      _goToNextStory();
    }
  }

  void _goToNextStory() {
    final collection = widget.collections[_currentRestaurantIndex];
    final totalStories = collection.stories?.length ?? 0;

    if (_currentStoryIndex < totalStories - 1) {
      // More stories in current restaurant
      setState(() {
        _currentStoryIndex++;
        _currentMediaIndex = 0;
        _contentKey = GlobalKey();
        _isMediaLoaded = false; // Reset for new media
      });
      _animationController.reset();
      _loadMedia();
    } else {
      // No more stories, go to next restaurant
      _markRestaurantSeen();
      _goToNextRestaurant();
    }
  }

  /// Calculate total media count across all stories in current restaurant
  int _getTotalMediaCount() {
    final collection = widget.collections[_currentRestaurantIndex];
    if (collection.stories == null) return 0;

    int total = 0;
    for (var story in collection.stories!) {
      total += story.media?.length ?? 0;
    }
    return total;
  }

  /// Calculate global media index across all stories
  int _getGlobalMediaIndex() {
    final collection = widget.collections[_currentRestaurantIndex];
    if (collection.stories == null) return 0;

    int globalIndex = 0;

    // Add media count from all previous stories
    for (int i = 0; i < _currentStoryIndex; i++) {
      globalIndex += collection.stories![i].media?.length ?? 0;
    }

    // Add current media index within current story
    globalIndex += _currentMediaIndex;

    return globalIndex;
  }

  void _goToPreviousMedia() {
    // If progress < 10%, go to actual previous media
    // Otherwise, restart current media
    final currentProgress = _animationController.value;

    if (currentProgress < 0.1) {
      // Go to previous media, story, or restaurant
      if (_currentMediaIndex > 0) {
        // Previous media in current story
        setState(() {
          _currentMediaIndex--;
          _contentKey = GlobalKey();
          _isMediaLoaded = false; // Reset for new media
        });
        _animationController.reset();
        _loadMedia();
      } else if (_currentStoryIndex > 0) {
        // Previous story in current restaurant
        setState(() {
          _currentStoryIndex--;
          final prevStory = widget.collections[_currentRestaurantIndex].stories![_currentStoryIndex];
          _currentMediaIndex = (prevStory.media?.length ?? 1) - 1;
          _contentKey = GlobalKey();
          _isMediaLoaded = false; // Reset for new media
        });
        _animationController.reset();
        _loadMedia();
      } else {
        // Previous restaurant
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

    // Mark all stories in this restaurant as viewed on backend
    if (collection.stories != null && collection.stories!.isNotEmpty) {
      for (var story in collection.stories!) {
        if (story.id != null) {
          Get.find<StoryController>().markStoryViewed(story.id!, true);
        }
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

    final content = Container(
      color: Colors.black, // Black background for story content
      child: PageView.builder(
          controller: _restaurantPageController,
          onPageChanged: (index) {
            setState(() {
              _currentRestaurantIndex = index;
              _currentStoryIndex = 0; // Reset to first story of new restaurant
              _currentMediaIndex = 0;
              _contentKey = GlobalKey();
              _isMediaLoaded = false; // Reset for new restaurant
            });
            _animationController.reset();
            _loadMedia();
          },
          itemCount: widget.collections.length,
          itemBuilder: (context, restaurantIndex) {
            final collection = widget.collections[restaurantIndex];
            final restaurant = collection.restaurant;
            // Use current story index for this restaurant
            final storyIndex = restaurantIndex == _currentRestaurantIndex ? _currentStoryIndex : 0;
            final story = collection.stories != null && collection.stories!.length > storyIndex
                ? collection.stories![storyIndex]
                : null;
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
                    // Only use GlobalKey for the current restaurant to avoid conflicts
                    key: restaurantIndex == _currentRestaurantIndex ? _contentKey : null,
                    media: currentMedia,
                    onImageLoaded: restaurantIndex == _currentRestaurantIndex ? _onImageLoaded : null,
                    onVideoReady: restaurantIndex == _currentRestaurantIndex
                        ? () {
                            // Mark media as loaded for videos and start timer
                            if (!_isMediaLoaded) {
                              setState(() {
                                _isMediaLoaded = true;
                              });

                              // Start the progress timer for video duration
                              final collection = widget.collections[_currentRestaurantIndex];
                              final story = collection.stories![_currentStoryIndex];
                              final media = story.media![_currentMediaIndex];

                              if (media.isVideo) {
                                _startImageProgress(media.durationSeconds ?? 15);
                              }
                            }
                          }
                        : null,
                    onVideoComplete: restaurantIndex == _currentRestaurantIndex
                        ? () {
                            if (!_isPaused) {
                              _goToNextMedia();
                            }
                          }
                        : null,
                    onVideoPlaying: restaurantIndex == _currentRestaurantIndex
                        ? (isPlaying) {
                            // You can sync progress with video playback if needed
                          }
                        : null,
                  ),
                ),
                if ((currentMedia.overlays?.isNotEmpty ?? false))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: StoryOverlaysLayer(
                        overlays: currentMedia.overlays ?? const <StoryOverlayModel>[],
                      ),
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
                        // Progress bars (show all media across all stories)
                        StoryProgressBarWidget(
                          itemCount: _getTotalMediaCount(),
                          currentIndex: _getGlobalMediaIndex(),
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
        ),
      );

    return Scaffold(
      backgroundColor: Colors.transparent,
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
          child: content,
        ),
      ),
    );
  }
}
