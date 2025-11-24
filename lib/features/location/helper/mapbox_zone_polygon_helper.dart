import 'package:flutter/material.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Data class to hold polygon annotation options for Mapbox zones
class MapboxZonePolygon {
  final int zoneId;
  final List<Position> coordinates;
  final Color fillColor;
  final Color strokeColor;
  final double fillOpacity;
  final double strokeOpacity;
  final double strokeWidth;

  MapboxZonePolygon({
    required this.zoneId,
    required this.coordinates,
    required this.fillColor,
    required this.strokeColor,
    required this.fillOpacity,
    required this.strokeOpacity,
    this.strokeWidth = 2.5,
  });
}

class MapboxZonePolygonHelper {
  const MapboxZonePolygonHelper._();

  /// Build polygon data for Mapbox zones
  static List<MapboxZonePolygon> buildPolygons({
    required List<ZoneListModel> zones,
    required Color baseColor,
    double strokeOpacity = 0.9,
    double fillOpacity = 0.12,
    int? highlightedZoneId,
  }) {
    final polygons = <MapboxZonePolygon>[];

    for (int index = 0; index < zones.length; index++) {
      final zone = zones[index];
      if (zone.formattedCoordinates == null || zone.formattedCoordinates!.isEmpty) {
        continue;
      }

      final points = <Position>[];
      for (final coord in zone.formattedCoordinates!) {
        if (coord.lat == null || coord.lng == null) {
          continue;
        }
        // Mapbox Position takes (lng, lat) order
        points.add(Position(coord.lng!, coord.lat!));
      }

      if (points.length < 3) {
        continue;
      }

      // Close the polygon by adding the first point at the end if not already closed
      if (points.first.lng != points.last.lng || points.first.lat != points.last.lat) {
        points.add(points.first);
      }

      final isHighlighted = highlightedZoneId != null && zone.id == highlightedZoneId;
      final isOtherZone = highlightedZoneId != null && zone.id != highlightedZoneId;

      // Slightly dim non-selected zones when one is highlighted
      final effectiveStrokeOpacity = isHighlighted
          ? 1.0
          : (isOtherZone ? strokeOpacity * 0.7 : strokeOpacity * 0.85).clamp(0.0, 1.0);

      final effectiveFillOpacity = isHighlighted
          ? (fillOpacity * 2.0).clamp(0.0, 0.3)
          : (isOtherZone
              ? fillOpacity * 0.8
              : fillOpacity * 1.3).clamp(0.0, 1.0);

      // Stroke width varies based on highlight state
      final effectiveStrokeWidth = isHighlighted ? 3.5 : 2.5;

      polygons.add(MapboxZonePolygon(
        zoneId: zone.id ?? index,
        coordinates: points,
        fillColor: baseColor,
        strokeColor: baseColor,
        fillOpacity: effectiveFillOpacity,
        strokeOpacity: effectiveStrokeOpacity,
        strokeWidth: effectiveStrokeWidth,
      ));
    }

    return polygons;
  }

  /// Create PolygonAnnotationOptions for a zone polygon (fill only)
  static PolygonAnnotationOptions createPolygonAnnotationOptions(
    MapboxZonePolygon polygon,
  ) {
    return PolygonAnnotationOptions(
      geometry: Polygon(
        coordinates: [polygon.coordinates],
      ),
      fillColor: polygon.fillColor.toARGB32(),
      fillOpacity: polygon.fillOpacity,
    );
  }

  /// Create PolylineAnnotationOptions for a zone border (stroke)
  static PolylineAnnotationOptions createPolylineAnnotationOptions(
    MapboxZonePolygon polygon,
  ) {
    return PolylineAnnotationOptions(
      geometry: LineString(
        coordinates: polygon.coordinates,
      ),
      lineColor: polygon.strokeColor.toARGB32(),
      lineOpacity: polygon.strokeOpacity,
      lineWidth: polygon.strokeWidth,
    );
  }

  /// Create diagonal stripe lines within a polygon
  static List<PolylineAnnotationOptions> createStripeAnnotationOptions(
    MapboxZonePolygon polygon, {
    double spacingDegrees = 0.008,  // Approximate spacing between lines (~800m)
  }) {
    final stripes = <PolylineAnnotationOptions>[];
    final coords = polygon.coordinates;

    if (coords.length < 3) return stripes;

    // Find bounding box
    double minLng = double.infinity, maxLng = double.negativeInfinity;
    double minLat = double.infinity, maxLat = double.negativeInfinity;

    for (final pos in coords) {
      if (pos.lng < minLng) minLng = pos.lng.toDouble();
      if (pos.lng > maxLng) maxLng = pos.lng.toDouble();
      if (pos.lat < minLat) minLat = pos.lat.toDouble();
      if (pos.lat > maxLat) maxLat = pos.lat.toDouble();
    }

    // Generate diagonal lines (bottom-left to top-right direction)
    // Start from bottom-left corner and move along both edges
    final width = maxLng - minLng;
    final height = maxLat - minLat;
    final diagonal = width + height;

    for (double offset = 0; offset <= diagonal; offset += spacingDegrees) {
      // Line starts from left edge or bottom edge
      double startLng, startLat;
      double endLng, endLat;

      if (offset <= height) {
        // Start from left edge
        startLng = minLng;
        startLat = minLat + offset;
      } else {
        // Start from bottom edge
        startLng = minLng + (offset - height);
        startLat = maxLat;
      }

      if (offset <= width) {
        // End at bottom edge
        endLng = minLng + offset;
        endLat = minLat;
      } else {
        // End at right edge
        endLng = maxLng;
        endLat = minLat + (offset - width);
      }

      // Clip line to polygon and create segments
      final clippedSegments = _clipLineToPolygon(
        Position(startLng, startLat),
        Position(endLng, endLat),
        coords,
      );

      for (final segment in clippedSegments) {
        if (segment.length >= 2) {
          stripes.add(PolylineAnnotationOptions(
            geometry: LineString(coordinates: segment),
            lineColor: polygon.strokeColor.toARGB32(),
            lineOpacity: polygon.fillOpacity * 2.5,  // Slightly more visible than fill
            lineWidth: 1.5,
          ));
        }
      }
    }

    return stripes;
  }

