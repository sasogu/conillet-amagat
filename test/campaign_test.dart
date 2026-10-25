import 'dart:io';

import 'package:conillet_amagat/data/puzzle_repository.dart';
import 'package:conillet_amagat/game/campaign.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = PuzzleRepository.fromJson(
    File('assets/puzzles.json').readAsStringSync(),
  );

  test('la campaña encadena los tamaños de 6×6 a 9×9', () {
    expect(campaignTotalStages(repository), 399);

    final first = campaignStageFor(repository, 1);
    expect(first.size, 6);
    expect(first.level, 1);
    expect(first.endless, isFalse);

    final lastEasy = campaignStageFor(repository, 99);
    expect(lastEasy.size, 6);
    expect(lastEasy.level, 99);

    final firstMedium = campaignStageFor(repository, 100);
    expect(firstMedium.size, 7);
    expect(firstMedium.level, 1);

    expect(campaignStageFor(repository, 199).size, 7);
    expect(campaignStageFor(repository, 199).level, 100);
    expect(campaignStageFor(repository, 200).size, 8);
    expect(campaignStageFor(repository, 300).size, 9);
    expect(campaignStageFor(repository, 399).level, 100);

    final loop = campaignStageFor(repository, 400);
    expect(loop.size, 9);
    expect(loop.level, 1);
    expect(loop.endless, isTrue);
  });

  test('las primeras etapas regalan conejos de pista', () {
    for (final stage in [1, 2, 3]) {
      expect(campaignStageFor(repository, stage).givenBunnies, 2);
    }
    for (final stage in [4, 5, 6]) {
      expect(campaignStageFor(repository, stage).givenBunnies, 1);
    }
    expect(campaignStageFor(repository, 7).givenBunnies, 0);
    expect(campaignStageFor(repository, 100).givenBunnies, 0);
  });

  test('los conejos de pista salen de la solución', () {
    final stage = campaignStageFor(repository, 1);
    final puzzle = repository.levelPuzzle(stage.size, stage.level);
    final cells = givenCellsFor(puzzle, stage.givenBunnies).toList();
    expect(cells, hasLength(2));
    expect(puzzle.solution, containsAll(cells));
  });
}
