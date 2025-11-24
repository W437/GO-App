import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' show Geolocator, LocationPermission;
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:godelivery_user/config/environment.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/features/location/helper/mapbox_zone_polygon_helper.dart';
import 'package:godelivery_user/helper/ui/map_utils.dart';

/// Animation mode for the map intro
enum MapAnimationMode {
  /// Full spinning globe animation (for first-time users after onboarding)
  full,
  /// Quick fly-in from globe view (for returning users)
  quick,
  /// No animation (skip to final position)
  none,
}

/// Callback types for Mapbox map events
typedef MapboxCameraMoveCallback = void Function(google.CameraPosition position);
typedef MapboxZoneTapCallback = void Function(int zoneId);

/// A Mapbox map widget that mirrors GoogleMap functionality for PickMapScreen
class MapboxPickMapWidget extends StatefulWidget {
  final google.LatLng initialPosition;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final List<ZoneListModel> zones;
  final int? highlightedZoneId;
  final Color zoneBaseColor;
  final bool isDarkMode;
  final MapAnimationMode animationMode;
  final VoidCallback? onMapCreated;
  final VoidCallback? onCameraMoveStarted;
  final MapboxCameraMoveCallback? onCameraMove;
  final VoidCallback? onCameraIdle;
  final MapboxZoneTapCallback? onZoneTap;
  final VoidCallback? onAnimationComplete;

  const MapboxPickMapWidget({
    super.key,
    required this.initialPosition,
    this.initialZoom = 10.43,
    this.minZoom = 6.5,
    this.maxZoom = 14,
    this.zones = const [],
    this.highlightedZoneId,
    required this.zoneBaseColor,
    this.isDarkMode = false,
    this.animationMode = MapAnimationMode.full,
    this.onMapCreated,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onZoneTap,
    this.onAnimationComplete,
  });

  @override
  State<MapboxPickMapWidget> createState() => MapboxPickMapWidgetState();
}

