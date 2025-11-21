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

  @override
  void initState() {
    super.initState();

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
    _videoController = VideoPlayerController.asset('assets/video/notbad.mp4');
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
    print('🚀 [SPLASH] _route() called - loading config and data');

    final splashController = Get.find<SplashController>();

    // 1. Load config data (no navigation)
    final configSuccess = await splashController.loadConfig();

    if (!configSuccess) {
      print('❌ [SPLASH] Config load failed - showing no internet screen');
      // Config load failed - navigate to no internet screen
      Get.off(() => NoInternetScreen(
        child: SplashScreen(
          notificationBody: widget.notificationBody,
          linkBody: widget.linkBody,
          muteVideo: widget.muteVideo,
        ),
      ));
      return;
    }

    print('✅ [SPLASH] Config loaded successfully - loading all data');

    // 2. Load all application data with progress tracking
    final dataSuccess = await splashController.loadAllData(useCache: true);

    if (!dataSuccess) {
      print('❌ [SPLASH] Data load failed - showing no internet screen');
      // Data load failed - navigate to no internet screen with retry
      Get.off(() => NoInternetScreen(
        child: SplashScreen(
          notificationBody: widget.notificationBody,
          linkBody: widget.linkBody,
          muteVideo: widget.muteVideo,
        ),
      ));
      return;
    }

    print('✅ [SPLASH] All data loaded successfully - navigating to app');

    // 3. Navigate based on app state (explicit, separate)
    await AppNavigator.navigateOnAppLaunch(
      notification: widget.notificationBody,
      linkBody: widget.linkBody,
    );
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
                // Only show progress after video completes and we're loading data
                if (_videoCompleted && splashController.loadingProgress > 0) {
                  return Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: splashController.loadingProgress / 100,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            // Loading message and percentage
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    splashController.loadingMessage,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${splashController.loadingProgress.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Skip button at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        if (!_hasTriggeredRoute) {
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
                        }
                      },
                      child: Text(
                        'skip'.tr,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
