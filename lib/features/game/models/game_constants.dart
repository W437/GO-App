import 'dart:math';
import 'package:flutter/material.dart';

class GameConstants {
  // Physics
  static const double gravity = 0.35;
  static const double jumpForce = -7;
  static const double pipeSpeed = 2;

  // Sizes
  static const double baseBirdSize = 40;
  static const double birdSize = baseBirdSize * 1.2; // ~48
  static const double basePipeWidth = 60;
  static const double pipeWidth = basePipeWidth * 1.15; // ~69
  static const double gapHeight = 150;
  static const double pipeSpacing = 200;
  static const double initialBirdY = 250;
  static const double floorHeight = 100;
  static const double baseScale = 1.2;

  // Settings
  static const double minGapSetting = 140;
  static const double minSpacingSetting = 166;

  // Powerup durations (in frames, 60fps)
  static const int burgerDuration = 7 * 60; // 7 seconds
  static const int pizzaDuration = 8 * 60;  // 8 seconds
  static const int friesDuration = 7 * 60;  // 7 seconds

  // Canvas dimensions will be set dynamically
  static double canvasWidth = 0;
  static double canvasHeight = 0;

  static void updateCanvasSize(Size size) {
    canvasWidth = size.width;
    canvasHeight = size.height * 0.9; // 90% of screen height (header is 10%)
  }

  static double getBirdCollisionRadius() {
    return (birdSize / 2) * 0.87;
  }

  static double getPowerUpCollisionRadius() {
    return (birdSize / 2) * 0.87 * 1.2;
  }

  static double clamp(double value, double min, double max) {
    return value.clamp(min, max);
  }

  static bool circleRectCollision(
    double cx, double cy, double r,
    double rx, double ry, double rw, double rh,
  ) {
    final closestX = clamp(cx, rx, rx + rw);
    final closestY = clamp(cy, ry, ry + rh);
    final dx = cx - closestX;
    final dy = cy - closestY;
    return dx * dx + dy * dy < r * r;
  }
}