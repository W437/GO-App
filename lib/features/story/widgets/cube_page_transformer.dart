import 'dart:math';
import 'package:flutter/material.dart';

/// Instagram-style 3D cube page transformer for story navigation
/// Creates a perspective cube rotation effect when swiping between pages
class CubePageTransformer extends StatelessWidget {
  final Widget child;
  final PageController controller;
  final int pageIndex;

  const CubePageTransformer({
    super.key,
    required this.child,
    required this.controller,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Calculate how far this page is from center
        final page = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : controller.initialPage.toDouble();

        final offset = page - pageIndex;

        // Apply 3D cube rotation
        return Transform(
          alignment: Alignment.center,
          transform: _buildCubeTransform(offset),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Builds the 3D cube transformation matrix
  Matrix4 _buildCubeTransform(double offset) {
    final matrix = Matrix4.identity();

    // Add perspective (0.003 gives a subtle 3D effect)
    matrix.setEntry(3, 2, 0.003);

    // Determine rotation direction and amount
    if (offset.abs() < 1.0) {
      // Page is visible (partially or fully)
      final rotationY = offset * pi / 4; // 45-degree max rotation

      // Apply Y-axis rotation for cube effect
      matrix.rotateY(rotationY);

      // Optional: Add slight scale effect for depth
      final scale = 1.0 - (offset.abs() * 0.1);
      matrix.scale(scale.clamp(0.9, 1.0));
    } else if (offset > 0) {
      // Page is to the right (out of view)
      matrix.rotateY(pi / 4);
      matrix.scale(0.9);
    } else {
      // Page is to the left (out of view)
      matrix.rotateY(-pi / 4);
      matrix.scale(0.9);
    }

    return matrix;
  }
}
