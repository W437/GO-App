import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_sheet.dart';
import 'package:godelivery_user/features/location/widgets/all_zones_sheet.dart';

class ZoneFloatingBadge extends StatefulWidget {
  final ZoneListModel? selectedZone;
  final List<ZoneListModel> zones;
  final Function(ZoneListModel?) onZoneChanged;
  final VoidCallback onConfirm;
  final int? userSavedZoneId; // User's currently saved zone ID

  const ZoneFloatingBadge({
    super.key,
    required this.selectedZone,
    required this.zones,
    required this.onZoneChanged,
    required this.onConfirm,
    this.userSavedZoneId,
  });

  @override
  State<ZoneFloatingBadge> createState() => _ZoneFloatingBadgeState();
}

class _ZoneFloatingBadgeState extends State<ZoneFloatingBadge> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  PageController? _pageController;
  int _currentIndex = 0;
  bool _isSwipingInternally = false; // Track if change is from swipe vs external

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));

    // Initialize page controller if we have zones
    if (widget.zones.isNotEmpty) {
      if (widget.selectedZone != null) {
        _currentIndex = widget.zones.indexWhere((z) => z.id == widget.selectedZone!.id);
        if (_currentIndex == -1) _currentIndex = 0;
      }
      _pageController = PageController(initialPage: _currentIndex);
    }

    // Trigger animations when zone is selected
    if (widget.selectedZone != null) {
      _slideController.forward();
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(ZoneFloatingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle zone selection changes
    if (widget.selectedZone != oldWidget.selectedZone) {
      if (widget.selectedZone != null) {
        // Animate in
        if (!_slideController.isCompleted) {
          _slideController.forward();
        }
        if (!_scaleController.isCompleted) {
          _scaleController.forward();
        }

        // Only update page if change is NOT from internal swipe
        if (!_isSwipingInternally && widget.zones.isNotEmpty) {
          final newIndex = widget.zones.indexWhere((z) => z.id == widget.selectedZone!.id);
          if (newIndex != -1 && newIndex != _currentIndex) {
            setState(() {
              _currentIndex = newIndex;
            });
            // Jump to page when zone is selected from map tap
            if (_pageController != null && _pageController!.hasClients) {
              _pageController!.jumpToPage(_currentIndex);
            } else {
              // Recreate page controller with new initial page
              _pageController?.dispose();
              _pageController = PageController(initialPage: _currentIndex);
            }
          }
        }
        // Reset the flag
        _isSwipingInternally = false;
      } else {
        // Animate out
        _slideController.reverse();
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  String _getZoneInitial(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  Color _getZoneColor(int? zoneId) {
    final colors = [
      const Color(0xFF00BFA6),  // Teal
      const Color(0xFF7C4DFF),  // Purple
      const Color(0xFFFF6D00),  // Orange
      const Color(0xFF00C853),  // Green
      const Color(0xFF2962FF),  // Blue
      const Color(0xFFD50000),  // Red
      const Color(0xFFFFAB00),  // Amber
      const Color(0xFF6200EA),  // Deep Purple
    ];
    return colors[(zoneId ?? 0) % colors.length];
  }


  Widget _buildZoneBadge(ZoneListModel zone) {
    final zoneColor = _getZoneColor(zone.id);
    final zoneName = zone.displayName ?? zone.name ?? 'Zone ${zone.id}';
    const operatingHours = '10:00 AM - 11:00 PM';
    const restaurantCount = 28;
    final isOpen = zone.status == 1;
    final isUserCurrentZone = widget.userSavedZoneId != null && zone.id == widget.userSavedZoneId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800]!.withOpacity(0.7),
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              border: Border.all(
                color: isUserCurrentZone
                    ? Theme.of(context).primaryColor
                    : Colors.white.withOpacity(0.1),
                width: isUserCurrentZone ? 3 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top section with zone info and status
                Stack(
                  children: [
                    Row(
                      children: [
                        // Zone initial circle
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: zoneColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getZoneInitial(zoneName),
                              style: robotoBold.copyWith(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Zone details
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                zoneName,
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    operatingHours,
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.restaurant,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$restaurantCount ${'restaurants'.tr}',
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Status indicator positioned at top right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Active/Closed status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? Colors.greenAccent.withOpacity(0.2)
                                  : Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: isOpen ? Colors.greenAccent : Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOpen ? 'Active' : 'Closed',
                                  style: robotoMedium.copyWith(
                                    fontSize: 10,
                                    color: isOpen ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if no zone is selected
    if (widget.selectedZone == null) {
      return const SizedBox.shrink();
    }

    // Get current zone info for buttons
    final currentZone = widget.zones.isNotEmpty && _currentIndex < widget.zones.length
        ? widget.zones[_currentIndex]
        : widget.selectedZone!;
    final isOpen = currentZone.status == 1;
    final isUserCurrentZone = widget.userSavedZoneId != null && currentZone.id == widget.userSavedZoneId;

    // Show zone badge with swipe functionality
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Swipeable badge
            widget.zones.length <= 1
                ? _buildZoneBadge(widget.selectedZone!)
                : SizedBox(
                    height: 90, // Reduced height since buttons are outside
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      pageSnapping: true,
                      itemCount: widget.zones.length,
                      onPageChanged: (index) {
                        if (_currentIndex != index) {
                          setState(() {
                            _currentIndex = index;
                            _isSwipingInternally = true; // Mark as internal swipe
                          });
                          // Notify parent of zone change without interrupting animation
                          widget.onZoneChanged(widget.zones[index]);
                        }
                      },
                      itemBuilder: (context, index) {
                        if (_pageController == null) {
                          return _buildZoneBadge(widget.zones[index]);
                        }

                        return AnimatedBuilder(
                          animation: _pageController!,
                          builder: (context, child) {
                            double scale = 1.0;
                            if (_pageController!.hasClients &&
                                _pageController!.positions.length == 1 &&
                                _pageController!.position.haveDimensions) {
                              final page = _pageController!.page ?? _currentIndex.toDouble();
                              final distanceFromCurrent = (page - index).abs();
                              // Scale from 0.9 to 1.0 with slight bounce when settling
                              scale = (1.0 - (distanceFromCurrent * 0.1)).clamp(0.9, 1.0);
                            }
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: scale, end: scale),
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: child,
                            );
                          },
                          child: _buildZoneBadge(widget.zones[index]),
                        );
                      },
                    ),
                  ),
            // Static pagination dots below
            if (widget.zones.length > 1)
              Container(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.zones.length.clamp(0, 10),
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: index == _currentIndex ? 8 : 6,
                      height: index == _currentIndex ? 8 : 6,
                      decoration: BoxDecoration(
                        color: index == _currentIndex
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            // Action buttons below badge
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(
                children: [
                  // Map/Zones button
                  Expanded(
                    flex: 1,
                    child: CustomButtonWidget(
                      height: 46,
                      buttonText: 'Zones',
                      icon: Icons.map_outlined,
                      color: Colors.white.withOpacity(0.15),
                      textColor: Colors.white.withOpacity(0.9),
                      onPressed: () {
                        CustomSheet.show(
                          context: context,
                          child: const AllZonesSheet(),
                          showHandle: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeExtraLarge,
                            vertical: Dimensions.paddingSizeDefault,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Confirm button - disabled if user's current zone or closed
                  Expanded(
                    flex: 2,
                    child: CustomButtonWidget(
                      height: 46,
                      buttonText: isUserCurrentZone
                          ? 'current_zone'.tr
                          : 'confirm_zone_selection'.tr,
                      onPressed: (isOpen && !isUserCurrentZone) ? widget.onConfirm : null,
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}