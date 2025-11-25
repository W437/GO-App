import 'dart:async';
import 'dart:math';
import 'package:animated_emoji/animated_emoji.dart';
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

class SplashScreen extends StatefulWidget {
  final NotificationBodyModel? notificationBody;
  final DeepLinkBody? linkBody;

  const SplashScreen({
    super.key,
    required this.notificationBody,
    required this.linkBody,
  });

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  bool _hasTriggeredRoute = false;

  @override
  void initState() {
    super.initState();

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

    // Start loading config and all data
    _startDataLoading();
  }

  /// Start data loading and navigate when complete
  Future<void> _startDataLoading() async {
    print('🚀 [SPLASH] Starting data loading...');
    final splashController = Get.find<SplashController>();

    // Load config first (required for everything else)
    final configSuccess = await splashController.loadConfig();

    if (!configSuccess) {
      print('❌ [SPLASH] Config load failed');
      _tryStartRouting();
      return;
    }

    // Load all data - BUT only if we are going to the dashboard
    if (splashController.shouldLoadData) {
      print('🚀 [SPLASH] Returning user detected - Starting data load');
      await splashController.loadAllData(useCache: false);
      print('✅ [SPLASH] Data loading complete');
    } else {
      print('🛑 [SPLASH] Fresh user detected - Skipping data load (will load in Dashboard)');
    }

    // Navigate as soon as data loads
    print('🚀 [SPLASH] Data loaded - navigating now');
    _tryStartRouting();
  }

  @override
  void dispose() {
    _onConnectivityChanged?.cancel();
    super.dispose();
  }

  void _handleConnectionRestored() {
    _tryStartRouting();
  }

  void _tryStartRouting() {
    print('🚀 [SPLASH] _tryStartRouting called - hasTriggeredRoute: $_hasTriggeredRoute');
    if (_hasTriggeredRoute) return;

    _hasTriggeredRoute = true;

    final hasConnection = Get.find<SplashController>().hasConnection;
    print('🚀 [SPLASH] Connection status: $hasConnection');

    if (!hasConnection) {
      print('🚀 [SPLASH] No connection - navigating to no internet screen');
      // Navigate to dedicated no internet screen
      Get.off(() => NoInternetScreen(
        child: SplashScreen(
          notificationBody: widget.notificationBody,
          linkBody: widget.linkBody,
        ),
      ));
      return;
    }

    print('🚀 [SPLASH] Starting route to next screen');

    // Add safety timeout - if routing takes more than 15 seconds, show no internet screen
    Future.delayed(const Duration(seconds: 15), () {
      if (Get.currentRoute == '/splash') {
        print('🚀 [SPLASH] Routing timed out after 15 seconds - showing no internet screen');
        Get.off(() => NoInternetScreen(
          child: SplashScreen(
            notificationBody: widget.notificationBody,
            linkBody: widget.linkBody,
          ),
        ));
      }
    });

    _route();
  }

  Future<void> _route() async {
    print('🚀 [SPLASH] _route() called - checking data loading status');

    final splashController = Get.find<SplashController>();

    // Check if data loading already completed
    if (splashController.dataLoadingComplete) {
      print('✅ [SPLASH] Data already loaded - navigating immediately');
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

    // Check if data loading failed
    if (splashController.dataLoadingFailed) {
      print('❌ [SPLASH] Data loading failed - showing no internet screen');
      Get.off(() => NoInternetScreen(
        child: SplashScreen(
          notificationBody: widget.notificationBody,
          linkBody: widget.linkBody,
        ),
      ));
      return;
    }

    // Data still loading - wait for it to complete
    print('⏳ [SPLASH] Data still loading, waiting for completion...');

    // Wait for data loading to complete
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
        ),
      ));
    }
  }

  /// Build emojis behind the logo
  List<Widget> _buildFloatingEmojis(BuildContext context) {
    return [
      // Fire emoji - right side
      Center(
        child: Transform.translate(
          offset: const Offset(120, -35),
          child: Transform.rotate(
            angle: 15 * (pi / 180),
            child: const _FloatingEmoji(
              emoji: AnimatedEmojis.fire,
              size: 58,
              delay: 0,
            ),
          ),
        ),
      ),
      // Heart eyes emoji - left side
      Center(
        child: Transform.translate(
          offset: const Offset(-100, 25),
          child: Transform.rotate(
            angle: -15 * (pi / 180),
            child: const _FloatingEmoji(
              emoji: AnimatedEmojis.heartEyes,
              size: 40,
              delay: 100,
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    print('🚀 [SPLASH] Building splash screen');
    return Scaffold(
      backgroundColor: Colors.white,
      key: _globalKey,
      body: GetBuilder<SplashController>(builder: (splashController) {
        print('🚀 [SPLASH] GetBuilder rebuilt - hasConnection: ${splashController.hasConnection}');
        return _buildSplashContent();
      }),
    );
  }

  Widget _buildSplashContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // White background
        Container(
          color: Colors.white,
        ),

        // Floating animated emojis
        ..._buildFloatingEmojis(context),

        // Logo with liquid fill effect based on loading progress
        GetBuilder<SplashController>(
          builder: (splashController) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              tween: Tween<double>(
                begin: 0,
                end: splashController.loadingProgress / 100,
              ),
              builder: (context, fillProgress, child) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo with liquid fill effect
                      SizedBox(
                        width: 200,
                        child: Stack(
                          children: [
                            // Background: Muted/gray logo
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.grey.shade300,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/image/hopa_white_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Foreground: Blue logo clipped from bottom to top
                            ClipRect(
                              clipper: _LiquidFillClipper(fillProgress),
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).primaryColor,
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  'assets/image/hopa_white_logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Loading message
                      Text(
                        splashController.loadingMessage,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
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

/// Custom clipper for liquid fill effect - reveals from bottom to top
class _LiquidFillClipper extends CustomClipper<Rect> {
  final double fillProgress; // 0.0 to 1.0

  _LiquidFillClipper(this.fillProgress);

  @override
  Rect getClip(Size size) {
    // Clip from bottom to top based on progress
    // At 0% progress: clip is at bottom (nothing visible)
    // At 100% progress: clip covers full height (fully visible)
    final top = size.height * (1.0 - fillProgress);
    return Rect.fromLTRB(0, top, size.width, size.height);
  }

  @override
  bool shouldReclip(_LiquidFillClipper oldClipper) {
    return oldClipper.fillProgress != fillProgress;
  }
}

/// Floating animated emoji with gentle bobbing motion
class _FloatingEmoji extends StatefulWidget {
  final AnimatedEmojiData emoji;
  final double size;
  final int delay;

  const _FloatingEmoji({
    required this.emoji,
    required this.size,
    this.delay = 0,
  });

  @override
  State<_FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<_FloatingEmoji>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _popInController;
  late Animation<double> _floatAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Pop-in animation controller (400ms bouncy scale)
    _popInController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _popInController, curve: Curves.elasticOut),
    );

    // Float animation controller
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Start pop-in after delay, then start floating
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _popInController.forward().then((_) {
          if (mounted) {
            _floatController.repeat(reverse: true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _popInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: child,
          ),
        );
      },
      child: AnimatedEmoji(
        widget.emoji,
        size: widget.size,
      ),
    );
  }
}
