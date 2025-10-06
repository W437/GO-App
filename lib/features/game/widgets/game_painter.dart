import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:godelivery_user/features/game/models/game_constants.dart';
import 'package:godelivery_user/features/game/models/game_models.dart';

class GamePainter extends CustomPainter {
  final GameState gameState;
  final ui.Image? bgImage;
  final ui.Image? baseImage;
  final ui.Image? pipeImage;
  final List<ui.Image>? birdFrames;
  final bool useFoodEmoji;
  final String foodEmoji;
  final int score;
  final int highScore;
  final int extraLives;
  final bool awaitTapToContinue;

  GamePainter({
    required this.gameState,
    this.bgImage,
    this.baseImage,
    this.pipeImage,
    this.birdFrames,
    this.useFoodEmoji = true,
    this.foodEmoji = '🍔',
    this.score = 0,
    this.highScore = 0,
    this.extraLives = 0,
    this.awaitTapToContinue = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameConstants.updateCanvasSize(size);

    // Draw blue gradient background
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF87CEEB), // Sky blue
        const Color(0xFF4A90E2), // Deeper blue
      ],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Draw pipes
    _drawPipes(canvas, size);

    // Draw base/floor
    if (baseImage != null) {
      _drawBase(canvas, size);
    }

    // Draw powerups
    _drawPowerUps(canvas);

    // Draw flames
    _drawFlames(canvas);

    // Draw score popups
    _drawScorePopups(canvas);

    // Draw bird
    _drawBird(canvas);

    // Draw UI elements
    _drawScore(canvas, size);
    _drawExtraLives(canvas, size);
    _drawActivePowerUps(canvas, size);

