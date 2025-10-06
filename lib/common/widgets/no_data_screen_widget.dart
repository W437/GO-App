/// No data screen widget for empty state displays
/// Shows appropriate messages and icons when no data is available

import 'dart:math';
import 'package:godelivery_user/common/widgets/custom_asset_image_widget.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class NoDataScreen extends StatefulWidget {
  //final bool isCart;
  final String? title;
  final bool fromAddress;
  //final bool isRestaurant;
  final bool isEmptyAddress;
  final bool isEmptyCart;
  final bool isEmptyChat;
  final bool isEmptyOrder;
  final bool isEmptyCoupon;
  final bool isEmptyFood;
  final bool isEmptyNotification;
  final bool isEmptyRestaurant;
  final bool isEmptySearchFood;
  final bool isEmptyTransaction;
  final bool isEmptyWishlist;
  const NoDataScreen({super.key, required this.title, /*this.isCart = false, this.fromAddress = false, this.isRestaurant = false,*/ this.fromAddress = false,
    this.isEmptyAddress = false, this.isEmptyCart = false, this.isEmptyChat = false, this.isEmptyOrder = false, this.isEmptyCoupon = false,
    this.isEmptyFood = false, this.isEmptyNotification = false, this.isEmptyRestaurant = false, this.isEmptySearchFood = false, this.isEmptyTransaction = false,
    this.isEmptyWishlist = false});

  @override
  State<NoDataScreen> createState() => _NoDataScreenState();
}

class _FallingEmoji {
  String emoji;
  double x;
  double startY;
  double speed;
  double size;
  double startRotation;
  double rotationSpeed;
  double screenHeight;

  _FallingEmoji({
    required this.emoji,
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.startRotation,
    required this.rotationSpeed,
    required this.screenHeight,
  });

  double getY(double progress) => startY + (speed * progress * 3500);
  double getRotation(double progress) => startRotation + (rotationSpeed * progress * 3500);

  double getOpacity(double progress) {
    final y = getY(progress);
    final fadeStartY = screenHeight / 2; // Start fading after half screen
    final fadeEndY = screenHeight - 100; // End fading 100px before bottom
    if (y < fadeStartY) {
      return 1.0;
    } else if (y > fadeEndY) {
      return 0.0;
    } else {
      // Fade from 1.0 to 0.0 from mid-screen to 100px before bottom
      return 1.0 - ((y - fadeStartY) / (fadeEndY - fadeStartY));
    }
  }
}


