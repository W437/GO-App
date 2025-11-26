import 'dart:async';
import 'dart:math';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:godelivery_user/common/widgets/adaptive/empty_states/no_internet_screen_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/notification/domain/models/notification_body_model.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/splash/domain/models/deep_link_body.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/helper/zone_polygon_helper.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;

  // Minimum splash duration for branding
  static const Duration _minSplashDuration = Duration(seconds: 2);
  late final DateTime _splashStartTime;

  // Animation for logo fill and bounce
  late AnimationController _fillAnimationController;
  late AnimationController _bounceAnimationController;
  late Animation<double> _fillAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();

    // Fill animation - 1.3 seconds
    _fillAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fillAnimationController,
      curve: Curves.easeInOut,
    ));

    // Bounce animation - 0.35 seconds (1.3s to 1.65s) - fast and snappy
    // Bounces up to 1.1 then smoothly back down to 1.0
    _bounceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _bounceAnimation = TweenSequence<double>([
      // Go up to 1.1
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      // Come back down to 1.0
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_bounceAnimationController);

    // Start fill animation, then bounce when done
    _fillAnimationController.forward().then((_) {
      _bounceAnimationController.forward();
    });

    _setupConnectivityListener();
    _initializeApp();
    _startApp();
  }

  void _setupConnectivityListener() {
    bool firstTime = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      bool isConnected = result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile);

      if(!firstTime) {
        showCustomSnackBar(
          isConnected ? 'connected'.tr : 'no_connection'.tr,
          isError: !isConnected,
        );
        if(isConnected) {
          _startApp(); // Retry on reconnection
        } else {
          Get.to(const NoInternetScreen());
        }
      }
      firstTime = false;
    });
  }

  void _initializeApp() {
    Get.find<SplashController>().initSharedData();

    // Validate and repair addresses with missing zone data
    final savedAddress = AddressHelper.getAddressFromSharedPref();
    if (savedAddress != null &&
        (savedAddress.zoneIds == null || savedAddress.zoneData == null) &&
        savedAddress.latitude != null &&
        savedAddress.longitude != null) {

      print('⚠️ [SPLASH] Address has missing zone data - attempting to repair');

      // Try to repair zone data using local polygon check
      final locationController = Get.find<LocationController>();
      if (locationController.zoneList.isNotEmpty) {
        final lat = double.tryParse(savedAddress.latitude!);
        final lng = double.tryParse(savedAddress.longitude!);

        if (lat != null && lng != null) {
          final zoneId = ZonePolygonHelper.getZoneIdForPoint(
            LatLng(lat, lng),
            locationController.zoneList,
          );

          if (zoneId != null) {
            // Found zone - repair the address
            final zone = locationController.zoneList.firstWhereOrNull((z) => z.id == zoneId);
            if (zone != null) {
              savedAddress.zoneId = zoneId;
              savedAddress.zoneIds = [zoneId];
              savedAddress.zoneData = [
                ZoneData(
                  id: zone.id,
                  status: zone.status,
                  minimumShippingCharge: zone.minimumShippingCharge,
                  perKmShippingCharge: zone.perKmShippingCharge,
                  maximumShippingCharge: zone.maximumShippingCharge,
                  maxCodOrderAmount: zone.maxCodOrderAmount,
                ),
              ];
              AddressHelper.saveAddressInSharedPref(savedAddress);
              print('✅ [SPLASH] Address zone data repaired - Zone ID: $zoneId');
            } else {
              // Zone not found in list - clear address
              print('❌ [SPLASH] Zone not found in list - clearing address');
              AddressHelper.clearAddressFromSharedPref();
            }
          } else {
            // Address is outside all zones - clear it
            print('❌ [SPLASH] Address outside all zones - clearing address');
            AddressHelper.clearAddressFromSharedPref();
          }
        } else {
          // Invalid coordinates - clear address
          print('❌ [SPLASH] Invalid coordinates - clearing address');
          AddressHelper.clearAddressFromSharedPref();
        }
      } else {
        // Zone list not loaded yet - will be validated later
        print('⚠️ [SPLASH] Zone list not loaded - validation deferred');
      }
    }

    // Load cart for logged in users
    if(Get.find<AuthController>().isGuestLoggedIn() || Get.find<AuthController>().isLoggedIn()) {
      Get.find<CartController>().getCartDataOnline();
    }
  }

  /// Single entry point for app startup
  Future<void> _startApp() async {
    final splashController = Get.find<SplashController>();

    // 1. Load config (required for everything)
    final configLoaded = await splashController.loadConfig();
    if (!configLoaded) {
      await _ensureMinimumDuration();
      _showNoInternet();
      return;
    }

    // 2. Load data if returning user
    if (splashController.shouldLoadData) {
      await splashController.loadAllData(useCache: false);
      if (splashController.dataLoadingFailed) {
        await _ensureMinimumDuration();
        _showNoInternet();
        return;
      }
    }

    // 3. Ensure minimum splash duration for branding
    await _ensureMinimumDuration();

    // 4. Navigate to appropriate screen
    await AppNavigator.navigateOnAppLaunch(
      notification: widget.notificationBody,
      linkBody: widget.linkBody,
    );
  }

  /// Ensure splash screen shows for minimum duration
  Future<void> _ensureMinimumDuration() async {
    final elapsed = DateTime.now().difference(_splashStartTime);
    final remaining = _minSplashDuration - elapsed;

    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }

  void _showNoInternet() {
    Get.off(() => NoInternetScreen(
      child: SplashScreen(
        notificationBody: widget.notificationBody,
        linkBody: widget.linkBody,
      ),
    ));
  }

  @override
  void dispose() {
    _onConnectivityChanged?.cancel();
    _fillAnimationController.dispose();
    _bounceAnimationController.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: Colors.white,
      key: _globalKey,
      body: GetBuilder<SplashController>(builder: (splashController) {
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

        // Logo with smooth fill and bounce animation
        AnimatedBuilder(
          animation: Listenable.merge([_fillAnimation, _bounceAnimation]),
          builder: (context, child) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo with liquid fill effect and bounce scale
                  Transform.scale(
                    scale: _bounceAnimation.value,
                    child: SizedBox(
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
                            clipper: _LiquidFillClipper(_fillAnimation.value),
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
                  ),
                  const SizedBox(height: 8),
                  // Loading message (optional)
                  GetBuilder<SplashController>(
                    builder: (splashController) {
                      return Text(
                        splashController.loadingMessage.isEmpty
                            ? ''
                            : splashController.loadingMessage,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
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
