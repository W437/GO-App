import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godelivery_user/util/dimensions.dart';

class SliverPullRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;

  /// Maximum stretch allowed for the pull gap.
  static const double maxStretchExtent = 100.0;

  const SliverPullRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.scrollController,
  });

  @override
  State<SliverPullRefreshIndicator> createState() => _SliverPullRefreshIndicatorState();
}

class _SliverPullRefreshIndicatorState extends State<SliverPullRefreshIndicator>
    with SingleTickerProviderStateMixin {

  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  bool _isDismissing = false;
  bool _wasArmed = false;
  bool _hasTriggeredHaptic = false;
  bool _wasDragging = false;

  late final AnimationController _hideController;

  // Thresholds for pull to refresh
  static const double _triggerThreshold = 100.0;
  static const double _showIndicatorThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _dragOffset = 0.0;
          _isDismissing = false;
        });
      }
    });
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
    _hideController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!widget.scrollController.hasClients || _isRefreshing) return;

    final position = widget.scrollController.position;

    if (position.pixels < 0) {
      final pullDistance = -position.pixels;
      final bool isDragging = position.activity is DragScrollActivity;

      // Clamp the visual offset
      final clampedPull = pullDistance.clamp(0.0, SliverPullRefreshIndicator.maxStretchExtent);

      if (clampedPull != _dragOffset) {
        setState(() {
          _dragOffset = clampedPull;
        });
      }

      // Check if armed (past threshold)
      final isArmed = pullDistance >= _triggerThreshold;

      // Haptic feedback when crossing threshold
      if (isArmed && !_hasTriggeredHaptic) {
        _hasTriggeredHaptic = true;
        HapticFeedback.mediumImpact();
      } else if (!isArmed && _hasTriggeredHaptic) {
        _hasTriggeredHaptic = false;
      }

      // Detect release: was dragging, now not dragging
      if (_wasDragging && !isDragging && _wasArmed && !_isRefreshing) {
        _triggerRefresh();
        _wasDragging = false;
        return;
      }

      // Track states
      _wasDragging = isDragging;
      if (isDragging) {
        _wasArmed = isArmed;
      }

    } else if (_dragOffset > 0 && !_isRefreshing) {
      // Scrolled back to top - if was armed, trigger refresh
      if (_wasArmed) {
        _triggerRefresh();
      } else {
        setState(() {
          _dragOffset = 0.0;
          _wasArmed = false;
          _hasTriggeredHaptic = false;
          _wasDragging = false;
        });
      }
    }
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;

    _wasArmed = false;
    _hasTriggeredHaptic = false;
    _wasDragging = false;
    _isDismissing = false;
    _hideController.reset();

    setState(() {
      _isRefreshing = true;
      _dragOffset = _triggerThreshold;
    });

    HapticFeedback.mediumImpact();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        // Small delay to show completion
        await Future.delayed(const Duration(milliseconds: 300));

        setState(() {
          _isRefreshing = false;
          _isDismissing = true;
        });

        // Animate out
        _hideController.forward(from: 0.0);
      }
    }
  }

  double get _progress {
    if (_isRefreshing) return 1.0;
    return (_dragOffset / _triggerThreshold).clamp(0.0, 1.0);
  }

  bool get _isArmed => _dragOffset >= _triggerThreshold;

  @override
  Widget build(BuildContext context) {
    // Don't show until pulled enough
    if (_dragOffset < _showIndicatorThreshold && !_isRefreshing && !_isDismissing) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final progress = _progress;

    // Calculate opacity for hide animation
    final hideOpacity = _isDismissing
        ? (1.0 - _hideController.value)
        : 1.0;

    // Animate in from scale 0.4 and opacity 0
    final scale = _isDismissing ? 1.0 : (0.4 + (0.6 * progress)).clamp(0.4, 1.0);
    final opacity = _isDismissing ? hideOpacity : (progress).clamp(0.0, 1.0);

    return Positioned(
      top: Dimensions.stickyHeaderHeight + 50,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicator circle
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: (_isRefreshing || _isDismissing)
                          ? CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 2.5,
                                  backgroundColor: theme.primaryColor.withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                                ),
                                AnimatedRotation(
                                  turns: _isArmed ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 14,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Text
                    Text(
                      (_isRefreshing || _isDismissing)
                          ? 'Refreshing...'
                          : _isArmed
                              ? 'Release to refresh'
                              : 'Pull to refresh',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
