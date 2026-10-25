import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:conillet_amagat/app_state.dart';
import 'package:conillet_amagat/data/game_store.dart';
import 'package:conillet_amagat/data/puzzle_repository.dart';
import 'package:conillet_amagat/game/campaign.dart';
import 'package:conillet_amagat/game/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Harness {
  Harness(this.app, this.controller);

  final AppState app;
  final GameController controller;
}

Future<Harness> createHarness({
  String mode = 'level',
  int level = 1,
  int size = 6,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repository = PuzzleRepository.fromJson(
    File('assets/puzzles.json').readAsStringSync(),
  );
  final app = AppState(store: GameStore(prefs), repository: repository);
  final puzzle = repository.levelPuzzle(size, level);
  final controller = GameController(
    puzzle: puzzle,
    app: app,
    mode: mode,
    levelIndex: level,
  );
  return Harness(app, controller);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'toque marca X, otro toque la borra y doble toque esconde un conejo',
    () async {
      final harness = await createHarness();
      final controller = harness.controller;
      addTearDown(controller.dispose);

      final bunnyCell = controller.puzzle.solution.first;
      expect(controller.marks[0], CellMark.none);
      controller.handleTap(0);
      expect(controller.marks[0], CellMark.cross);
      controller.handleTap(0);
      expect(controller.marks[0], CellMark.none);
      expect(controller.handleDoubleTap(bunnyCell), DoubleTapResult.placed);
      expect(controller.marks[bunnyCell], CellMark.bunny);
      expect(controller.handleDoubleTap(bunnyCell), DoubleTapResult.removed);
      expect(controller.marks[bunnyCell], CellMark.none);
      expect(controller.lives, startingLives);
    },
  );

  test(
    'el marcado automático bloquea fila, columna, región y contactos',
    () async {
      final harness = await createHarness();
      final controller = harness.controller;
      addTearDown(controller.dispose);

      final puzzle = controller.puzzle;
      final cell = puzzle.solution.firstWhere((cell) {
        return puzzle.rowOf(cell) + 1 < puzzle.size &&
            puzzle.colOf(cell) + 1 < puzzle.size;
      });
      expect(controller.handleDoubleTap(cell), DoubleTapResult.placed);
      final blocked = controller.blockedCells;
      final row = puzzle.rowOf(cell);
      final col = puzzle.colOf(cell);

      expect(blocked, contains(puzzle.cellAt(row, (col + 1) % puzzle.size)));
      expect(blocked, contains(puzzle.cellAt((row + 1) % puzzle.size, col)));
      expect(
        blocked,
        containsAll(
          puzzle.regionCells[puzzle.regions[cell]].where(
            (other) => other != cell,
          ),
        ),
      );
      expect(blocked, contains(puzzle.cellAt(row + 1, col + 1)));
      expect(blocked, isNot(contains(cell)));
    },
  );

  test('un conejo mal colocado quita una vida y deja una X', () async {
    final harness = await createHarness();
    final controller = harness.controller;
    addTearDown(controller.dispose);

    final wrong = List.generate(
      controller.puzzle.cellCount,
      (index) => index,
    ).firstWhere((cell) => !controller.puzzle.solution.contains(cell));

    expect(controller.handleDoubleTap(wrong), DoubleTapResult.wrong);
    expect(controller.lives, startingLives - 1);
    expect(controller.marks[wrong], CellMark.cross);
    expect(controller.failed, isFalse);

    controller.undo();
    expect(controller.marks[wrong], CellMark.none);
    expect(controller.lives, startingLives - 1);
  });

  test('tres fallos agotan las vidas y bloquean el tablero', () async {
    final harness = await createHarness();
    final controller = harness.controller;
    addTearDown(controller.dispose);

    final wrong = [
      for (var cell = 0; cell < controller.puzzle.cellCount; cell++)
        if (!controller.puzzle.solution.contains(cell)) cell,
    ];

    expect(controller.handleDoubleTap(wrong[0]), DoubleTapResult.wrong);
    expect(controller.handleDoubleTap(wrong[1]), DoubleTapResult.wrong);
    expect(
      controller.handleDoubleTap(wrong[2]),
      DoubleTapResult.outOfLives,
    );
    expect(controller.lives, 0);
    expect(controller.failed, isTrue);
    expect(controller.canPlay, isFalse);
    expect(controller.hint(), isNull);

    controller.handleDoubleTap(wrong[3]);
    expect(controller.marks[wrong[3]], CellMark.none);

    controller.reset();
    expect(controller.lives, startingLives);
    expect(controller.failed, isFalse);
    expect(controller.marks.every((mark) => mark == CellMark.none), isTrue);
  });

  test('los conejos de pista están fijos y no gastan vidas', () async {
    final harness = await createHarness();
    final controller = harness.controller;
    addTearDown(controller.dispose);

    final given = givenCellsFor(controller.puzzle, 2).toList();
    final withGiven = GameController(
      puzzle: controller.puzzle,
      app: harness.app,
      mode: 'campaign',
      levelIndex: 1,
      given: given,
    );
    addTearDown(withGiven.dispose);

    expect(withGiven.givenCells, given.toSet());
    for (final cell in given) {
      expect(withGiven.marks[cell], CellMark.bunny);
    }

    expect(withGiven.handleDoubleTap(given.first), DoubleTapResult.none);
    withGiven.handleTap(given.first);
    withGiven.handleDrag(given.first);
    expect(withGiven.marks[given.first], CellMark.bunny);
    expect(withGiven.lives, startingLives);

    withGiven.handleTap(0);
    withGiven.reset();
    for (final cell in given) {
      expect(withGiven.marks[cell], CellMark.bunny);
    }
    expect(withGiven.lives, startingLives);
  });

  test('la partida guardada conserva los conejos de pista', () async {
    final harness = await createHarness();
    final given = givenCellsFor(harness.controller.puzzle, 2).toList();
    final controller = GameController(
      puzzle: harness.controller.puzzle,
      app: harness.app,
      mode: 'campaign',
      levelIndex: 1,
      given: given,
    );
    harness.controller.dispose();
    controller.pause();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final saved = harness.app.store.readGame();
    expect(saved, isNotNull);
    expect(saved!.given, given);
    expect(saved.mode, 'campaign');

    final restored = GameController(
      puzzle: controller.puzzle,
      app: harness.app,
      mode: 'campaign',
      levelIndex: 1,
      restore: saved,
    );
    expect(restored.givenCells, given.toSet());
    for (final cell in given) {
      expect(restored.marks[cell], CellMark.bunny);
    }
    restored.dispose();
    controller.dispose();
  });

  test('completar una etapa avanza la campaña', () async {
    final harness = await createHarness(mode: 'campaign', level: 7);
    final controller = harness.controller;
    addTearDown(controller.dispose);
    expect(harness.app.campaignStage, 1);

    for (final cell in controller.puzzle.solution) {
      controller.handleDoubleTap(cell);
    }

    expect(controller.finished, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(harness.app.campaignStage, 8);
    expect(harness.app.store.readCampaignStage(), 8);
  });

  test('la pista coloca un conejo de la solución sin gastar vidas', () async {
    final harness = await createHarness();
    final controller = harness.controller;
    addTearDown(controller.dispose);

    final cell = controller.hint();
    expect(cell, isNotNull);
    expect(controller.puzzle.solution, contains(cell));
    expect(controller.marks[cell!], CellMark.bunny);
    expect(controller.hintsUsed, 1);
    expect(controller.lives, startingLives);
  });

  test('resolver el puzle termina la partida y guarda el progreso', () async {
    final harness = await createHarness(level: 3);
    final controller = harness.controller;
    addTearDown(controller.dispose);

    for (final cell in controller.puzzle.solution) {
      controller.handleDoubleTap(cell);
    }

    expect(controller.finished, isTrue);
    expect(controller.conflictCells, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(harness.app.stats.solved, 1);
    expect(harness.app.stats.solvedBySize[6], 1);
    expect(harness.app.completedLevels(6), 3);
    expect(harness.app.savedGame, isNull);
  });

  test('guarda y restaura la partida y las vidas', () async {
    final harness = await createHarness();
    final controller = harness.controller;
    final bunnyCell = controller.puzzle.solution.firstWhere(
      (cell) => cell != 0,
    );
    final wrong = List.generate(
      controller.puzzle.cellCount,
      (index) => index,
    ).firstWhere((cell) => !controller.puzzle.solution.contains(cell));
    controller.handleTap(0);
    controller.handleDoubleTap(bunnyCell);
    controller.handleDoubleTap(wrong);
    controller.pause();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final saved = harness.app.store.readGame();
    expect(saved, isNotNull);
    expect(saved!.marks[0], CellMark.cross.index);
    expect(saved.marks[bunnyCell], CellMark.bunny.index);
    expect(saved.marks[wrong], CellMark.cross.index);
    expect(saved.lives, startingLives - 1);

    final restored = GameController(
      puzzle: controller.puzzle,
      app: harness.app,
      mode: 'level',
      levelIndex: 1,
      restore: saved,
    );
    expect(restored.marks[0], CellMark.cross);
    expect(restored.marks[bunnyCell], CellMark.bunny);
    expect(restored.lives, startingLives - 1);
    expect(restored.failed, isFalse);
    restored.dispose();
    controller.dispose();
  });

  test('reiniciar limpia marcas, pistas y cronómetro', () async {
    final harness = await createHarness();
    final controller = harness.controller;
    addTearDown(controller.dispose);

    final wrong = List.generate(
      controller.puzzle.cellCount,
      (index) => index,
    ).firstWhere((cell) => !controller.puzzle.solution.contains(cell));
    controller.handleTap(0);
    controller.hint();
    controller.handleDoubleTap(wrong);
    expect(controller.lives, startingLives - 1);
    controller.reset();
    expect(controller.marks.every((mark) => mark == CellMark.none), isTrue);
    expect(controller.hintsUsed, 0);
    expect(controller.elapsedSeconds, 0);
    expect(controller.lives, startingLives);
    expect(controller.failed, isFalse);
  });

  test(
    'la racha diaria solo cuenta una vez al día y exige días consecutivos',
    () async {
      final harness = await createHarness();
      final app = harness.app;
      harness.controller.dispose();
      final puzzle = app.repository.levelPuzzle(6, 1);

      awaited(Future<void> Function() action) async => action();

      await awaited(
        () => app.recordCompletion(
          puzzle: puzzle,
          mode: 'daily',
          levelIndex: 20261020,
          hintsUsed: 0,
          seconds: 60,
          now: DateTime(2026, 10, 20),
        ),
      );
      expect(app.stats.dailyStreak, 1);

      await awaited(
        () => app.recordCompletion(
          puzzle: puzzle,
          mode: 'daily',
          levelIndex: 20261020,
          hintsUsed: 0,
          seconds: 60,
          now: DateTime(2026, 10, 20, 20),
        ),
      );
      expect(app.stats.dailyStreak, 1);

      await awaited(
        () => app.recordCompletion(
          puzzle: puzzle,
          mode: 'daily',
          levelIndex: 20261021,
          hintsUsed: 0,
          seconds: 60,
          now: DateTime(2026, 10, 21),
        ),
      );
      expect(app.stats.dailyStreak, 2);

      await awaited(
        () => app.recordCompletion(
          puzzle: puzzle,
          mode: 'daily',
          levelIndex: 20261025,
          hintsUsed: 0,
          seconds: 60,
          now: DateTime(2026, 10, 25),
        ),
      );
      expect(app.stats.dailyStreak, 1);
    },
  );
}