class _NoDataScreenState extends State<NoDataScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  late AnimationController _emojiRainController;
  final List<_FallingEmoji> _fallingEmojis = [];
  final Random _random = Random();
  final List<String> _foodEmojis = ['🍔', '🍕', '🍟', '🌮', '🍱', '🍜', '🍝', '🥗', '🍦', '🍰', '🥤', '🍩'];

  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.95).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
    ]).animate(_animationController);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.03), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.03, end: -0.02), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.02, end: 0.0), weight: 20),
    ]).animate(_animationController);

    _emojiRainController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emojiRainController.dispose();
    super.dispose();
  }

  void _playAnimation() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds < 5) {
      return; // Tap cooldown active
    }
    _lastTapTime = now;

    _animationController.forward(from: 0.0);
    _startEmojiRain();
  }

  void _startEmojiRain() {
    _fallingEmojis.clear();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Create 5-10 emojis
    final emojiCount = 5 + _random.nextInt(6);
    for (int i = 0; i < emojiCount; i++) {
      final size = 24 + _random.nextDouble() * 20; // Size between 24-44
      final startY = -100 - _random.nextDouble() * 300; // Start between -100 and -400
      final speedMultiplier = 0.85 + _random.nextDouble() * 0.3; // Random speed 0.85-1.15x
      // Calculate speed to ensure emoji falls from startY to screenHeight+100 in 3500ms
      final distance = screenHeight + 100 - startY;
      final speed = (distance / 3500) * speedMultiplier;

      _fallingEmojis.add(_FallingEmoji(
        emoji: _foodEmojis[_random.nextInt(_foodEmojis.length)],
        x: _random.nextDouble() * screenWidth,
        startY: startY,
        speed: speed,
        size: size,
        startRotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.003, // Random rotation speed
        screenHeight: screenHeight,
      ));
    }

    setState(() {}); // Trigger rebuild to show new emojis
    _emojiRainController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _fallingEmojis.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    double height = MediaQuery.of(context).size.height;
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Stack(
      children: [
        Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(mainAxisAlignment: widget.fromAddress ? MainAxisAlignment.start : MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [

        widget.fromAddress ? SizedBox(height : height * 0.25) : SizedBox(
          height: widget.isEmptyCart ? height * 0.15 : widget.isEmptyTransaction || widget.isEmptyCoupon ? height * 0.15  : isDesktop ? height * 0.2 : height * 0.3,
        ),

        Center(
          child: widget.isEmptyCart || widget.isEmptyOrder
            ? GestureDetector(
                onTap: _playAnimation,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Lottie.asset(
                          widget.isEmptyCart ? 'assets/animations/cart_empty_lottie.json' : 'assets/animations/food_changing_orders_lottie.json',
                          width: isDesktop ? 200 : 150,
                          height: isDesktop ? 200 : 150,
                          repeat: true,
                        ),
                      ),
                    );
                  },
                ),
              )
            : CustomAssetImageWidget(
                widget.isEmptyAddress ? Images.emptyAddress : widget.isEmptyChat ? Images.emptyChat
                    : widget.isEmptyCoupon ? Images.emptyCoupon : widget.isEmptyFood ? Images.emptyFood : widget.isEmptyNotification ? Images.emptyNotification
                    : widget.isEmptyRestaurant ? Images.emptyRestaurant : widget.isEmptySearchFood ? Images.emptySearchFood : widget.isEmptyTransaction ? Images.emptyTransaction
                    : widget.isEmptyWishlist ? Images.emptyWishlist : Images.emptyFood,
                width: isDesktop ? 130 : 80, height: isDesktop ? 130 : 80,
              ),
        ),
        SizedBox(height: widget.fromAddress ? 10 : 10),

        Text(
          widget.title ?? '',
          style: robotoMedium.copyWith(color: widget.fromAddress ? Theme.of(context).textTheme.bodyMedium!.color : Theme.of(context).disabledColor),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: widget.fromAddress ? 10 : MediaQuery.of(context).size.height * 0.03),

        widget.fromAddress ? Text(
          'please_add_your_address_for_your_better_experience'.tr,
          style: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
          textAlign: TextAlign.center,
        ) : const SizedBox(),
        SizedBox(height: widget.isEmptyAddress ? 30 : MediaQuery.of(context).size.height * 0.05),


        widget.fromAddress ? InkWell(
          onTap: () => Get.toNamed(RouteHelper.getAddAddressRoute(false, 0)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              color: Theme.of(context).primaryColor,
            ),
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeExtraOverLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_sharp, size: 18.0, color: Theme.of(context).cardColor),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Text('add_address'.tr, style: robotoBold.copyWith(color: Theme.of(context).cardColor)),
              ],
            ),
          ),
        ) : const SizedBox(),


      ]),
    ),

        // Emoji rain overlay
        if (_fallingEmojis.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _emojiRainController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _EmojiRainPainter(_fallingEmojis, _emojiRainController.value),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _EmojiRainPainter extends CustomPainter {
  final List<_FallingEmoji> emojis;
  final double progress;

  _EmojiRainPainter(this.emojis, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var emoji in emojis) {
      final y = emoji.getY(progress);
      final rotation = emoji.getRotation(progress);
      final opacity = emoji.getOpacity(progress);

      if (opacity <= 0) continue; // Skip fully transparent emojis

      canvas.save();
      canvas.translate(emoji.x, y);
      canvas.rotate(rotation);

      // Apply opacity using Paint
      final paint = Paint()
        ..color = Colors.black.withOpacity(opacity)
        ..maskFilter = null;

      canvas.saveLayer(null, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: emoji.emoji,
          style: TextStyle(fontSize: emoji.size),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore(); // Restore layer
      canvas.restore(); // Restore translation/rotation
    }
  }

  @override
  bool shouldRepaint(_EmojiRainPainter oldDelegate) => true;
}
