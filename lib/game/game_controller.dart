import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/game_store.dart';
import 'puzzle.dart';

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
  }) : marks = List<CellMark>.filled(puzzle.cellCount, CellMark.none) {
    _regionCells = puzzle.regionCells;
    if (restore != null) {
      elapsedSeconds = restore.elapsedSeconds;
      hintsUsed = restore.hintsUsed;
      for (var index = 0; index < puzzle.cellCount; index++) {
        final value = restore.marks[index];
        marks[index] = value >= 0 && value < CellMark.values.length
            ? CellMark.values[value]
            : CellMark.none;
      }
    }
    _startTicker();
    _saveSoon();
  }

  final Puzzle puzzle;
  final AppState app;
  final String mode;
  final int levelIndex;

  final List<CellMark> marks;
  late final List<List<int>> _regionCells;

  final List<_Move> _history = [];
  Timer? _ticker;
  Timer? _saveTimer;
  bool _disposed = false;
  bool _winRecorded = false;

  int elapsedSeconds = 0;
  int hintsUsed = 0;
  bool finished = false;
  bool paused = false;

  bool get canUndo => _history.isNotEmpty && !finished;

  bool get autoCrossEnabled => app.settings.autoCross;

  int get catCount => marks.where((mark) => mark == CellMark.cat).length;

  Set<int> get cats => {
    for (var cell = 0; cell < marks.length; cell++)
      if (marks[cell] == CellMark.cat) cell,
  };

  /// Casillas descartadas automáticamente por los gatos ya colocados.
  Set<int> get blockedCells {
    if (!app.settings.autoCross) return const {};
    final blocked = <int>{};
    for (final cell in cats) {
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
    blocked.removeAll(cats);
    return blocked;
  }

  Set<int> get conflictCells {
    final list = cats.toList(growable: false);
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

  bool get isSolvedByPlayer => puzzle.isSolution(cats);

  void handleTap(int cell) {
    if (finished) return;
    switch (marks[cell]) {
      case CellMark.cat:
      case CellMark.cross:
        _apply(cell, CellMark.none);
      case CellMark.none:
        _apply(cell, CellMark.cross);
        HapticFeedback.selectionClick();
    }
  }

  void handleDoubleTap(int cell) {
    if (finished) return;
    final next = marks[cell] == CellMark.cat ? CellMark.none : CellMark.cat;
    _apply(cell, next, haptic: next == CellMark.cat);
  }

  void handleDrag(int cell) {
    if (finished) return;
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
    if (finished) return null;
    final candidates = <int>[
      for (final cell in puzzle.solution)
        if (marks[cell] != CellMark.cat) cell,
    ];
    if (candidates.isEmpty) return null;
    final cell = candidates.first;
    hintsUsed += 1;
    _apply(cell, CellMark.cat, haptic: true);
    return cell;
  }

  void reset() {
    if (finished) return;
    _history.clear();
    for (var index = 0; index < marks.length; index++) {
      marks[index] = CellMark.none;
    }
    elapsedSeconds = 0;
    hintsUsed = 0;
    _restartTicker();
    _saveSoon();
    notifyListeners();
  }

  void pause() {
    if (paused || finished) return;
    paused = true;
    _ticker?.cancel();
    _persistNow();
    notifyListeners();
  }

  void resume() {
    if (!paused || finished) return;
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
    if (finished || _winRecorded) return;
    if (!puzzle.isSolution(cats)) return;
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
    if (paused || finished) return;
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
