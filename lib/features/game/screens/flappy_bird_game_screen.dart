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

class _FlappyBirdGameScreenState extends State<FlappyBirdGameScreen> with TickerProviderStateMixin {
  ui.Image? bgImage;
  ui.Image? baseImage;
  ui.Image? pipeImage;
  List<ui.Image> birdFrames = [];

  late AnimationController _gameOverAnimationController;
  late Animation<double> _gameOverScaleAnimation;
  bool _hasTriggeredGameOverAnimation = false;

  @override
  void initState() {
    super.initState();
    _loadImages();

    _gameOverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _gameOverScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.95).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
    ]).animate(_gameOverAnimationController);
  }

  @override
  void dispose() {
    _gameOverAnimationController.dispose();
    super.dispose();
  }

  void _checkGameOverState(GameController controller) {
    if (controller.gameOver && !_hasTriggeredGameOverAnimation) {
      _hasTriggeredGameOverAnimation = true;
      _gameOverAnimationController.forward(from: 0.0);
    } else if (!controller.gameOver && _hasTriggeredGameOverAnimation) {
      _hasTriggeredGameOverAnimation = false;
      _gameOverAnimationController.reset();
    }
  }

  Future<void> _loadImages() async {
    // Try to load images
    try {
      // Background
      bgImage = await _loadImage('assets/game/assets/background-day.jpg');
    } catch (e) {
      debugPrint('Could not load background: $e');
    }

    try {
      // Base/floor
      baseImage = await _loadImage('assets/game/assets/base.png');
    } catch (e) {
      debugPrint('Could not load base: $e');
    }

    try {
      // Pipe
      pipeImage = await _loadImage('assets/game/assets/pipe-green.png');
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
        final frame = await _loadImage('assets/game/assets/$name');
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
        _checkGameOverState(controller);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: PopScope(
            canPop: true,
            child: Scaffold(
              backgroundColor: const Color(0xFF1a1a2e),
              extendBodyBehindAppBar: true,
              body: Column(
                children: [
                  // Header
                  Container(
                    height: MediaQuery.of(context).size.height * 0.1 + MediaQuery.of(context).padding.top,
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeDefault,
                      MediaQuery.of(context).padding.top,
                      Dimensions.paddingSizeDefault,
                      0,
                    ),
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
                              child: ScaleTransition(
                                scale: _gameOverScaleAnimation,
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              'Score',
                                              style: TextStyle(
                                                fontSize: Dimensions.fontSizeDefault,
                                                color: Theme.of(context).disabledColor,
                                              ),
                                            ),
                                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                            Text(
                                              '${controller.score}',
                                              style: TextStyle(
                                                fontSize: Dimensions.fontSizeOverLarge,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).textTheme.bodyLarge!.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: Dimensions.paddingSizeExtraLarge),
                                        Column(
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.emoji_events,
                                                  color: Colors.amber,
                                                  size: Dimensions.fontSizeDefault,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Best',
                                                  style: TextStyle(
                                                    fontSize: Dimensions.fontSizeDefault,
                                                    color: Theme.of(context).disabledColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                            Text(
                                              '${controller.highScore}',
                                              style: TextStyle(
                                                fontSize: Dimensions.fontSizeOverLarge,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
                                    const SizedBox(height: Dimensions.paddingSizeSmall),
                                    SizedBox(
                                      width: 200,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showLeaderboard(context),
                                        icon: Icon(
                                          Icons.leaderboard,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        label: Text(
                                          'Leaderboard',
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: Dimensions.paddingSizeDefault,
                                          ),
                                          side: BorderSide(
                                            color: Theme.of(context).primaryColor,
                                            width: 2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(Dimensions.radiusDefault),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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

  void _showLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusLarge),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Global Leaderboard',
                    style: TextStyle(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Leaderboard list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                itemCount: 20,
                itemBuilder: (context, index) {
                  // Dummy data
                  final names = [
                    'Alex Chen', 'Maria Garcia', 'James Wilson', 'Sarah Johnson',
                    'Mohammed Ali', 'Emma Brown', 'David Lee', 'Sophia Martinez',
                    'Michael Kim', 'Olivia Taylor', 'Daniel Anderson', 'Isabella White',
                    'Ryan Thomas', 'Ava Jackson', 'Kevin Nguyen', 'Mia Robinson',
                    'Christopher Wright', 'Charlotte Lopez', 'Andrew Clark', 'Amelia Hill'
                  ];
                  final score = 250 - (index * 10) - (index * 2);
                  final isCurrentUser = index == 7; // Mock current user position

                  return Container(
                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Theme.of(context).disabledColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      border: isCurrentUser
                          ? Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Rank
                        SizedBox(
                          width: 40,
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: Dimensions.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: index < 3 ? Colors.amber : Theme.of(context).disabledColor,
                            ),
                          ),
                        ),

                        // Trophy for top 3
                        if (index < 3)
                          Container(
                            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                            child: Icon(
                              Icons.emoji_events,
                              color: index == 0
                                  ? const Color(0xFFFFD700) // Gold
                                  : index == 1
                                      ? const Color(0xFFC0C0C0) // Silver
                                      : const Color(0xFFCD7F32), // Bronze
                              size: 24,
                            ),
                          ),

                        // Name
                        Expanded(
                          child: Text(
                            names[index],
                            style: TextStyle(
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                              color: Theme.of(context).textTheme.bodyLarge!.color,
                            ),
                          ),
                        ),

                        // Score
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: Dimensions.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}