  /// Clip a line to a polygon, returning segments inside the polygon
  static List<List<Position>> _clipLineToPolygon(
    Position start,
    Position end,
    List<Position> polygon,
  ) {
    final segments = <List<Position>>[];
    final intersections = <double>[];
    const epsilon = 1e-9;  // Small epsilon for deduplication

    // Find all intersections with polygon edges
    for (int i = 0; i < polygon.length - 1; i++) {
      final p1 = polygon[i];
      final p2 = polygon[i + 1];

      final t = _lineIntersection(start, end, p1, p2);
      if (t != null && t >= -epsilon && t <= 1 + epsilon) {
        // Clamp to [0, 1] range
        intersections.add(t.clamp(0.0, 1.0));
      }
    }

    // Sort intersections by parameter t
    intersections.sort();

    // Remove duplicate intersections (when line passes through vertex)
    final uniqueIntersections = <double>[];
    for (final t in intersections) {
      if (uniqueIntersections.isEmpty ||
          (t - uniqueIntersections.last).abs() > epsilon) {
        uniqueIntersections.add(t);
      }
    }

    // Check if start point is inside
    bool inside = _isPointInPolygon(start, polygon);
    double lastT = 0;

    for (final t in uniqueIntersections) {
      if (inside) {
        // We were inside, now exiting - create segment
        final segStart = _interpolate(start, end, lastT);
        final segEnd = _interpolate(start, end, t);
        // Only add if segment has meaningful length
        if ((t - lastT).abs() > epsilon) {
          // Safety check: verify midpoint is actually inside polygon
          final midT = (lastT + t) / 2;
          final midPoint = _interpolate(start, end, midT);
          if (_isPointInPolygon(midPoint, polygon)) {
            segments.add([segStart, segEnd]);
          }
        }
      }
      inside = !inside;
      lastT = t;
    }

    // If we end inside the polygon, add final segment
    if (inside && (1.0 - lastT).abs() > epsilon) {
      final segStart = _interpolate(start, end, lastT);
      // Safety check: verify midpoint is actually inside polygon
      final midT = (lastT + 1.0) / 2;
      final midPoint = _interpolate(start, end, midT);
      if (_isPointInPolygon(midPoint, polygon)) {
        segments.add([segStart, end]);
      }
    }

    return segments;
  }

  /// Calculate line-line intersection parameter t for first line
  static double? _lineIntersection(Position a1, Position a2, Position b1, Position b2) {
    final d1x = a2.lng - a1.lng;
    final d1y = a2.lat - a1.lat;
    final d2x = b2.lng - b1.lng;
    final d2y = b2.lat - b1.lat;

    final cross = d1x * d2y - d1y * d2x;
    if (cross.abs() < 1e-10) return null;  // Parallel lines

    final dx = b1.lng - a1.lng;
    final dy = b1.lat - a1.lat;

    final t = (dx * d2y - dy * d2x) / cross;
    final u = (dx * d1y - dy * d1x) / cross;

    if (u >= 0 && u <= 1) {
      return t;
    }
    return null;
  }

  /// Interpolate between two positions
  static Position _interpolate(Position a, Position b, double t) {
    return Position(
      a.lng + (b.lng - a.lng) * t,
      a.lat + (b.lat - a.lat) * t,
    );
  }

  /// Check if a point is inside a polygon using ray casting algorithm
  static int? getZoneIdForPoint(Position point, List<ZoneListModel> zones) {
    for (var zone in zones) {
      if (zone.formattedCoordinates == null || zone.formattedCoordinates!.isEmpty) {
        continue;
      }

      final points = <Position>[];
      for (final coord in zone.formattedCoordinates!) {
        if (coord.lat == null || coord.lng == null) {
          continue;
        }
        points.add(Position(coord.lng!, coord.lat!));
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

  /// Ray casting algorithm to check if point is inside polygon
  static bool _isPointInPolygon(Position point, List<Position> polygon) {
    int intersections = 0;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].lat > point.lat) != (polygon[j].lat > point.lat)) {
        // Calculate the x-coordinate (longitude) where the ray crosses the polygon edge
        double xIntersection = (point.lat - polygon[i].lat) *
            (polygon[j].lng - polygon[i].lng) /
            (polygon[j].lat - polygon[i].lat) + polygon[i].lng;
        if (point.lng < xIntersection) {
          intersections++;
        }
      }
      j = i;
    }

    return intersections % 2 != 0;
  }
}
