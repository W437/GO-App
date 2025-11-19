import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ZonePolygonHelper {
  const ZonePolygonHelper._();

  static Set<Polygon> buildPolygons({
    required List<ZoneListModel> zones,
    required Color baseColor,
    double strokeOpacity = 0.9,
    double fillOpacity = 0.12,
    double hueStep = 18,
    int? highlightedZoneId,
    bool useEnhancedStyle = true,
    Function(int)? onZoneTap,
  }) {
    final polygons = <Polygon>{};

    for (int index = 0; index < zones.length; index++) {
      final zone = zones[index];
      if (zone.formattedCoordinates == null || zone.formattedCoordinates!.isEmpty) {
        continue;
      }

      final points = <LatLng>[];
      for (final coord in zone.formattedCoordinates!) {
        if (coord.lat == null || coord.lng == null) {
          continue;
        }
        points.add(LatLng(coord.lat!, coord.lng!));
      }

      if (points.length < 3) {
        continue;
      }

      final isHighlighted = highlightedZoneId != null && zone.id == highlightedZoneId;
      final isOtherZone = highlightedZoneId != null && zone.id != highlightedZoneId;
      final colorVariant = _colorForZone(baseColor, zone.id ?? index, hueStep: hueStep);

      // Thinner strokes and dimming for non-selected zones
      final effectiveStrokeWidth = isHighlighted ? 3 : 2; // Thinner strokes (must be int)

      // Slightly dim non-selected zones when one is highlighted
      final effectiveStrokeOpacity = isHighlighted
          ? 1.0
          : (isOtherZone ? strokeOpacity * 0.7 : strokeOpacity * 0.85).clamp(0.0, 1.0);

      final effectiveFillOpacity = isHighlighted
          ? (fillOpacity * 2.0).clamp(0.0, 0.3)
          : (isOtherZone
              ? fillOpacity * 0.8  // Less dimming for better visibility
              : fillOpacity * 1.3).clamp(0.0, 1.0);

      // Mute colors for non-selected zones
      final effectiveColor = isOtherZone
          ? _mutedColor(colorVariant)
          : colorVariant;

      polygons.add(Polygon(
        polygonId: PolygonId('zone_${zone.id ?? polygons.length}'),
        points: points,
        strokeWidth: effectiveStrokeWidth,
        strokeColor: effectiveColor.withOpacity(effectiveStrokeOpacity),
        fillColor: effectiveColor.withOpacity(effectiveFillOpacity),
        consumeTapEvents: true,  // Make zones clickable
        geodesic: true,
        onTap: () {
          if (onZoneTap != null && zone.id != null) {
            onZoneTap(zone.id!);
          }
        },
      ));
    }

    return polygons;
  }

  // Check if a point is inside a polygon using ray casting algorithm
  static int? getZoneIdForPoint(LatLng point, List<ZoneListModel> zones) {
    for (var zone in zones) {
      if (zone.formattedCoordinates == null || zone.formattedCoordinates!.isEmpty) {
        continue;
      }

      final points = <LatLng>[];
      for (final coord in zone.formattedCoordinates!) {
        if (coord.lat == null || coord.lng == null) {
          continue;
        }
        points.add(LatLng(coord.lat!, coord.lng!));
      }

      if (points.length < 3) {
        continue;
      }

      if (_isPointInPolygon(point, points)) {
        return zone.id;
      }
    }
    return null;
  }

  // Ray casting algorithm to check if point is inside polygon
  static bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersections = 0;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) {
        double slope = (point.longitude - polygon[i].longitude) * (polygon[j].latitude - polygon[i].latitude) /
            (polygon[j].longitude - polygon[i].longitude) + polygon[i].latitude;
        if (point.latitude < slope) {
          intersections++;
        }
      }
      j = i;
    }

    return intersections % 2 != 0;
  }

  // Create a slightly muted version of the color for non-selected zones
  static Color _mutedColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    // Slightly reduce saturation for subtle muting
    return HSLColor.fromAHSL(
      hsl.alpha,
      hsl.hue,
      hsl.saturation * 0.6,  // Higher saturation for better visibility
      math.min(0.65, hsl.lightness * 1.1),  // Slightly lighter
    ).toColor();
  }

  static Color _colorForZone(Color baseColor, int seed, {double hueStep = 18}) {
    final hsl = HSLColor.fromColor(baseColor);
    final hueOffset = (seed * hueStep) % 360;
    final adjustedHue = (hsl.hue + hueOffset) % 360;

    // Enhanced color generation for better visibility
    // Increase saturation for more vibrant colors
    final enhancedSaturation = math.min(1.0, hsl.saturation * 1.2);

    // Use a more controlled lightness range for better contrast
    final lightness = 0.45 + (0.15 * math.sin(seed * 0.5));

    return HSLColor.fromAHSL(
      hsl.alpha,
      adjustedHue,
      enhancedSaturation,
      lightness.clamp(0.4, 0.6),
    ).toColor();
  }
}
