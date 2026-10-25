import 'dart:io';

import 'package:conillet_amagat/data/puzzle_repository.dart';
import 'package:conillet_amagat/game/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = PuzzleRepository.fromJson(
    File('assets/puzzles.json').readAsStringSync(),
  );
  final puzzle = repository.levelPuzzle(6, 1);

  test('la base depende del tamaño del puzle', () {
    expect(scoreFor(puzzle: puzzle, seconds: 0, lives: 0).base, 600);
    expect(
      scoreFor(
        puzzle: repository.levelPuzzle(9, 1),
        seconds: 0,
        lives: 0,
      ).base,
      900,
    );
  });

  test('resolver más rápido da más puntos', () {
    final fast = scoreFor(puzzle: puzzle, seconds: 40, lives: 3);
    final slow = scoreFor(puzzle: puzzle, seconds: 200, lives: 3);
    expect(fast.timeBonus, greaterThan(slow.timeBonus));
    expect(fast.points, greaterThan(slow.points));
    expect(slow.timeBonus, 0);
  });

  test('las vidas no consumidas dan puntos y zanahorias', () {
    final three = scoreFor(puzzle: puzzle, seconds: 90, lives: 3);
    final one = scoreFor(puzzle: puzzle, seconds: 90, lives: 1);
    expect(three.carrots, 3);
    expect(one.carrots, 1);
    expect(three.livesBonus, 300);
    expect(one.livesBonus, 100);
    expect(three.points, greaterThan(one.points));
  });

  test('sin vidas no hay zanahorias', () {
    final score = scoreFor(puzzle: puzzle, seconds: 90, lives: 0);
    expect(score.carrots, 0);
    expect(score.livesBonus, 0);
    expect(score.points, score.base + score.timeBonus);
  });
}
