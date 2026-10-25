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
