import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/game/models/game_constants.dart';
import 'package:godelivery_user/features/game/models/game_logic.dart';
import 'package:godelivery_user/features/game/models/game_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class GameController extends GetxController with GetSingleTickerProviderStateMixin {
  // Game state
  late GameState gameState;
  late AnimationController animationController;

  // Game status
  bool gameStarted = false;
  bool gameOver = false;
  bool isPaused = false;
  bool awaitTapToContinue = false;
  bool isLoading = true;

  // Scores
  int score = 0;
  int highScore = 0;
  int extraLives = 0;

  // Assets
  bool useFoodEmoji = true;
  String foodEmoji = '🍔';
  final List<String> foodEmojis = [
    '🍔', '🍕', '🍟', '🌭', '🍗', '🥪', '🍣', '🍜',
    '🍩', '🍦', '🍰', '🥗', '🍝', '🍤', '🥟', '🍿'
  ];

  // Audio players
  final AudioPlayer hitSfx = AudioPlayer();
  final AudioPlayer dieSfx = AudioPlayer();
  final AudioPlayer pointSfx = AudioPlayer();
  final AudioPlayer swooshSfx = AudioPlayer();
  final AudioPlayer wingSfx = AudioPlayer();

  // Death state
  bool isDying = false;

  @override
  void onInit() {
    super.onInit();
    _loadHighScore();
    _initializeGame();
    _setupAnimation();
    _loadSounds();
  }

  void _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('flappyHighScore') ?? 0;
    update();
  }

  void _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('flappyHighScore', highScore);
  }

  void _initializeGame() {
    gameState = GameState.initial();
    extraLives = 0;
    awaitTapToContinue = false;

    if (useFoodEmoji) {
      final randIndex = Random().nextInt(foodEmojis.length);
      foodEmoji = foodEmojis[randIndex];
    }

    isLoading = false;
    update();
  }

  void _setupAnimation() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    animationController.addListener(_gameLoop);
  }

  void _loadSounds() async {
    // Try to load sounds, use placeholders if files don't exist
    try {
      await hitSfx.setSource(AssetSource('game/sfx/hit.wav'));
    } catch (e) {
      debugPrint('Could not load hit sound: $e');
    }

    try {
      await dieSfx.setSource(AssetSource('game/sfx/die.wav'));
    } catch (e) {
      debugPrint('Could not load die sound: $e');
    }

    try {
      await pointSfx.setSource(AssetSource('game/sfx/point.wav'));
    } catch (e) {
      debugPrint('Could not load point sound: $e');
    }

    try {
      await swooshSfx.setSource(AssetSource('game/sfx/swoosh.wav'));
    } catch (e) {
      debugPrint('Could not load swoosh sound: $e');
    }

    try {
      await wingSfx.setSource(AssetSource('game/sfx/wing.wav'));
    } catch (e) {
      debugPrint('Could not load wing sound: $e');
    }
  }

  void _gameLoop() {
    if (gameOver || isPaused || awaitTapToContinue) return;

    // Handle dying state - let bird fall to ground
    if (isDying) {
      gameState.bird.velocity += GameConstants.gravity;
      gameState.bird.y += gameState.bird.velocity;

      // Update bird rotation while falling
      final targetRotation = gameState.bird.velocity * 0.02;
      gameState.birdRotation += 0.1 * (targetRotation - gameState.birdRotation);

      final birdRadius = GameConstants.getBirdCollisionRadius();
      final baseY = GameConstants.canvasHeight - GameConstants.floorHeight * GameConstants.baseScale;

      // Check if bird hit ground
      if (gameState.bird.y + birdRadius >= baseY) {
        gameState.bird.y = baseY - birdRadius;
        gameState.bird.velocity = 0;
        _playSound(dieSfx);
        gameOver = true;
        isDying = false;
        animationController.stop();
      }

      update(); // Always update to render the fall
      return;
    }

    // Update game state
    GameLogic.updateFlames(gameState);
    GameLogic.updateScorePopups(gameState);

    // Update scrolling offsets
    final pizzaStack = GameLogic.getPizzaStack(gameState);
    final actualPipeSpeed = GameLogic.computePizzaSpeed(pizzaStack);
    gameState.bgOffset = (gameState.bgOffset + actualPipeSpeed * 0.1) % (400 * 1.5);
    gameState.floorOffset = (gameState.floorOffset + actualPipeSpeed) % 336;

    // Update bird physics
    gameState.bird.velocity += GameConstants.gravity;
    gameState.bird.y += gameState.bird.velocity;

    // Clamp bird position
    if (gameState.bird.y < 20) {
      gameState.bird.y = 20;
      gameState.bird.velocity = 0;
    }

    // Update flap timer
    if (gameState.flapTimer > 0) {
      gameState.flapTimer--;
    }

    // Update bird rotation
    final targetRotation = gameState.flapTimer > 0 ? -0.5 : gameState.bird.velocity * 0.02;
    gameState.birdRotation += 0.1 * (targetRotation - gameState.birdRotation);

    // Check ground collision
    final birdRadius = GameConstants.getBirdCollisionRadius();
    const birdX = 100.0;
    final birdY = gameState.bird.y;
    final baseY = GameConstants.canvasHeight - GameConstants.floorHeight * GameConstants.baseScale;

    if (birdY + birdRadius > baseY) {
      _handleCollision();
      return;
    }

    // Update pipes
    if (gameState.pipes.isEmpty) {
      gameState.pipes.add(GameLogic.createPipe(GameConstants.canvasWidth + 100, gameState));
    }

    for (var pipe in gameState.pipes) {
      pipe.x -= actualPipeSpeed;
    }

    // Add new pipes
    final dynamicSpacing = (GameConstants.pipeSpacing - gameState.score * 2).clamp(
      GameConstants.minSpacingSetting,
      GameConstants.pipeSpacing,
    );

    if (gameState.pipes.isNotEmpty &&
        gameState.pipes.last.x < GameConstants.canvasWidth - dynamicSpacing) {
      gameState.pipes.add(GameLogic.createPipe(GameConstants.canvasWidth + 100, gameState));
    }

    // Remove off-screen pipes
    gameState.pipes.removeWhere((p) => p.x < -GameConstants.pipeWidth);

    // Update powerups
    GameLogic.updatePowerUpsOnField(gameState, actualPipeSpeed, birdX, birdY);

    // Check pipe collisions and scoring
    for (var pipe in gameState.pipes) {
      // Check if passed pipe for scoring
      if (!pipe.passed && pipe.x + GameConstants.pipeWidth / 2 < 100) {
        pipe.passed = true;
        gameState.score += GameLogic.getScoreMultiplier(gameState);
        score = gameState.score;
        _playSound(pointSfx);
        GameLogic.spawnScorePopupIfFries(gameState, gameState.bird.y);

        // Update high score
        if (score > highScore) {
          highScore = score;
          _saveHighScore();
        }
      }

      // Check collision if not invulnerable and not already dying
      if (!GameLogic.isInvulnerable(gameState) && !isDying) {
        // Top pipe collision
        if (GameConstants.circleRectCollision(
          birdX, birdY, birdRadius,
          pipe.x, 0, GameConstants.pipeWidth, pipe.height,
        )) {
          _handleCollision();
          return;
        }

        // Bottom pipe collision
        final bottomPipeY = pipe.height + pipe.gap;
        final bottomPipeHeight = GameConstants.canvasHeight -
            GameConstants.floorHeight * GameConstants.baseScale - bottomPipeY;

        if (GameConstants.circleRectCollision(
          birdX, birdY, birdRadius,
          pipe.x, bottomPipeY, GameConstants.pipeWidth, bottomPipeHeight,
        )) {
          _handleCollision();
          return;
        }
      }
    }

    // Update active powerups
    GameLogic.updateActivePowerUps(gameState);

    // Update animation frame
    gameState.frameCount++;
    if (gameState.frameCount % 5 == 0) {
      gameState.birdFrame = (gameState.birdFrame + 1) % 3;
    }

    update();
  }

  void handleTap() {
    if (!gameStarted && !gameOver) {
      startGame();
    } else if (gameStarted && !gameOver && !isPaused && !isDying) {
      jump();
    }
  }

  void startGame() {
    gameStarted = true;
    gameOver = false;
    isDying = false;
    gameState.bird.y = GameConstants.initialBirdY;
    gameState.bird.velocity = 0;
    _playSound(swooshSfx);
    animationController.repeat();
    update();
  }

  void jump() {
    if (gameOver) return;

    if (awaitTapToContinue) {
      awaitTapToContinue = false;
      animationController.repeat();
      update();
      return;
    }

    gameState.bird.velocity = GameConstants.jumpForce;
    gameState.flapTimer = 32;
    _playSound(wingSfx);
  }

  void togglePause() {
    if (!gameStarted || gameOver || awaitTapToContinue) return;

    isPaused = !isPaused;
    _playSound(swooshSfx);

    if (isPaused) {
      animationController.stop();
    } else {
      animationController.repeat();
    }

    update();
  }

  void resetGame() {
    animationController.stop();
    _initializeGame();
    gameStarted = false;
    gameOver = false;
    isPaused = false;
    isDying = false;
    score = 0;
    gameState = GameState.initial();
    update();
  }

  void _handleCollision() {
    if (isDying) return; // Already dying

    _playSound(hitSfx);
    isDying = true;
    // Don't stop animation yet - let bird fall
    update();
  }

  void _handleGameOver() {
    gameOver = true;
    animationController.stop();
    _playSound(hitSfx);
    update();
  }

  void _playSound(AudioPlayer player) async {
    try {
      await player.stop();
      await player.resume();
    } catch (e) {
      // Ignore sound errors
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    hitSfx.dispose();
    dieSfx.dispose();
    pointSfx.dispose();
    swooshSfx.dispose();
    wingSfx.dispose();
    super.onClose();
  }
}