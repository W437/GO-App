import 'dart:math';
import 'package:godelivery_user/features/game/models/game_constants.dart';
import 'package:godelivery_user/features/game/models/game_models.dart';

class GameLogic {
  static final Random _random = Random();

  static Pipe createPipe(double x, GameState state) {
    final dynamicGap = GameConstants.minGapSetting.clamp(
      GameConstants.minGapSetting,
      GameConstants.gapHeight - state.score * 2,
    );

    final availableHeight = GameConstants.canvasHeight -
        GameConstants.floorHeight * GameConstants.baseScale - dynamicGap;
    const minPipeHeight = 80.0;
    final maxPipeHeight = (availableHeight - 80).clamp(80, double.infinity);

    var pipeHeight = _random.nextDouble() * (maxPipeHeight - minPipeHeight) + minPipeHeight;
    pipeHeight = pipeHeight.clamp(80, double.infinity);

    // 65% chance for a powerup
    if (_random.nextDouble() < 0.65) {
      final powerUpX = x - (GameConstants.pipeSpacing / 2);
      final powerUpY = _random.nextDouble() * (dynamicGap - 80) + (pipeHeight + 40);

      final r = _random.nextDouble();
      PowerUpType type;
      if (r < 0.444) {
        type = PowerUpType.fries;
      } else if (r < 0.722) {
        type = PowerUpType.pizza;
      } else {
        type = PowerUpType.burger;
      }

      state.powerUps.add(PowerUp(x: powerUpX, y: powerUpY, type: type));
    }

    return Pipe(x: x, height: pipeHeight, gap: dynamicGap, passed: false);
  }

  static double computePizzaSpeed(int stack) {
    if (stack <= 0) return 2;
    if (stack == 1) return 4;
    if (stack == 2) return 6;
    return 8;
  }

  static int getPizzaStack(GameState state) {
    return state.activePowerUps[PowerUpType.pizza]?.stack ?? 0;
  }

  static int getPizzaMultiplier(GameState state) {
    final stack = getPizzaStack(state);
    if (stack <= 0) return 1;
    return (stack * 2).clamp(1, 6);
  }

  static int getFriesStack(GameState state) {
    return state.activePowerUps[PowerUpType.fries]?.stack ?? 0;
  }

  static int getFriesMultiplier(GameState state) {
    final stack = getFriesStack(state);
    if (stack <= 0) return 1;
    return (stack * 2).clamp(1, 6);
  }

  static double getPipeSpeed(GameState state) {
    return computePizzaSpeed(getPizzaStack(state));
  }

  static int getScoreMultiplier(GameState state) {
    final multi = getFriesMultiplier(state);
    return multi <= 1 ? 1 : multi;
  }

  static bool isInvulnerable(GameState state) {
    return state.activePowerUps.containsKey(PowerUpType.burger) ||
           state.activePowerUps.containsKey(PowerUpType.pizza);
  }

  static void spawnScorePopupIfFries(GameState state, double birdY) {
    final fm = getFriesMultiplier(state);
    if (fm > 1) {
      state.scorePopups.add(ScorePopup(
        x: 100,
        y: birdY - 20,
        text: '${fm}x!',
        life: 60,
      ));
    }
  }

  static void spawnFlame(GameState state, double birdY, int pizzaMultiplier) {
    if (pizzaMultiplier < 2) return;

    final count = pizzaMultiplier ~/ 2;
    for (int i = 0; i < count; i++) {
      final size = _random.nextDouble() * 0.6 + 0.7;
      final offsetX = 20 + _random.nextDouble() * 10;
      final offsetY = (_random.nextDouble() - 0.5) * 10;
      final flameVX = -(5 + _random.nextDouble() * 3);
      final flameVY = _random.nextDouble() * 4 - 2;
      final rotation = _random.nextDouble() * pi * 1.1;
      final rotationSpeed = _random.nextDouble() * 0.2 - 0.1;

      state.flames.add(Flame(
        x: 100 - offsetX,
        y: birdY + offsetY,
        life: 42,
        vx: flameVX,
        vy: flameVY,
        size: size,
        rotation: rotation,
        rotationSpeed: rotationSpeed,
      ));
    }
  }

  static void updateFlames(GameState state) {
    final pizzaMultiplier = getPizzaMultiplier(state);
    if (pizzaMultiplier >= 2) {
      spawnFlame(state, state.bird.y, pizzaMultiplier);
    }

    for (var flame in state.flames) {
      flame.x += flame.vx;
      flame.y += flame.vy;
      if (flame.rotationSpeed != null && flame.rotation != null) {
        flame.rotation = flame.rotation! + flame.rotationSpeed!;
      }
      flame.life--;
    }

    state.flames.removeWhere((f) => f.life <= 0);
  }

  static void updateScorePopups(GameState state) {
    for (var popup in state.scorePopups) {
      popup.y -= 0.5;
      popup.life--;
    }
    state.scorePopups.removeWhere((s) => s.life <= 0);
  }

  static void updateActivePowerUps(GameState state) {
    final keysToRemove = <PowerUpType>[];

    state.activePowerUps.forEach((key, powerUp) {
      powerUp.timer--;
      if (!powerUp.flashing && powerUp.timer <= 60) {
        powerUp.flashing = true;
      }
      if (powerUp.timer <= 0) {
        keysToRemove.add(key);
      }
    });

    for (var key in keysToRemove) {
      state.activePowerUps.remove(key);
    }
  }

  static void activatePowerUp(GameState state, PowerUpType type, [int? customDuration]) {
    int duration = 0;
    switch (type) {
      case PowerUpType.burger:
        duration = GameConstants.burgerDuration;
        break;
      case PowerUpType.pizza:
        duration = GameConstants.pizzaDuration;
        break;
      case PowerUpType.fries:
        duration = GameConstants.friesDuration;
        break;
    }

    if (customDuration != null) {
      duration = customDuration;
    }

    final existing = state.activePowerUps[type];
    if (existing != null) {
      existing.timer = duration;
      existing.duration = duration;
      existing.flashing = false;
      if (type == PowerUpType.pizza || type == PowerUpType.fries) {
        existing.stack = (existing.stack ?? 1).clamp(1, 3) + 1;
      }
    } else {
      final powerUp = ActivePowerUp(
        type: type,
        timer: duration,
        duration: duration,
        flashing: false,
      );
      if (type == PowerUpType.pizza || type == PowerUpType.fries) {
        powerUp.stack = 1;
      }
      state.activePowerUps[type] = powerUp;
    }
  }

  static int updatePowerUpsOnField(
    GameState state,
    double currentPipeSpeed,
    double birdX,
    double birdY,
  ) {
    // Move powerups
    for (var powerUp in state.powerUps) {
      powerUp.x -= currentPipeSpeed;
    }

    // Check collisions
    final collisionRadius = GameConstants.getPowerUpCollisionRadius();
    state.powerUps.removeWhere((powerUp) {
      if (powerUp.x < -50) return true;

      final dx = birdX - powerUp.x;
      final dy = birdY - powerUp.y;
      if (dx * dx + dy * dy < collisionRadius * collisionRadius) {
        activatePowerUp(state, powerUp.type);
        return true;
      }
      return false;
    });

    return 0; // Extra lives gained (not implemented in original)
  }
}