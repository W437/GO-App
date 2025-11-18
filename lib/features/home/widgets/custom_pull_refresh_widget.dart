import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _SliverPullRefreshIndicatorState extends State<SliverPullRefreshIndicator> with TickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  bool _isDismissingIndicator = false;
  bool _armedForRefresh = false;
  ValueNotifier<bool>? _scrollActivityNotifier;
  late final AnimationController _dismissController;
  late final AnimationController _snapController;
  double _snapStartFraction = 0.0;
  late final AnimationController _completionPulseController;
  DateTime? _cooldownUntil;
  static const Duration _refreshCooldownDuration = Duration(milliseconds: 900);

  static const double _kDragThreshold = 40.0;
  static const double _kRefreshExtent = 70.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachScrollActivityListener());
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(() {
        if (_isDismissingIndicator && mounted) {
          setState(() {});
        }
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _isDismissingIndicator = false;
            _dragOffset = 0.0;
          });
          _cooldownUntil = DateTime.now().add(_refreshCooldownDuration);
        }
      });
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        if (_isRefreshing && mounted) {
          setState(() {});
        }
      })..addStatusListener((status) {
        if (mounted) {
          setState(() {});
        }
      })
      ..value = 1.0;
    _completionPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..addListener(() {
        if (_showCompletionState && mounted) {
          setState(() {});
        }
      });
  }

  @override
  void didUpdateWidget(covariant SliverPullRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_handleScroll);
      widget.scrollController.addListener(_handleScroll);
      _detachScrollActivityListener();
      WidgetsBinding.instance.addPostFrameCallback((_) => _attachScrollActivityListener());
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    _detachScrollActivityListener();
    _dismissController.dispose();
    _snapController.dispose();
    _completionPulseController.dispose();
    super.dispose();
  }

  void _attachScrollActivityListener() {
    _detachScrollActivityListener();
    if (!mounted || !widget.scrollController.hasClients) return;
    _scrollActivityNotifier = widget.scrollController.position.isScrollingNotifier;
    _scrollActivityNotifier?.addListener(_handleScrollActivity);
  }

  void _detachScrollActivityListener() {
    _scrollActivityNotifier?.removeListener(_handleScrollActivity);
    _scrollActivityNotifier = null;
  }

  void _handleScrollActivity() {
    if (!mounted || _isRefreshing) return;
    final bool isScrolling = _scrollActivityNotifier?.value ?? true;
    if (!isScrolling && _armedForRefresh && !_isCoolingDown) {
      _handleRefresh();
    }
  }

  void _handleScroll() {
    if (!widget.scrollController.hasClients) {
      return;
    }

    final position = widget.scrollController.position;

    if (!_isRefreshing && _isDismissingIndicator && position.pixels < 0) {
      return;
    }

    if (position.pixels < 0) {
      if (_isRefreshing) {
        if (_dragOffset != _kRefreshExtent) {
          setState(() {
            _dragOffset = _kRefreshExtent;
          });
        }
        return;
      }

      final pullDistance = -position.pixels;
      final double clampedPull = pullDistance.clamp(0.0, SliverPullRefreshIndicator.maxStretchExtent);
      final hasReachedThreshold = pullDistance >= _kDragThreshold;
      final bool isDragging = position.activity is DragScrollActivity;

      if (pullDistance > SliverPullRefreshIndicator.maxStretchExtent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollController.hasClients &&
              widget.scrollController.position.pixels < -SliverPullRefreshIndicator.maxStretchExtent) {
            widget.scrollController.jumpTo(-SliverPullRefreshIndicator.maxStretchExtent);
          }
        });
      }

      if (!isDragging && _armedForRefresh && !_isRefreshing) {
        _handleRefresh();
        return;
      }

      if (_dragOffset != clampedPull || (isDragging && hasReachedThreshold != _armedForRefresh)) {
        setState(() {
          _dragOffset = clampedPull;

          if (isDragging) {
            if (hasReachedThreshold && !_armedForRefresh) {
              _armedForRefresh = true;
              HapticFeedback.mediumImpact();
            } else if (!hasReachedThreshold && _armedForRefresh) {
              _armedForRefresh = false;
            }
          }
        });
      }

    } else if (_dragOffset > 0 && !_isRefreshing) {
      if (_armedForRefresh && !_isCoolingDown && !_isDismissingIndicator) {
        _handleRefresh();
      } else {
        setState(() {
          _dragOffset = 0.0;
          _armedForRefresh = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing || _isCoolingDown || _isDismissingIndicator) return;

    final DateTime startTime = DateTime.now();
    final double initialSnapFraction = (_dragOffset / _kRefreshExtent).clamp(0.0, 1.0);
    _dismissController.stop();
    _dismissController.reset();
    _completionPulseController.reset();

    setState(() {
      _isRefreshing = true;
      _isDismissingIndicator = false;
      _dragOffset = _kRefreshExtent;
      _armedForRefresh = false;
      _snapStartFraction = initialSnapFraction;
      _cooldownUntil = null;
    });
    _snapController.forward(from: 0.0);

    HapticFeedback.mediumImpact();

    try {
      await widget.onRefresh();
    } finally {
      final elapsed = DateTime.now().difference(startTime);
      final remaining = const Duration(seconds: 1) - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isDismissingIndicator = true;
          _dragOffset = _kRefreshExtent;
          _armedForRefresh = false;
        });
        _completionPulseController.forward(from: 0.0);

        // Keep the completion state visible for a beat before animating out
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted && _isDismissingIndicator) {
            _dismissController.forward(from: 0);
          }
        });
      }
    }
  }

  double get _pullProgress {
    if (_isRefreshing || _isDismissingIndicator) return 1.0;
    const double deadZone = _kDragThreshold * 0.45; // extended idle zone
    final double completionZone = (_kDragThreshold * 2 - deadZone).clamp(1, double.infinity);
    final double adjustedDrag = (_dragOffset - deadZone).clamp(0.0, completionZone);
    return (adjustedDrag / completionZone).clamp(0.0, 1.0);
  }

  bool get _isReadyToRelease => !_isRefreshing && _dragOffset >= _kDragThreshold;
  bool get _showCompletionState => !_isRefreshing && _isDismissingIndicator;
  bool get _showRefreshingCopy => _isRefreshing;
  bool get _isCoolingDown => _cooldownUntil != null && _cooldownUntil!.isAfter(DateTime.now());

  String get _statusHeadline {
    if (_showRefreshingCopy) {
      return 'Refreshing your feed';
    } else if (_showCompletionState) {
      return 'Freshly updated';
    } else if (_isReadyToRelease) {
      return 'Release for fresh picks';
    } else {
      return 'Pull for today\'s bites';
    }
  }

  String get _statusDetail {
    if (_showRefreshingCopy) {
      return 'Fetching the latest restaurants and offers';
    } else if (_showCompletionState) {
      return 'All caught up. Enjoy the new bites!';
    } else if (_isReadyToRelease) {
      return 'You\'re right there — let go to reload';
    } else {
      return 'Drag down gently to check what\'s new';
    }
  }

  Widget _buildIndicatorBadge(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = _pullProgress;
    final Color borderColor = theme.primaryColor.withOpacity(0.15 + (0.25 * progress));
    final Color haloColor = theme.primaryColor.withOpacity(0.05 + (0.08 * progress));
    const double statusWidth = 205;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 25,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: haloColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIndicatorAvatar(theme, progress),
          const SizedBox(width: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutBack,
                )),
                child: child,
              ),
            ),
            child: _showCompletionState
                ? SizedBox(
                    width: statusWidth,
                    key: const ValueKey('completed'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Feed refreshed',
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ) ??
                              TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enjoy the latest picks',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              ) ??
                              TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: statusWidth,
                    key: const ValueKey('default'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ) ??
                              TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                          child: Text(_statusHeadline, maxLines: 1, overflow: TextOverflow.fade),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.75) ??
                                    Colors.black.withOpacity(0.6),
                              ) ??
                              TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.6),
                              ),
                          child: Text(
                            _statusDetail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildProgressBar(theme, progress),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorAvatar(ThemeData theme, double progress) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.primaryColor.withOpacity(0.08 + (0.18 * progress)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: _isRefreshing
            ? CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation(theme.primaryColor),
              )
            : _showCompletionState
                ? Icon(Icons.check_rounded, color: theme.primaryColor, size: 28)
                : Stack(
                alignment: Alignment.center,
                children: [
                  if (progress > 0)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 2.4,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                      ),
                    ),
                  Icon(
                    Icons.soup_kitchen_outlined,
                    color: theme.primaryColor,
                    size: 26,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, double progress) {
    const double barWidth = 150;
    return Container(
      width: barWidth,
      height: 4,
      decoration: BoxDecoration(
        color: theme.disabledColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: (barWidth * (progress.clamp(0.0, 1.0))),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get real-time scroll position for instant response
    final realTimeHeight = widget.scrollController.hasClients && widget.scrollController.position.pixels < 0
        ? (-widget.scrollController.position.pixels).clamp(0.0, SliverPullRefreshIndicator.maxStretchExtent)
        : (_isRefreshing ? _kRefreshExtent : 0.0);

    final bool shouldRenderIndicator = realTimeHeight > 4 || _isRefreshing || _isDismissingIndicator;
    if (!shouldRenderIndicator) {
      return const SizedBox.shrink();
    }

    final double indicatorHeight = (_isRefreshing || _isDismissingIndicator)
        ? _kRefreshExtent
        : realTimeHeight;
    final double snapProgress = _isRefreshing ? _snapController.value.clamp(0.0, 1.0) : 1.0;
    final double snapCurve = _isRefreshing ? Curves.elasticOut.transform(snapProgress) : 1.0;
    final double refreshingHeight = _isRefreshing
        ? lerpDouble(_snapStartFraction * _kRefreshExtent, _kRefreshExtent, snapCurve)!
        : indicatorHeight;
    final double translateY = (refreshingHeight - 20).clamp(0.0, SliverPullRefreshIndicator.maxStretchExtent);

    double targetScale;
    double targetOpacity;
    if (_isDismissingIndicator) {
      final dismissProgress = _dismissController.value.clamp(0.0, 1.0);
      final double pulse =
          1 + 0.06 * Curves.elasticOut.transform(_completionPulseController.value.clamp(0.0, 1.0));
      targetScale = (1.0 - (dismissProgress * 0.2)) * pulse;
      targetOpacity = 1.0 - dismissProgress;
    } else if (_isRefreshing) {
      final double bounce = Curves.easeOutBack.transform(snapProgress);
      targetScale = lerpDouble(
        (_snapStartFraction.clamp(0.7, 1.0)),
        1.05,
        bounce,
      )!;
      targetOpacity = Curves.easeOut.transform(snapProgress);
    } else {
      final appearProgress = (_dragOffset / SliverPullRefreshIndicator.maxStretchExtent).clamp(0.0, 1.0);
      final curve = Curves.easeOutExpo.transform(appearProgress);
      const double baseScale = 0.55;
      const double scaleRange = 0.45;
      targetScale = baseScale + (scaleRange * curve);
      targetOpacity = Curves.easeOutCubic.transform(appearProgress);
    }

    return Positioned(
      top: Dimensions.stickyHeaderHeight - 24,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_isRefreshing && realTimeHeight <= 4,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          opacity: targetOpacity.clamp(0.0, 1.0),
          child: SizedBox(
            height: SliverPullRefreshIndicator.maxStretchExtent + 64,
            child: Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  scale: targetScale.clamp(0.7, 1.0),
                  child: _buildIndicatorBadge(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