    // Draw overlays
    if (awaitTapToContinue) {
      _drawExtraLifeOverlay(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    if (bgImage == null) return;

    final scale = 0.6;
    final bgWidth = bgImage!.width * scale;
    final bgHeight = bgImage!.height * scale;

    // Draw with parallax effect
    canvas.save();
    canvas.translate(-gameState.bgOffset, 0);

    final repetitions = (size.width / bgWidth).ceil() + 1;
    for (int i = 0; i < repetitions; i++) {
      canvas.drawImageRect(
        bgImage!,
        Rect.fromLTWH(0, 0, bgImage!.width.toDouble(), bgImage!.height.toDouble()),
        Rect.fromLTWH(i * bgWidth, 0, bgWidth, bgHeight),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    canvas.restore();
  }

  void _drawPipes(Canvas canvas, Size size) {
    final pipePaint = Paint()..color = Colors.green;

    for (var pipe in gameState.pipes) {
      if (pipeImage != null) {
        // Calculate pipe aspect ratio
        final pipeAspectRatio = pipeImage!.width / pipeImage!.height;
        final pipeDisplayHeight = GameConstants.pipeWidth / pipeAspectRatio;

        // Draw top pipe (flipped and repeated to fill height)
        canvas.save();
        canvas.translate(pipe.x, pipe.height);
        canvas.scale(1, -1);

        // Repeat pipe texture to fill the top pipe height (from bottom to top)
        double currentY = 0;
        while (currentY < pipe.height) {
          final segmentHeight = min(pipeDisplayHeight, pipe.height - currentY);
          final srcHeight = (segmentHeight / pipeDisplayHeight) * pipeImage!.height;

          canvas.drawImageRect(
            pipeImage!,
            Rect.fromLTWH(0, 0, pipeImage!.width.toDouble(), srcHeight),
            Rect.fromLTWH(0, currentY, GameConstants.pipeWidth, segmentHeight),
            Paint(),
          );

          currentY += pipeDisplayHeight;
        }
        canvas.restore();

        // Draw bottom pipe (repeated to fill height)
        final bottomY = pipe.height + pipe.gap;
        final floorY = size.height - GameConstants.floorHeight * GameConstants.baseScale;
        final bottomHeight = floorY - bottomY;

        canvas.save();
        canvas.translate(pipe.x, bottomY);

        // Repeat pipe texture to fill the bottom pipe height
        double bottomCurrentY = 0;
        while (bottomCurrentY < bottomHeight) {
          final segmentHeight = min(pipeDisplayHeight, bottomHeight - bottomCurrentY);
          final srcHeight = (segmentHeight / pipeDisplayHeight) * pipeImage!.height;

          canvas.drawImageRect(
            pipeImage!,
            Rect.fromLTWH(0, 0, pipeImage!.width.toDouble(), srcHeight),
            Rect.fromLTWH(0, bottomCurrentY, GameConstants.pipeWidth, segmentHeight),
            Paint(),
          );

          bottomCurrentY += pipeDisplayHeight;
        }
        canvas.restore();
      } else {
        // Fallback to colored rectangles
        final topRect = Rect.fromLTWH(pipe.x, 0, GameConstants.pipeWidth, pipe.height);
        canvas.drawRect(topRect, pipePaint);

        final bottomY = pipe.height + pipe.gap;
        final floorY = size.height - GameConstants.floorHeight * GameConstants.baseScale;
        final bottomHeight = floorY - bottomY;
        final bottomRect = Rect.fromLTWH(pipe.x, bottomY, GameConstants.pipeWidth, bottomHeight);
        canvas.drawRect(bottomRect, pipePaint);
      }
    }
  }

  void _drawBase(Canvas canvas, Size size) {
    final baseHeight = GameConstants.floorHeight * GameConstants.baseScale;
    final baseY = size.height - baseHeight;

    if (baseImage == null) {
      // Draw placeholder floor
      final floorRect = Rect.fromLTWH(0, baseY, size.width, baseHeight);
      canvas.drawRect(floorRect, Paint()..color = const Color(0xFFDED895));
      return;
    }

    final baseTileWidth = baseImage!.width * GameConstants.baseScale;

    for (double x = -gameState.floorOffset; x < size.width; x += baseTileWidth) {
      canvas.drawImageRect(
        baseImage!,
        Rect.fromLTWH(0, 0, baseImage!.width.toDouble(), baseImage!.height.toDouble()),
        Rect.fromLTWH(x, baseY, baseTileWidth, baseHeight),
        Paint(),
      );
    }
  }

  void _drawPowerUps(Canvas canvas) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var powerUp in gameState.powerUps) {
      String emoji = '❓';
      double offsetY = 0;
      double rotation = 0;

      switch (powerUp.type) {
        case PowerUpType.burger:
          emoji = '🍔';
          offsetY = sin(gameState.frameCount * 0.08) * 6;
          break;
        case PowerUpType.pizza:
          emoji = '🍕';
          rotation = (gameState.frameCount * 0.3) % (pi * 2);
          break;
        case PowerUpType.fries:
          emoji = '🍟';
          offsetY = sin(gameState.frameCount * 0.1) * 4;
          break;
      }

      canvas.save();
      canvas.translate(powerUp.x, powerUp.y + offsetY);
      canvas.rotate(rotation);

      textPainter.text = TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 40),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }
  }

