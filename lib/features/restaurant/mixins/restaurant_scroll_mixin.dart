import 'package:flutter/material.dart';

/// Mixin for detecting active section/category based on scroll position.
/// Used by RestaurantScreen to sync sticky header with scroll position.
mixin RestaurantScrollMixin<T extends StatefulWidget> on State<T> {
  // Layout constants
  static const double categoryBarHeight = 50.0;
  static const double expandedHeight = 210.0;
  static const double logoSize = 120.0;
  static const double logoCenterOffset = 5.0;

  /// Map of section/category IDs to their GlobalKeys for scroll detection
  Map<int, GlobalKey> get categorySectionKeys;

  /// Detect which section is currently centered in viewport (new API)
  /// Returns the section ID that should be active, or null if none found.
  int? detectActiveSectionOnScroll(double viewportHeight, double viewportCenter) {
    int? bestSectionId;
    double bestDistance = double.infinity;

    for (final entry in categorySectionKeys.entries) {
      final key = entry.value;
      final ctx = key.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final position = box.localToGlobal(Offset.zero);
          final sectionTop = position.dy;
          final sectionCenter = sectionTop + (box.size.height / 2);

          // Check distance from section center to viewport center
          final distance = (sectionCenter - viewportCenter).abs();

          // Section should be visible on screen
          if (sectionTop < viewportHeight && sectionTop > -box.size.height) {
            if (distance < bestDistance) {
              bestDistance = distance;
              bestSectionId = entry.key;
            }
          }
        }
      }
    }

    return bestSectionId;
  }
}
