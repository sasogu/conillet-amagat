import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/game_store.dart';
import 'puzzle.dart';

enum DoubleTapResult { none, placed, removed, wrong, outOfLives }

class _Move {
  const _Move(this.cell, this.previous);

  final int cell;
  final CellMark previous;
}

class GameController extends ChangeNotifier {
  GameController({
    required this.puzzle,
    required this.app,
    required this.mode,
    required this.levelIndex,
    SavedGame? restore,
    Iterable<int> given = const [],
  }) : marks = List<CellMark>.filled(puzzle.cellCount, CellMark.none) {
    _regionCells = puzzle.regionCells;
    givenCells = Set.unmodifiable(
      (restore != null ? restore.given : given).where(
        (cell) => cell >= 0 && cell < puzzle.cellCount,
      ),
    );
    if (restore != null) {
      elapsedSeconds = restore.elapsedSeconds;
      hintsUsed = restore.hintsUsed;
      lives = restore.lives.clamp(0, startingLives);
      failed = lives == 0;
      for (var index = 0; index < puzzle.cellCount; index++) {
        final value = restore.marks[index];
        marks[index] = value >= 0 && value < CellMark.values.length
            ? CellMark.values[value]
            : CellMark.none;
      }
    }
    for (final cell in givenCells) {
      marks[cell] = CellMark.bunny;
    }
    _startTicker();
    _saveSoon();
  }

  final Puzzle puzzle;
  final AppState app;
  final String mode;
  final int levelIndex;

  final List<CellMark> marks;
  late final Set<int> givenCells;
  late final List<List<int>> _regionCells;

  final List<_Move> _history = [];
  Timer? _ticker;
  Timer? _saveTimer;
  bool _disposed = false;
  bool _winRecorded = false;

  int elapsedSeconds = 0;
  int hintsUsed = 0;
  int lives = startingLives;
  bool finished = false;
  bool failed = false;
  bool paused = false;

  bool get canUndo => _history.isNotEmpty && !finished && !failed;

  bool get canPlay => !finished && !failed;

  bool get autoCrossEnabled => app.settings.autoCross;

  bool isGiven(int cell) => givenCells.contains(cell);

  int get bunnyCount => marks.where((mark) => mark == CellMark.bunny).length;

  Set<int> get bunnies => {
    for (var cell = 0; cell < marks.length; cell++)
      if (marks[cell] == CellMark.bunny) cell,
  };

  /// Casillas descartadas automáticamente por los conejos ya colocados.
  Set<int> get blockedCells {
    if (!app.settings.autoCross) return const {};
    final blocked = <int>{};
    for (final cell in bunnies) {
      final row = puzzle.rowOf(cell);
      final col = puzzle.colOf(cell);
      for (var otherCol = 0; otherCol < puzzle.size; otherCol++) {
        blocked.add(puzzle.cellAt(row, otherCol));
      }
      for (var otherRow = 0; otherRow < puzzle.size; otherRow++) {
        blocked.add(puzzle.cellAt(otherRow, col));
      }
      blocked.addAll(_regionCells[puzzle.regions[cell]]);
      blocked.addAll(_neighbours(cell));
    }
    blocked.removeAll(bunnies);
    return blocked;
  }

