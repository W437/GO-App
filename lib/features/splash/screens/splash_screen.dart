import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:godelivery_user/common/widgets/adaptive/empty_states/no_internet_screen_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/notification/domain/models/notification_body_model.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/splash/domain/models/deep_link_body.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/navigation/app_navigator.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBodyModel? notificationBody;
  final DeepLinkBody? linkBody;
  final bool muteVideo;

  const SplashScreen({
    super.key,
    required this.notificationBody,
    required this.linkBody,
    this.muteVideo = false,
  });

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  late final VideoPlayerController _videoController;
  late final Future<void> _videoInitializationFuture;
  bool _videoCompleted = false;
  bool _hasTriggeredRoute = false;
  bool _videoFailedToLoad = false;
  bool _skipPressed = false;

  // Skip button configuration
  static const int? skipButtonDelaySeconds = 2; // Set to null to disable skip button
  bool _skipButtonEnabled = false;

  @override
  void initState() {
    super.initState();

    // Enable skip button after delay (if configured)
    if (skipButtonDelaySeconds != null) {
      Future.delayed(Duration(seconds: skipButtonDelaySeconds!), () {
        if (mounted) {
          setState(() {
            _skipButtonEnabled = true;
          });
        }
      });
    }

    _initializeVideo();

    bool firstTime = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      bool isConnected = result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile);

      if(!firstTime) {
        ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: Duration(seconds: isConnected ? 3 : 6000),
          content: Text(isConnected ? 'connected'.tr : 'no_connection'.tr, textAlign: TextAlign.center),
        ));
        if(isConnected) {
          _handleConnectionRestored();
        }else {
          Get.to(const NoInternetScreen());
        }
      }

      firstTime = false;

    });

    Get.find<SplashController>().initSharedData();
    if(AddressHelper.getAddressFromSharedPref() != null && (AddressHelper.getAddressFromSharedPref()!.zoneIds == null
        || AddressHelper.getAddressFromSharedPref()!.zoneData == null)) {
      AddressHelper.clearAddressFromSharedPref();
    }
    if(Get.find<AuthController>().isGuestLoggedIn() || Get.find<AuthController>().isLoggedIn()) {
      Get.find<CartController>().getCartDataOnline();
    }

    // Start loading config and all data in parallel with video
    _startDataLoading();
  }

  /// Start data loading in parallel with video playback
  Future<void> _startDataLoading() async {
    print('🚀 [SPLASH] Starting parallel data loading...');
    final splashController = Get.find<SplashController>();

    // Load config first (required for everything else)
    final configSuccess = await splashController.loadConfig();

    if (!configSuccess) {
      print('❌ [SPLASH] Config load failed during parallel load');
      return; // Will be handled in _route()
    }

    // Load all data while video plays - BUT only if we are going to the dashboard
    if (splashController.shouldLoadData) {
      print('🚀 [SPLASH] Returning user detected - Starting parallel data load');
      await splashController.loadAllData(useCache: false);
      print('✅ [SPLASH] Parallel data loading complete');
    } else {
      print('🛑 [SPLASH] Fresh user detected - Skipping data load (will load in Dashboard)');
      // We don't load data, but we don't mark it as failed either.
      // The _route method will handle the navigation based on config only.
    }
  }

  @override
  void dispose() {
    super.dispose();

    _onConnectivityChanged?.cancel();
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
  }

  void _initializeVideo() {
    print('🎥 [SPLASH] Starting video initialization...');
    _videoController = VideoPlayerController.asset('assets/video/hopa_intro.mp4');
    _videoInitializationFuture = _videoController.initialize().then((_) async {
      print('🎥 [SPLASH] Video initialized successfully');
      print('🎥 [SPLASH] Video duration: ${_videoController.value.duration}');
      print('🎥 [SPLASH] Video aspect ratio: ${_videoController.value.aspectRatio}');
      print('🎥 [SPLASH] Video size: ${_videoController.value.size}');

      if (!mounted) {
        print('🎥 [SPLASH] Widget not mounted, skipping play');
        return;
      }

      await _videoController.setLooping(false);
      await _videoController.setVolume(widget.muteVideo ? 0.0 : 1.0);
      print('🎥 [SPLASH] Starting video playback...');
      await _videoController.play();
      print('🎥 [SPLASH] Video play() called, isPlaying: ${_videoController.value.isPlaying}');
      print('🎥 [SPLASH] Video muted: ${widget.muteVideo}, volume: ${_videoController.value.volume}');

      _videoController.addListener(_videoListener);
      if (mounted) {
        setState(() {});
      }
    }).catchError((error) {
      print('❌ [SPLASH] Video initialization failed: $error');
      _videoFailedToLoad = true;
      _handleVideoCompleted();
    });
  }

  void _videoListener() {
    if (!_videoController.value.isInitialized || _videoFailedToLoad) {
      return;
    }
    final Duration duration = _videoController.value.duration;
    final Duration position = _videoController.value.position;
    if (!_videoCompleted && duration > Duration.zero && position >= duration - const Duration(milliseconds: 100)) {
      _handleVideoCompleted();
    }
  }

  void _handleVideoCompleted() {
    if (_videoCompleted) return;
    print('🎥 [SPLASH] Video completed');
    _videoCompleted = true;
    _videoController.removeListener(_videoListener);
    _tryStartRouting();
  }

  void _handleConnectionRestored() {
    _tryStartRouting();
  }

  void _tryStartRouting() {
    print('🎥 [SPLASH] _tryStartRouting called - hasTriggeredRoute: $_hasTriggeredRoute, videoCompleted: $_videoCompleted');
    if (_hasTriggeredRoute || !_videoCompleted) return;

    _hasTriggeredRoute = true;

    final hasConnection = Get.find<SplashController>().hasConnection;
    print('🎥 [SPLASH] Connection status: $hasConnection');

    if (!hasConnection) {
      print('🎥 [SPLASH] No connection - navigating to no internet screen');
      // Navigate to dedicated no internet screen
      Get.off(() => NoInternetScreen(
        child: SplashScreen(
          notificationBody: widget.notificationBody,
          linkBody: widget.linkBody,
          muteVideo: widget.muteVideo,
        ),
      ));
      return;
    }

    print('🎥 [SPLASH] Starting route to next screen');

    // Add safety timeout - if routing takes more than 15 seconds, show no internet screen
    Future.delayed(const Duration(seconds: 15), () {
      if (Get.currentRoute == '/splash') {
        print('🎥 [SPLASH] Routing timed out after 15 seconds - showing no internet screen');
        Get.off(() => NoInternetScreen(
          child: SplashScreen(
            notificationBody: widget.notificationBody,
            linkBody: widget.linkBody,
            muteVideo: widget.muteVideo,
          ),
        ));
      }
    });

    _route();
  }

  Future<void> _route() async {
    print('🚀 [SPLASH] _route() called - checking data loading status');

    final splashController = Get.find<SplashController>();

    // Check if data loading already completed (from parallel load in initState)
    if (splashController.dataLoadingComplete) {
      print('✅ [SPLASH] Data already loaded in parallel - navigating immediately');
      await AppNavigator.navigateOnAppLaunch(
        notification: widget.notificationBody,
        linkBody: widget.linkBody,
      );
      return;
    }

    // Check if we intentionally skipped loading (Fresh User)
    if (!splashController.shouldLoadData) {
      print('⏩ [SPLASH] Data load was skipped (Fresh User) - navigating immediately');
      await AppNavigator.navigateOnAppLaunch(
        notification: widget.notificationBody,
        linkBody: widget.linkBody,
      );
      return;
    }

    // Check if data loading failed during parallel load
    if (splashController.dataLoadingFailed) {
      print('❌ [SPLASH] Data loading failed - showing no internet screen');
      Get.off(() => NoInternetScreen(
        child: SplashScreen(
          notificationBody: widget.notificationBody,
          linkBody: widget.linkBody,
          muteVideo: widget.muteVideo,
        ),
      ));
      return;
    }

    // Data still loading - wait for it to complete
    print('⏳ [SPLASH] Data still loading, waiting for completion...');

    // Wait for data loading to complete (should be quick since it started in parallel)
    int attempts = 0;
    while (!splashController.dataLoadingComplete && !splashController.dataLoadingFailed && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // Check final status
    if (splashController.dataLoadingComplete) {
      print('✅ [SPLASH] Data loading completed - navigating');
      await AppNavigator.navigateOnAppLaunch(
        notification: widget.notificationBody,
        linkBody: widget.linkBody,
      );
    } else {
      print('❌ [SPLASH] Data loading failed or timed out - showing no internet screen');
      Get.off(() => NoInternetScreen(
        child: SplashScreen(
          notificationBody: widget.notificationBody,
          linkBody: widget.linkBody,
          muteVideo: widget.muteVideo,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎥 [SPLASH] Building splash screen - skipPressed: $_skipPressed');
    return Scaffold(
      backgroundColor: Colors.white,
      key: _globalKey,
      body: _skipPressed
        ? const Center(child: CircularProgressIndicator())  // Show loading when skipped
        : GetBuilder<SplashController>(builder: (splashController) {
            print('🎥 [SPLASH] GetBuilder rebuilt - hasConnection: ${splashController.hasConnection}');

            // Always show video player - no overlay during video playback
            // No internet check will happen after video completes in _tryStartRouting()
            return _buildVideoPlayer();
          }),
    );
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder<void>(
      future: _videoInitializationFuture,
      builder: (context, snapshot) {
        print('🎥 [SPLASH] FutureBuilder state: ${snapshot.connectionState}');

        final bool isVideoReady = snapshot.connectionState == ConnectionState.done &&
                                   !_videoFailedToLoad &&
                                   !snapshot.hasError;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail shown while video loads
            Image.asset(
              'assets/image/splash_thumbnail.jpg',
              fit: BoxFit.contain,
            ),

            // Video player on top, only visible when ready
            if (isVideoReady)
              Container(
                color: Colors.white,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),

            // Progress indicator for data loading
            GetBuilder<SplashController>(
              builder: (splashController) {
                // Show progress and keep visible even at 100%
                if (splashController.loadingProgress > 0) {
                  return Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            tween: Tween<double>(
                              begin: splashController.loadingProgress / 100,
                              end: splashController.loadingProgress / 100,
                            ),
                            builder: (context, value, child) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: value.clamp(0.01, 1.0),
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  // Loading message (centered)
                                  Text(
                                    splashController.loadingMessage,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Skip button at the bottom (only if enabled)
            if (skipButtonDelaySeconds != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _skipButtonEnabled ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: TextButton(
                          onPressed: _skipButtonEnabled && !_hasTriggeredRoute ? () {
                            print('🎥 [SPLASH] Skip button pressed - hiding splash immediately');
                            setState(() {
                              _skipPressed = true;
                              _hasTriggeredRoute = true;
                              _videoCompleted = true;
                            });
                            // Stop video
                            _videoController.pause();
                            // Navigate
                            _route();
                          } : null,
                          child: Text(
                            'skip'.tr,
                            style: TextStyle(
                              color: _skipButtonEnabled ? Colors.grey.shade400 : Colors.transparent,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(
              'Launching...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
