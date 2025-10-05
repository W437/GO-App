import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/game/controllers/game_controller.dart';
import 'package:godelivery_user/features/game/widgets/game_painter.dart';
import 'package:godelivery_user/util/dimensions.dart';

class FlappyBirdGameScreen extends StatefulWidget {
  const FlappyBirdGameScreen({super.key});

  @override
  State<FlappyBirdGameScreen> createState() => _FlappyBirdGameScreenState();
}

class _FlappyBirdGameScreenState extends State<FlappyBirdGameScreen> {
  ui.Image? bgImage;
  ui.Image? baseImage;
  ui.Image? pipeImage;
  List<ui.Image> birdFrames = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    // Try to load images
    try {
      // Background
      bgImage = await _loadImage('assets/game/bg/background-day.jpg');
    } catch (e) {
      debugPrint('Could not load background: $e');
    }

    try {
      // Base/floor
      baseImage = await _loadImage('assets/game/bg/base.png');
    } catch (e) {
      debugPrint('Could not load base: $e');
    }

    try {
      // Pipe
      pipeImage = await _loadImage('assets/game/pipe/pipe-green.png');
    } catch (e) {
      debugPrint('Could not load pipe: $e');
    }

    // Bird frames
    final frameNames = [
      'yellowbird-downflap.png',
      'yellowbird-midflap.png',
      'yellowbird-upflap.png'
    ];

    for (var name in frameNames) {
      try {
        final frame = await _loadImage('assets/game/char/$name');
        birdFrames.add(frame);
      } catch (e) {
        debugPrint('Could not load bird frame $name: $e');
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<ui.Image> _loadImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GameController>(
      init: GameController(),
      builder: (controller) {
        return PopScope(
          canPop: true,
          child: Scaffold(
            backgroundColor: const Color(0xFF1a1a2e),
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    height: MediaQuery.of(context).size.height * 0.1,
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back/Pause button
                        IconButton(
                          onPressed: () {
                            if (controller.gameStarted &&
                                !controller.gameOver &&
                                !controller.awaitTapToContinue) {
                              controller.togglePause();
                            } else {
                              Get.back();
                            }
                          },
                          icon: Icon(
                            controller.gameStarted &&
                                    !controller.gameOver &&
                                    !controller.awaitTapToContinue
                                ? Icons.pause
                                : Icons.arrow_back,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                          ),
                        ),

                        // Title
                        Text(
                          'GO! BIRD',
                          style: TextStyle(
                            fontSize: Dimensions.fontSizeExtraLarge,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),

                        // High score
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: Dimensions.fontSizeExtraLarge,
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Text(
                              controller.highScore.toString(),
                              style: TextStyle(
                                fontSize: Dimensions.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge!.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Game Area
                  Expanded(
                    child: Stack(
                      children: [
                        // Game Canvas
                        GestureDetector(
                          onTapDown: (_) => controller.handleTap(),
                          child: Container(
                            color: const Color(0xFF70C5CE),
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: GamePainter(
                                gameState: controller.gameState,
                                bgImage: bgImage,
                                baseImage: baseImage,
                                pipeImage: pipeImage,
                                birdFrames: birdFrames,
                                useFoodEmoji: controller.useFoodEmoji,
                                foodEmoji: controller.foodEmoji,
                                score: controller.score,
                                highScore: controller.highScore,
                                extraLives: controller.extraLives,
                                awaitTapToContinue: controller.awaitTapToContinue,
                              ),
                            ),
                          ),
                        ),

                        // Pause Menu Overlay
                        if (controller.isPaused)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Game Paused',
                                      style: TextStyle(
                                        fontSize: Dimensions.fontSizeOverLarge,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge!.color,
                                      ),
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeLarge),
                                    SizedBox(
                                      width: 200,
                                      child: ElevatedButton(
                                        onPressed: controller.togglePause,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: Dimensions.paddingSizeDefault,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(Dimensions.radiusDefault),
                                          ),
                                        ),
                                        child: const Text(
                                          'Resume Game',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeSmall),
                                    SizedBox(
                                      width: 200,
                                      child: TextButton(
                                        onPressed: () => Get.back(),
                                        child: Text(
                                          'Back to Menu',
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Start Screen Overlay
                        if (!controller.gameStarted && !controller.gameOver && !controller.isLoading)
                          GestureDetector(
                            onTap: controller.handleTap,
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // GO logo placeholder
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'GO!',
                                          style: TextStyle(
                                            fontSize: Dimensions.fontSizeOverLarge * 1.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeLarge),
                                    Text(
                                      'Tap to Play!',
                                      style: TextStyle(
                                        fontSize: Dimensions.fontSizeExtraLarge,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Loading Overlay
                        if (controller.isLoading)
                          Container(
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),

                        // Game Over Overlay
                        if (controller.gameOver)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                                margin: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Game Over!',
                                      style: TextStyle(
                                        fontSize: Dimensions.fontSizeOverLarge * 1.5,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge!.color,
                                      ),
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                    Text(
                                      'Score: ${controller.score}',
                                      style: TextStyle(
                                        fontSize: Dimensions.fontSizeExtraLarge,
                                        color: Theme.of(context).textTheme.bodyLarge!.color,
                                      ),
                                    ),
                                    if (controller.score == controller.highScore && controller.score > 0) ...[
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      Text(
                                        'New High Score! 🏆',
                                        style: TextStyle(
                                          fontSize: Dimensions.fontSizeLarge,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: Dimensions.paddingSizeLarge),
                                    SizedBox(
                                      width: 200,
                                      child: ElevatedButton(
                                        onPressed: controller.resetGame,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: Dimensions.paddingSizeDefault,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(Dimensions.radiusDefault),
                                          ),
                                        ),
                                        child: const Text(
                                          'Play Again',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
      },
    );
  }
}