  void _drawFlames(Canvas canvas) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var flame in gameState.flames) {
      canvas.save();
      canvas.translate(flame.x, flame.y);
      if (flame.rotation != null) {
        canvas.rotate(flame.rotation!);
      }

      final opacity = flame.life / 42.0;
      textPainter.text = TextSpan(
        text: '🔥',
        style: TextStyle(
          fontSize: 24 * (flame.size ?? 1),
          color: Colors.white.withOpacity(opacity),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }
  }

  void _drawScorePopups(Canvas canvas) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var popup in gameState.scorePopups) {
      final opacity = (popup.life / 30.0).clamp(0.0, 1.0);

      textPainter.text = TextSpan(
        text: popup.text,
        style: TextStyle(
          fontSize: 24,
          color: Colors.yellow.withOpacity(opacity),
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(popup.x - textPainter.width / 2, popup.y - textPainter.height / 2),
      );
    }
  }

  void _drawBird(Canvas canvas) {
    canvas.save();
    canvas.translate(100, gameState.bird.y);
    canvas.rotate(gameState.birdRotation);

    // DEBUG: Draw collision circle
    final collisionRadius = GameConstants.getBirdCollisionRadius();
    final debugPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, collisionRadius, debugPaint);

    // Draw burger shield if active
    if (gameState.activePowerUps.containsKey(PowerUpType.burger)) {
      final burger = gameState.activePowerUps[PowerUpType.burger]!;
      double shieldAlpha = 0.4;
      if (burger.flashing) {
        shieldAlpha = 0.4 + 0.3 * ((1 + sin(gameState.frameCount * 0.5)) / 2);
      }

      final shieldPaint = Paint()
        ..color = Colors.cyan.withOpacity(shieldAlpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset.zero,
        GameConstants.birdSize / 2 + 10,
        shieldPaint,
      );
    }

    if (useFoodEmoji) {
      // Draw food emoji as bird
      final textPainter = TextPainter(
        text: TextSpan(
          text: foodEmoji,
          style: TextStyle(fontSize: GameConstants.birdSize),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
    } else if (birdFrames != null && birdFrames!.isNotEmpty) {
      // Draw bird sprite
      final frame = birdFrames![gameState.birdFrame % birdFrames!.length];
      final birdScale = GameConstants.birdSize / frame.width;
      final birdHeight = frame.height * birdScale;

      canvas.drawImageRect(
        frame,
        Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
        Rect.fromLTWH(
          -GameConstants.birdSize / 2,
          -birdHeight / 2,
          GameConstants.birdSize,
          birdHeight,
        ),
        Paint(),
      );
    } else {
      // Draw placeholder circle
      canvas.drawCircle(
        Offset.zero,
        GameConstants.birdSize / 2,
        Paint()..color = Colors.yellow,
      );
    }

    canvas.restore();
  }

  void _drawScore(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw score with outline
    final scoreText = score.toString();
    final textStyle = const TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    // Draw outline
    for (double x = -2; x <= 2; x++) {
      for (double y = -2; y <= 2; y++) {
        if (x != 0 || y != 0) {
          textPainter.text = TextSpan(
            text: scoreText,
            style: textStyle.copyWith(color: Colors.black),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(size.width / 2 - textPainter.width / 2 + x, 50 + y),
          );
        }
      }
    }

    // Draw main text
    textPainter.text = TextSpan(text: scoreText, style: textStyle);
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, 50),
    );
  }

  void _drawExtraLives(Canvas canvas, Size size) {
    if (extraLives <= 0) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '❤️' * extraLives,
        style: const TextStyle(fontSize: 32),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 + 60, 50));
  }

  void _drawActivePowerUps(Canvas canvas, Size size) {
    const barWidth = 150.0;
    const barHeight = 20.0;
    int index = 0;

    gameState.activePowerUps.forEach((type, powerUp) {
      final x = size.width / 2 - barWidth / 2;
      final y = 110.0 + index * (barHeight + 8);

      // Draw background
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(10),
      );
      canvas.drawRRect(bgRect, Paint()..color = Colors.white.withOpacity(0.3));

      // Draw progress
      final progress = powerUp.timer / powerUp.duration;
      Color barColor = Colors.lime;
      if (type == PowerUpType.pizza) barColor = Colors.orange;
      if (type == PowerUpType.fries) barColor = Colors.amber;
      if (powerUp.flashing && gameState.frameCount % 10 < 5) {
        barColor = Colors.yellow;
      }

      canvas.save();
      canvas.clipRRect(bgRect);
      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth * progress, barHeight),
        Paint()..color = barColor,
      );
      canvas.restore();

      // Draw label
      String label = '';
      if (type == PowerUpType.burger) {
        label = 'Shield';
      } else if (type == PowerUpType.pizza) {
        final stack = powerUp.stack ?? 1;
        label = 'Speed ${stack * 2}x';
      } else if (type == PowerUpType.fries) {
        final stack = powerUp.stack ?? 1;
        label = 'Score ${stack * 2}x';
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, y + 3),
      );

      index++;
    });
  }

  void _drawExtraLifeOverlay(Canvas canvas, Size size) {
    // Draw semi-transparent overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // Draw text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(
      text: 'You get another life!\nTap to keep playing!',
      style: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}