  Set<int> get conflictCells {
    final list = bunnies.toList(growable: false);
    final conflicts = <int>{};
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final first = list[i];
        final second = list[j];
        final rowDistance = (puzzle.rowOf(first) - puzzle.rowOf(second)).abs();
        final colDistance = (puzzle.colOf(first) - puzzle.colOf(second)).abs();
        final sameRow = rowDistance == 0;
        final sameCol = colDistance == 0;
        final sameRegion = puzzle.regions[first] == puzzle.regions[second];
        final touching = rowDistance <= 1 && colDistance <= 1;
        if (sameRow || sameCol || sameRegion || touching) {
          conflicts
            ..add(first)
            ..add(second);
        }
      }
    }
    return conflicts;
  }

  bool get isSolvedByPlayer => puzzle.isSolution(bunnies);

  void handleTap(int cell) {
    if (!canPlay || givenCells.contains(cell)) return;
    switch (marks[cell]) {
      case CellMark.bunny:
      case CellMark.cross:
        _apply(cell, CellMark.none);
      case CellMark.none:
        _apply(cell, CellMark.cross);
        HapticFeedback.selectionClick();
    }
  }

  DoubleTapResult handleDoubleTap(int cell) {
    if (!canPlay || givenCells.contains(cell)) {
      return DoubleTapResult.none;
    }
    if (marks[cell] == CellMark.bunny) {
      _apply(cell, CellMark.none);
      return DoubleTapResult.removed;
    }

    if (!puzzle.solution.contains(cell)) {
      lives = (lives - 1).clamp(0, startingLives);
      final outOfLives = lives == 0;
      if (outOfLives) {
        failed = true;
        _ticker?.cancel();
      }
      _apply(cell, CellMark.cross);
      HapticFeedback.heavyImpact();
      if (outOfLives) _persistNow();
      notifyListeners();
      return outOfLives ? DoubleTapResult.outOfLives : DoubleTapResult.wrong;
    }

    _apply(cell, CellMark.bunny, haptic: true);
    return DoubleTapResult.placed;
  }

  void handleDrag(int cell) {
    if (!canPlay || givenCells.contains(cell)) return;
    if (marks[cell] != CellMark.none) return;
    _apply(cell, CellMark.cross);
  }

  void undo() {
    if (!canUndo) return;
    final move = _history.removeLast();
    marks[move.cell] = move.previous;
    _saveSoon();
    notifyListeners();
  }

  int? hint() {
    if (!canPlay) return null;
    final candidates = <int>[
      for (final cell in puzzle.solution)
        if (marks[cell] != CellMark.bunny) cell,
    ];
    if (candidates.isEmpty) return null;
    final cell = candidates.first;
    hintsUsed += 1;
    _apply(cell, CellMark.bunny, haptic: true);
    return cell;
  }

  void reset() {
    if (finished) return;
    _history.clear();
    for (var index = 0; index < marks.length; index++) {
      marks[index] = CellMark.none;
    }
    for (final cell in givenCells) {
      marks[cell] = CellMark.bunny;
    }
    elapsedSeconds = 0;
    hintsUsed = 0;
    lives = startingLives;
    failed = false;
    _restartTicker();
    _saveSoon();
    notifyListeners();
  }

  void pause() {
    if (paused || !canPlay) return;
    paused = true;
    _ticker?.cancel();
    _persistNow();
    notifyListeners();
  }

  void resume() {
    if (!paused || !canPlay) return;
    paused = false;
    _startTicker();
    notifyListeners();
  }

  void _apply(int cell, CellMark mark, {bool haptic = false}) {
    final previous = marks[cell];
    if (previous == mark) return;
    _history.add(_Move(cell, previous));
    marks[cell] = mark;
    if (haptic) HapticFeedback.lightImpact();
    _checkWin();
    _saveSoon();
    notifyListeners();
  }

  void _checkWin() {
    if (finished || failed || _winRecorded) return;
    if (!puzzle.isSolution(bunnies)) return;
    if (conflictCells.isNotEmpty) return;
    finished = true;
    _winRecorded = true;
    _ticker?.cancel();
    _saveTimer?.cancel();
    HapticFeedback.heavyImpact();
    unawaited(
      app.recordCompletion(
        puzzle: puzzle,
        mode: mode,
        levelIndex: levelIndex,
        hintsUsed: hintsUsed,
        seconds: elapsedSeconds,
        lives: lives,
      ),
    );
  }

  Iterable<int> _neighbours(int cell) sync* {
    final row = puzzle.rowOf(cell);
    final col = puzzle.colOf(cell);
    for (var otherRow = row - 1; otherRow <= row + 1; otherRow++) {
      if (otherRow < 0 || otherRow >= puzzle.size) continue;
      for (var otherCol = col - 1; otherCol <= col + 1; otherCol++) {
        if (otherCol < 0 || otherCol >= puzzle.size) continue;
        final other = puzzle.cellAt(otherRow, otherCol);
        if (other != cell) yield other;
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    if (paused || !canPlay) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (paused || finished) return;
      elapsedSeconds += 1;
      if (elapsedSeconds % 5 == 0) _persistNow();
      notifyListeners();
    });
  }

  void _restartTicker() {
    _ticker?.cancel();
    _startTicker();
  }

  SavedGame _toSaved() => SavedGame(
    puzzle: puzzle,
    marks: [for (final mark in marks) mark.index],
    elapsedSeconds: elapsedSeconds,
    hintsUsed: hintsUsed,
    mode: mode,
    levelIndex: levelIndex,
    lives: lives,
    given: givenCells.toList(growable: false),
  );

  void _saveSoon() {
    if (finished || _disposed) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), _persistNow);
  }

  void _persistNow() {
    if (finished || _disposed) return;
    unawaited(app.saveGame(_toSaved()));
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (!finished) _persistNow();
    _ticker?.cancel();
    _disposed = true;
    super.dispose();
  }
}