class MapboxPickMapWidgetState extends State<MapboxPickMapWidget> {
  MapboxMap? _mapboxMap;
  PolygonAnnotationManager? _polygonManager;
  PolylineAnnotationManager? _polylineManager;  // For zone border strokes
  PolylineAnnotationManager? _stripeManager;    // For diagonal stripe pattern
  bool _isMoving = false;
  Timer? _idleTimer;
  bool _hasAnimated = false;
  bool _mapReady = false;
  bool _styleReady = false;
  bool _animationComplete = false;
  bool _showOverlay = true;  // White overlay until animation starts
  final String _instanceId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    print('🗺️ [MAPBOX $_instanceId] initState called');
    // Set access token BEFORE map is created
    MapboxOptions.setAccessToken(Environment.mapboxToken);
  }

  @override
  Widget build(BuildContext context) {
    // Set initial camera based on animation mode to prevent flicker
    final CameraOptions initialCamera;
    switch (widget.animationMode) {
      case MapAnimationMode.full:
        // Full animation: start at globe view over North Atlantic
        initialCamera = CameraOptions(
          center: Point(coordinates: Position(-35.0, 35.0)),
          zoom: 0,
          bearing: 0,
          pitch: 0,
        );
        break;
      case MapAnimationMode.quick:
        // Quick animation: start zoomed in on Middle East
        initialCamera = CameraOptions(
          center: Point(coordinates: Position(35.0, 32.0)),
          zoom: 4.0,
          bearing: 0,
          pitch: 0,
        );
        break;
      case MapAnimationMode.none:
        // No animation: start at final position
        initialCamera = CameraOptions(
          center: Point(coordinates: Position(
            widget.initialPosition.longitude,
            widget.initialPosition.latitude,
          )),
          zoom: widget.initialZoom,
          bearing: 0,
          pitch: 0,
        );
        break;
    }

    return Stack(
      children: [
        MapWidget(
          key: ValueKey('mapbox_pick_map_$_instanceId'),
          styleUri: widget.isDarkMode
              ? MapboxStyles.DARK
              : MapboxStyles.STANDARD,
          cameraOptions: initialCamera,
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          onCameraChangeListener: _onCameraChange,
          onTapListener: _onMapTap,
        ),
        // White overlay to hide map until animation starts
        if (_showOverlay)
          AnimatedOpacity(
            opacity: _showOverlay ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(color: Colors.white),
          ),
      ],
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    print('🗺️ [MAPBOX $_instanceId] onMapCreated called');
    _mapboxMap = mapboxMap;

    // Hide map ornaments (logo, scale bar, attribution)
    mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));

    // Disable all gestures during initial animation
    mapboxMap.gestures.updateSettings(GesturesSettings(
      scrollEnabled: false,
      rotateEnabled: false,
      pinchToZoomEnabled: false,
      doubleTapToZoomInEnabled: false,
      doubleTouchToZoomOutEnabled: false,
      quickZoomEnabled: false,
      pitchEnabled: false,
    ));

    // Create annotation managers for zones (polygons for fill, polylines for stroke and stripes)
    _polygonManager = await mapboxMap.annotations.createPolygonAnnotationManager();
    _polylineManager = await mapboxMap.annotations.createPolylineAnnotationManager();
    _stripeManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    // Add zone polygons and strokes
    await _updateZonePolygons();

    _mapReady = true;
    print('🗺️ [MAPBOX $_instanceId] mapReady=true');
    widget.onMapCreated?.call();

    // Try to start animation if style is also ready
    _tryStartGlobeAnimation();
  }

  void _onStyleLoaded(StyleLoadedEventData eventData) async {
    print('🗺️ [MAPBOX $_instanceId] onStyleLoaded called, styleReady=$_styleReady');
    // Prevent multiple triggers
    if (_styleReady) return;
    _styleReady = true;
    print('🗺️ [MAPBOX $_instanceId] styleReady=true');

    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !mounted) {
      print('🗺️ [MAPBOX $_instanceId] onStyleLoaded - mapboxMap null or not mounted, aborting');
      return;
    }

    // Enable globe projection for 3D globe view
    print('🗺️ [MAPBOX $_instanceId] Setting globe projection');
    await mapboxMap.style.setProjection(StyleProjection(name: StyleProjectionName.globe));
    if (!mounted) return;

    // Try to start animation if map is also ready
    _tryStartGlobeAnimation();
  }

  /// Starts the appropriate animation based on animationMode
  void _tryStartGlobeAnimation() async {
    print('🗺️ [MAPBOX $_instanceId] _tryStartGlobeAnimation - mapReady=$_mapReady, styleReady=$_styleReady, hasAnimated=$_hasAnimated, mode=${widget.animationMode}');
    // Wait for both map and style to be ready
    if (!_mapReady || !_styleReady || _hasAnimated) {
      print('🗺️ [MAPBOX $_instanceId] Not ready for animation, returning');
      return;
    }
    _hasAnimated = true;

    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !mounted) {
      print('🗺️ [MAPBOX $_instanceId] mapboxMap null or not mounted, aborting animation');
      return;
    }

    // Hide overlay to reveal map - animation is ready
    if (mounted) {
      setState(() {
        _showOverlay = false;
      });
    }

    // Small delay for overlay fade
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // Choose animation based on mode
    switch (widget.animationMode) {
      case MapAnimationMode.full:
        await _runFullGlobeAnimation(mapboxMap);
        break;
      case MapAnimationMode.quick:
        await _runQuickFlyInAnimation(mapboxMap);
        break;
      case MapAnimationMode.none:
        await _skipToFinalPosition(mapboxMap);
        break;
    }
  }

  /// Full spinning globe animation (for first-time users after onboarding)
  Future<void> _runFullGlobeAnimation(MapboxMap mapboxMap) async {
    print('🗺️ [MAPBOX $_instanceId] Starting FULL globe animation sequence');

    // Force camera to globe view (zoom 0) centered on North Atlantic Ocean
    const northAtlanticLng = -35.0;
    const northAtlanticLat = 35.0;
    print('🗺️ [MAPBOX $_instanceId] Setting camera to zoom 0 (globe) - North Atlantic Ocean');
    await mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(northAtlanticLng, northAtlanticLat)),
        zoom: 0,
        bearing: 0,
        pitch: 0,
      ),
    );
    if (!mounted) return;

    // Small delay to ensure the camera change is rendered
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // Spin the globe 360° smoothly over 2.5 seconds
    print('🗺️ [MAPBOX $_instanceId] Spinning globe 360° smoothly...');
    const spinDurationMs = 2500;
    const frameIntervalMs = 16;  // ~60fps
    const totalFrames = spinDurationMs ~/ frameIntervalMs;

    for (int frame = 0; frame <= totalFrames; frame++) {
      if (!mounted) return;

      final progress = frame / totalFrames;
      double currentLng = northAtlanticLng + (360.0 * progress);
      if (currentLng > 180.0) {
        currentLng -= 360.0;
      }

      await mapboxMap.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(currentLng, northAtlanticLat)),
          zoom: 0,
          bearing: 0,
          pitch: 0,
        ),
      );

      if (frame < totalFrames) {
        await Future.delayed(const Duration(milliseconds: frameIntervalMs));
      }
    }
    if (!mounted) return;

    // Fly to target location (4 seconds)
    final flyToZoom = widget.initialZoom - 0.5;
    print('🗺️ [MAPBOX $_instanceId] Starting flyTo animation (4000ms) to zoom=$flyToZoom');
    mapboxMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(
          widget.initialPosition.longitude,
          widget.initialPosition.latitude,
        )),
        zoom: flyToZoom,
        bearing: 0,
        pitch: 0,
      ),
      MapAnimationOptions(duration: 4000, startDelay: 0),
    );

    await Future.delayed(const Duration(milliseconds: 4000));
    if (!mounted) return;

    await _finalizeAnimation(mapboxMap);
  }

  /// Quick fly-in animation from globe view (for returning users)
  Future<void> _runQuickFlyInAnimation(MapboxMap mapboxMap) async {
    print('🗺️ [MAPBOX $_instanceId] Starting QUICK fly-in animation');

    // Map already starts at Middle East position (set in initialCamera)
    // Just fly to target
    final flyToZoom = widget.initialZoom - 0.5;  // Close to final zoom
    print('🗺️ [MAPBOX $_instanceId] Quick flyTo animation (1500ms) to zoom=$flyToZoom');
    mapboxMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(
          widget.initialPosition.longitude,
          widget.initialPosition.latitude,
        )),
        zoom: flyToZoom,
        bearing: 0,
        pitch: 0,
      ),
      MapAnimationOptions(duration: 1500, startDelay: 0),
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    await _finalizeAnimation(mapboxMap);
  }

  /// Skip animation and go directly to final position
  Future<void> _skipToFinalPosition(MapboxMap mapboxMap) async {
    print('🗺️ [MAPBOX $_instanceId] Skipping animation, going to final position');

    await mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(
          widget.initialPosition.longitude,
          widget.initialPosition.latitude,
        )),
        zoom: widget.initialZoom,
        bearing: 0,
        pitch: 0,
      ),
    );
    if (!mounted) return;

    await _finalizeAnimation(mapboxMap);
  }

  /// Common finalization after any animation completes
  Future<void> _finalizeAnimation(MapboxMap mapboxMap) async {
    print('🗺️ [MAPBOX $_instanceId] Finalizing animation, setting bounds and enabling gestures');

    // Set zoom constraints
    await mapboxMap.setBounds(CameraBoundsOptions(
      minZoom: widget.minZoom,
      maxZoom: widget.maxZoom,
    ));
    if (!mounted) return;

    // Enable gestures
    mapboxMap.gestures.updateSettings(GesturesSettings(
      scrollEnabled: true,
      rotateEnabled: false,
      pinchToZoomEnabled: true,
      doubleTapToZoomInEnabled: true,
      doubleTouchToZoomOutEnabled: true,
      quickZoomEnabled: true,
      pitchEnabled: false,
    ));

    // Mark animation as complete and notify parent
    _animationComplete = true;
    widget.onAnimationComplete?.call();
    print('🗺️ [MAPBOX $_instanceId] Animation sequence complete');

    // Request location permission and show user location
    await _requestLocationAndShowPuck();
  }

  /// Request location permission and enable the location puck on the map
  Future<void> _requestLocationAndShowPuck() async {
    if (_mapboxMap == null || !mounted) return;

    print('🗺️ [MAPBOX $_instanceId] Requesting location permission...');

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      print('🗺️ [MAPBOX $_instanceId] Permission result: $permission');
    }

    if (!mounted) return;

    // If permission granted, enable location puck
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      print('🗺️ [MAPBOX $_instanceId] Enabling location puck');
      await _mapboxMap!.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: false,
          puckBearingEnabled: false,
        ),
      );
    } else {
      print('🗺️ [MAPBOX $_instanceId] Location permission denied: $permission');
    }
  }

  void _onCameraChange(CameraChangedEventData eventData) {
    // Detect camera move started
    if (!_isMoving) {
      _isMoving = true;
      widget.onCameraMoveStarted?.call();
    }

    // Get current camera state and convert to Google format for compatibility
    _mapboxMap?.getCameraState().then((cameraState) {
      final googlePosition = google.CameraPosition(
        target: MapUtils.pointToGoogleLatLng(cameraState.center),
        zoom: cameraState.zoom,
        bearing: cameraState.bearing,
        tilt: cameraState.pitch,
      );
      widget.onCameraMove?.call(googlePosition);
    });

    // Proper debounce - cancel previous timer and start new one
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 100), () {
      if (_isMoving) {
        _isMoving = false;
        widget.onCameraIdle?.call();
      }
    });
  }

  void _onMapTap(MapContentGestureContext context) async {
    // Block taps during animation
    if (!_animationComplete) return;
    if (_polygonManager == null || widget.zones.isEmpty) return;

    // Check if tap is inside any zone polygon
    final tapPosition = Position(
      context.point.coordinates.lng,
      context.point.coordinates.lat,
    );

    final zoneId = MapboxZonePolygonHelper.getZoneIdForPoint(
      tapPosition,
      widget.zones,
    );

    if (zoneId != null) {
      widget.onZoneTap?.call(zoneId);
    }
  }

  /// Update zone polygons on the map
  Future<void> _updateZonePolygons() async {
    if (_polygonManager == null) return;

    // Clear existing polygons, strokes, and stripes
    await _polygonManager!.deleteAll();
    await _polylineManager?.deleteAll();
    await _stripeManager?.deleteAll();

    if (widget.zones.isEmpty) return;

    // Build polygon data
    final polygonData = MapboxZonePolygonHelper.buildPolygons(
      zones: widget.zones,
      baseColor: widget.zoneBaseColor,
      highlightedZoneId: widget.highlightedZoneId,
    );

    // Create polygon annotations (fill)
    final fillOptions = polygonData.map((p) =>
      MapboxZonePolygonHelper.createPolygonAnnotationOptions(p)
    ).toList();

    if (fillOptions.isNotEmpty) {
      await _polygonManager!.createMulti(fillOptions);
    }

    // Create polyline annotations (stroke/border)
    if (_polylineManager != null) {
      final strokeOptions = polygonData.map((p) =>
        MapboxZonePolygonHelper.createPolylineAnnotationOptions(p)
      ).toList();

      if (strokeOptions.isNotEmpty) {
        await _polylineManager!.createMulti(strokeOptions);
      }
    }

    // Create diagonal stripe pattern inside zones
    if (_stripeManager != null) {
      final allStripeOptions = <PolylineAnnotationOptions>[];
      for (final polygon in polygonData) {
        final stripes = MapboxZonePolygonHelper.createStripeAnnotationOptions(polygon);
        allStripeOptions.addAll(stripes);
      }

      if (allStripeOptions.isNotEmpty) {
        await _stripeManager!.createMulti(allStripeOptions);
      }
    }
  }

  /// Update polygons when zones or highlighted zone changes
  void updatePolygons(List<ZoneListModel> zones, int? highlightedZoneId) {
    if (_polygonManager != null) {
      _updateZonePolygons();
    }
  }

  /// Animate camera to a new position
  Future<void> animateCamera(google.LatLng target, {double? zoom}) async {
    if (_mapboxMap == null) return;

    final currentState = await _mapboxMap!.getCameraState();

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: MapUtils.toMapboxPoint(target),
        zoom: zoom ?? currentState.zoom,
      ),
      MapAnimationOptions(duration: 300),
    );
  }

  /// Animate camera to fit bounds
  Future<void> animateToBounds(google.LatLngBounds bounds, {double padding = 50}) async {
    if (_mapboxMap == null) return;

    // Convert Google LatLngBounds to Mapbox CoordinateBounds
    final southwest = MapUtils.toMapboxPoint(bounds.southwest);
    final northeast = MapUtils.toMapboxPoint(bounds.northeast);

    final coordinateBounds = CoordinateBounds(
      southwest: southwest,
      northeast: northeast,
      infiniteBounds: false,
    );

    // Calculate camera for bounds
    final cameraOptions = await _mapboxMap!.cameraForCoordinateBounds(
      coordinateBounds,
      MbxEdgeInsets(
        top: padding,
        left: padding,
        bottom: padding + 150, // Extra padding at bottom for badge
        right: padding,
      ),
      null, // bearing
      null, // pitch
      null, // maxZoom
      null, // offset
    );

    await _mapboxMap!.flyTo(
      cameraOptions,
      MapAnimationOptions(duration: 500),
    );
  }

  /// Move camera without animation
  Future<void> moveCamera(google.LatLng target, {double? zoom}) async {
    if (_mapboxMap == null) return;

    final currentState = await _mapboxMap!.getCameraState();

    await _mapboxMap!.setCamera(
      CameraOptions(
        center: MapUtils.toMapboxPoint(target),
        zoom: zoom ?? currentState.zoom,
      ),
    );
  }

  /// Get current camera position
  Future<google.CameraPosition?> getCameraPosition() async {
    if (_mapboxMap == null) return null;

    final state = await _mapboxMap!.getCameraState();
    return google.CameraPosition(
      target: MapUtils.pointToGoogleLatLng(state.center),
      zoom: state.zoom,
      bearing: state.bearing,
      tilt: state.pitch,
    );
  }

  @override
  void didUpdateWidget(MapboxPickMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update polygons if zones or highlight changed
    if (oldWidget.zones != widget.zones ||
        oldWidget.highlightedZoneId != widget.highlightedZoneId) {
      _updateZonePolygons();
    }
  }

  @override
  void dispose() {
    print('🗺️ [MAPBOX $_instanceId] dispose called');
    _idleTimer?.cancel();
    _polygonManager = null;
    _polylineManager = null;
    _stripeManager = null;
    _mapboxMap = null;
    super.dispose();
  }
}
