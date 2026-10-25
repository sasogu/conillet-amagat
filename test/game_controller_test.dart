import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ronron/app_state.dart';
import 'package:ronron/data/game_store.dart';
import 'package:ronron/data/puzzle_repository.dart';
import 'package:ronron/game/game_controller.dart';
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
    'toque marca X, otro toque la borra y doble toque pone un gato',
    () async {
      final harness = await createHarness();
      final controller = harness.controller;
      addTearDown(controller.dispose);

      expect(controller.marks[0], CellMark.none);
      controller.handleTap(0);
      expect(controller.marks[0], CellMark.cross);
      controller.handleTap(0);
      expect(controller.marks[0], CellMark.none);
      controller.handleDoubleTap(0);
      expect(controller.marks[0], CellMark.cat);
      controller.handleDoubleTap(0);
      expect(controller.marks[0], CellMark.none);
    },
  );

  test(
    'el marcado automático bloquea fila, columna, región y contactos',
    () async {
      final harness = await createHarness();
      final controller = harness.controller;
      addTearDown(controller.dispose);

      final cell = 2;
      controller.handleDoubleTap(cell);
      final blocked = controller.blockedCells;
      final puzzle = controller.puzzle;
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

  test('detecta gatos que comparten fila y deshace movimientos', () async {
    final harness = await createHarness();
    final controller = harness.controller;
    addTearDown(controller.dispose);

    controller.handleDoubleTap(0);
    controller.handleDoubleTap(1);
    expect(controller.conflictCells, containsAll({0, 1}));

    controller.undo();
    expect(controller.marks[1], CellMark.none);
    expect(controller.conflictCells, isEmpty);
  });

  test('la pista coloca un gato de la solución', () async {
    final harness = await createHarness();
    final controller = harness.controller;
    addTearDown(controller.dispose);

    final cell = controller.hint();
    expect(cell, isNotNull);
    expect(controller.puzzle.solution, contains(cell));
    expect(controller.marks[cell!], CellMark.cat);
    expect(controller.hintsUsed, 1);
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

  test('guarda y restaura la partida', () async {
    final harness = await createHarness();
    final controller = harness.controller;
    controller.handleTap(0);
    controller.handleDoubleTap(1);
    controller.pause();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final saved = harness.app.store.readGame();
    expect(saved, isNotNull);
    expect(saved!.marks[0], CellMark.cross.index);
    expect(saved.marks[1], CellMark.cat.index);

    final restored = GameController(
      puzzle: controller.puzzle,
      app: harness.app,
      mode: 'level',
      levelIndex: 1,
      restore: saved,
    );
    expect(restored.marks[0], CellMark.cross);
    expect(restored.marks[1], CellMark.cat);
    restored.dispose();
    controller.dispose();
  });

  test('reiniciar limpia marcas, pistas y cronómetro', () async {
    final harness = await createHarness();
    final controller = harness.controller;
    addTearDown(controller.dispose);

    controller.handleTap(0);
    controller.hint();
    controller.reset();
    expect(controller.marks.every((mark) => mark == CellMark.none), isTrue);
    expect(controller.hintsUsed, 0);
    expect(controller.elapsedSeconds, 0);
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
