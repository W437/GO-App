class Bird {
  double y;
  double velocity;

  Bird({required this.y, required this.velocity});
}

class Pipe {
  double x;
  double height;
  double gap;
  bool passed;

  Pipe({
    required this.x,
    required this.height,
    required this.gap,
    this.passed = false,
  });
}

enum PowerUpType { burger, pizza, fries }

class PowerUp {
  double x;
  double y;
  PowerUpType type;

  PowerUp({
    required this.x,
    required this.y,
    required this.type,
  });
}

class ActivePowerUp {
  PowerUpType type;
  int timer;
  int duration;
  bool flashing;
  int? stack;

  ActivePowerUp({
    required this.type,
    required this.timer,
    required this.duration,
    this.flashing = false,
    this.stack,
  });
}

class ScorePopup {
  double x;
  double y;
  String text;
  int life;

  ScorePopup({
    required this.x,
    required this.y,
    required this.text,
    required this.life,
  });
}

class Flame {
  double x;
  double y;
  int life;
  double vx;
  double vy;
  double? size;
  double? rotation;
  double? rotationSpeed;

  Flame({
    required this.x,
    required this.y,
    required this.life,
    required this.vx,
    required this.vy,
    this.size,
    this.rotation,
    this.rotationSpeed,
  });
}

class GameState {
  int score;
  Bird bird;
  List<Pipe> pipes;
  List<PowerUp> powerUps;
  Map<PowerUpType, ActivePowerUp> activePowerUps;
  List<Flame> flames;
  List<ScorePopup> scorePopups;
  double floorOffset;
  double bgOffset;
  int flapTimer;
  double birdRotation;
  int frameCount;
  int birdFrame;

  GameState({
    required this.score,
    required this.bird,
    required this.pipes,
    required this.powerUps,
    required this.activePowerUps,
    required this.flames,
    required this.scorePopups,
    required this.floorOffset,
    required this.bgOffset,
    required this.flapTimer,
    required this.birdRotation,
    required this.frameCount,
    required this.birdFrame,
  });

  factory GameState.initial() {
    return GameState(
      score: 0,
      bird: Bird(y: 250, velocity: 0),
      pipes: [],
      powerUps: [],
      activePowerUps: {},
      flames: [],
      scorePopups: [],
      floorOffset: 0,
      bgOffset: 0,
      flapTimer: 0,
      birdRotation: 0,
      frameCount: 0,
      birdFrame: 0,
    );
  }
}