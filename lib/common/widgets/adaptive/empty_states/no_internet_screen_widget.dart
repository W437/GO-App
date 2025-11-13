// No internet screen widget for handling connectivity issues
// Displays network error message with retry functionality

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoInternetScreen extends StatefulWidget {
  final Widget? child;
  const NoInternetScreen({super.key, this.child});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> with TickerProviderStateMixin {
  bool _isRetrying = false;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade-in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Initialize scale/pulse animation for illustration
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
    });

    try {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();

      if (!connectivityResult.contains(ConnectivityResult.none)) {
        // Connection restored
        try {
          if (widget.child != null) {
            Get.off(widget.child);
          } else {
            Get.offAllNamed(RouteHelper.getInitialRoute());
          }
        } catch (e) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
        }
      } else {
        // Still no connection - show feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('still_no_connection'.tr),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Error checking connection
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('connection_check_failed'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'No internet connection screen',
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeLarge,
            vertical: MediaQuery.of(context).size.height * 0.025,
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated illustration
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      Images.noInternet,
                      width: 120,
                      height: 120,
                      semanticLabel: 'No internet connection illustration',
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  // "Oops!" heading
                  Text(
                    'oops'.tr,
                    style: robotoBold.copyWith(
                      fontSize: 34,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  // Main error message
                  Text(
                    'no_internet_connection'.tr,
                    textAlign: TextAlign.center,
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium!.color?.withValues(alpha: 0.7),
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  // Actionable guidance
                  Text(
                    'please_check_connection'.tr,
                    textAlign: TextAlign.center,
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).disabledColor,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  // Troubleshooting tip
                  Text(
                    'check_wifi_data'.tr,
                    textAlign: TextAlign.center,
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).disabledColor,
                      fontSize: Dimensions.fontSizeSmall,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge * 1.5),

                  // Enhanced retry button
                  CustomButtonWidget(
                    buttonText: 'try_again'.tr,
                    icon: Icons.refresh_rounded,
                    iconSize: 22,
                    onPressed: _handleRetry,
                    isLoading: _isRetrying,
                    height: 56,
                    width: 200,
                    radius: 28,
                    margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
