import 'dart:math' as math;

import 'puzzle.dart';

/// Puntuación obtenida al resolver un puzle.
class PuzzleScore {
  const PuzzleScore({
    required this.base,
    required this.timeBonus,
    required this.livesBonus,
    required this.carrots,
  });

  final int base;
  final int timeBonus;
  final int livesBonus;
  final int carrots;

  int get points => base + timeBonus + livesBonus;
}

/// Puntos por tamaño, rapidez y vidas conservadas.
PuzzleScore scoreFor({
  required Puzzle puzzle,
  required int seconds,
  required int lives,
}) {
  final safeSeconds = math.max(0, seconds);
  final safeLives = math.max(0, lives);
  final base = puzzle.size * 100;
  final targetSeconds = puzzle.size * 30;
  final timeBonus = math.max(0, targetSeconds - safeSeconds) * 10;
  final livesBonus = safeLives * 100;
  return PuzzleScore(
    base: base,
    timeBonus: timeBonus,
    livesBonus: livesBonus,
    carrots: safeLives,
  );
}

/// Etapas que avanza la campaña según el rendimiento.
///
/// 1 por resolver; 2 si se resuelve dentro del tiempo objetivo y sin perder
/// vidas; 3 si además no se usan pistas y se baja del 60 % del objetivo.
int stageAdvanceFor({
  required int size,
  required int seconds,
  required int lives,
  required int hintsUsed,
  int maxLives = 3,
}) {
  final target = size * 30;
  var advance = 1;
  if (lives >= maxLives && seconds <= target) advance += 1;
  if (lives >= maxLives && hintsUsed == 0 && seconds <= target * 0.6) {
    advance += 1;
  }
  return advance;
}
