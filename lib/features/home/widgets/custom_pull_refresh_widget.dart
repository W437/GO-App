import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:godelivery_user/util/dimensions.dart';

class SliverPullRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;

  /// Maximum stretch allowed for the pull gap so the header never detaches.
  static const double maxStretchExtent = 120.0;

  const SliverPullRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.scrollController,
  });

  @override
  State<SliverPullRefreshIndicator> createState() => _SliverPullRefreshIndicatorState();
}

class _SliverPullRefreshIndicatorState extends State<SliverPullRefreshIndicator> {
  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  bool _canRefresh = false;

  static const double _kDragThreshold = 40.0;
  static const double _kRefreshExtent = 70.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant SliverPullRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_handleScroll);
      widget.scrollController.addListener(_handleScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (!widget.scrollController.hasClients) {
      return;
    }

    final position = widget.scrollController.position;

    if (position.pixels < 0) {
      if (_isRefreshing) {
        // Keep scroll position at refresh extent while refreshing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollController.hasClients && _isRefreshing) {
            widget.scrollController.jumpTo(-_kRefreshExtent);
          }
        });
        return;
      }

      final pullDistance = -position.pixels;
      final double clampedPull = pullDistance.clamp(0.0, SliverPullRefreshIndicator.maxStretchExtent);
      final hasReachedThreshold = pullDistance >= _kDragThreshold;

      if (pullDistance > SliverPullRefreshIndicator.maxStretchExtent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollController.hasClients &&
              widget.scrollController.position.pixels < -SliverPullRefreshIndicator.maxStretchExtent) {
            widget.scrollController.jumpTo(-SliverPullRefreshIndicator.maxStretchExtent);
          }
        });
      }

      if (_dragOffset != clampedPull || _canRefresh != hasReachedThreshold) {
        setState(() {
          _dragOffset = clampedPull;

          if (hasReachedThreshold && !_canRefresh) {
            _canRefresh = true;
            HapticFeedback.mediumImpact();
          } else if (!hasReachedThreshold && _canRefresh) {
            _canRefresh = false;
          }
        });
      }

    } else if (_dragOffset > 0 && !_isRefreshing) {
      if (_canRefresh) {
        _handleRefresh();
      } else {
        setState(() {
          _dragOffset = 0.0;
          _canRefresh = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _dragOffset = _kRefreshExtent;
      _canRefresh = false;
    });

    // Keep scroll at refresh position
    widget.scrollController.jumpTo(-_kRefreshExtent);

    HapticFeedback.mediumImpact();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _dragOffset = 0.0;
          _canRefresh = false;
        });

        // Animate back to top
        widget.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  double _calculateOpacity() {
    if (_isRefreshing) return 1.0;
    // Don't show until 30px drag
    if (_dragOffset < 30.0) return 0.0;
    final progress = ((_dragOffset - 30.0).clamp(0.0, _kDragThreshold - 30.0) / (_kDragThreshold - 30.0)).clamp(0.0, 1.0);
    return progress;
  }

  double _calculateScale() {
    if (_isRefreshing) return 1.0;
    // Don't scale until 30px drag
    if (_dragOffset < 30.0) return 0.0;
    final progress = ((_dragOffset - 30.0).clamp(0.0, _kDragThreshold - 30.0) / (_kDragThreshold - 30.0)).clamp(0.0, 1.0);
    return 0.2 + (0.8 * progress);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Get real-time scroll position for instant response
    final realTimeHeight = widget.scrollController.hasClients && widget.scrollController.position.pixels < 0
        ? (-widget.scrollController.position.pixels).clamp(0.0, SliverPullRefreshIndicator.maxStretchExtent)
        : (_isRefreshing ? _kRefreshExtent : 0.0);

    final height = realTimeHeight;

    // Positioned overlay anchored to sticky header
    return Positioned(
      top: Dimensions.stickyHeaderHeight,
      left: Dimensions.paddingSizeExtraSmall,
      right: Dimensions.paddingSizeExtraSmall,
      child: IgnorePointer(
        ignoring: height == 0,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor],
            ),
          ),
          child: height > 0 ? Center(
            child: Opacity(
              opacity: _calculateOpacity(),
              child: Transform.scale(
                scale: _calculateScale(),
                child: OverflowBox(
                  maxWidth: 240,
                  maxHeight: 240,
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Lottie.asset(
                      'assets/animations/go_pull_loading.json',
                      animate: true,
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ) : null,
        ),
      ),
    );
  }
}

class _PullRefreshHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Color primaryColor;
  final double opacity;
  final double scale;
  final bool isRefreshing;

  _PullRefreshHeaderDelegate({
    required this.height,
    required this.primaryColor,
    required this.opacity,
    required this.scale,
    required this.isRefreshing,
  });

  @override
  double get maxExtent => height;

  @override
  double get minExtent => isRefreshing ? height : 0.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (height <= 0) return const SizedBox.shrink();

    // Use LayoutBuilder to get the actual available space
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                primaryColor,
              ],
            ),
          ),
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: opacity,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: scale,
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: Lottie.asset(
                    'assets/animations/go_pull_loading.json',
                    animate: true,
                    repeat: true,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(_PullRefreshHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.opacity != opacity ||
        oldDelegate.scale != scale ||
        oldDelegate.isRefreshing != isRefreshing;
  }
}
