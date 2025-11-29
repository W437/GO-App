import 'package:flutter/material.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/features/restaurant/mixins/restaurant_scroll_mixin.dart';
import 'package:godelivery_user/util/dimensions.dart';

/// Floating restaurant logo widget with bounce and press animations.
/// Used in RestaurantScreen, positioned above all other elements.
class RestaurantLogoWidget extends StatefulWidget {
  final String? imageUrl;
  final String? blurhash;
  final double topPosition;
  final double opacity;
  final double scale;

  const RestaurantLogoWidget({
    super.key,
    required this.imageUrl,
    this.blurhash,
    required this.topPosition,
    required this.opacity,
    required this.scale,
  });

  @override
  State<RestaurantLogoWidget> createState() => RestaurantLogoWidgetState();
}

class RestaurantLogoWidgetState extends State<RestaurantLogoWidget>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();

    // Bounce animation with smooth continuous spring
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.02)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_bounceController);

    // Press animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  /// Trigger bounce animation (called externally when scrolling to top)
  void triggerBounce() {
    _bounceController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topPosition,
      left: 0,
      right: 0,
      child: Center(
        child: Opacity(
          opacity: widget.opacity,
          child: AnimatedBuilder(
            animation: Listenable.merge([_bounceAnimation, _pressAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: widget.scale * _bounceAnimation.value * _pressAnimation.value,
                child: child,
              );
            },
            child: GestureDetector(
              onTapDown: (_) => _pressController.forward(),
              onTapUp: (_) => _pressController.reverse(),
              onTapCancel: () => _pressController.reverse(),
              onTap: () => _bounceController.forward(from: 0.0),
              child: Container(
                height: RestaurantScrollMixin.logoSize,
                width: RestaurantScrollMixin.logoSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                    width: 2.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(149, 157, 165, 0.2),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  child: BlurhashImageWidget(
                    imageUrl: widget.imageUrl ?? '',
                    blurhash: widget.blurhash,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
