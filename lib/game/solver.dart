import 'puzzle.dart';

/// Cuenta soluciones completas (hasta [limit]) recorriendo fila a fila.
///
/// Es un recorrido exhaustivo: garantiza que el recuento es exacto.
int countSolutions(Puzzle puzzle, {int limit = 2}) {
  final size = puzzle.size;
  final usedColumns = List<bool>.filled(size, false);
  final usedRegions = List<bool>.filled(size, false);
  var found = 0;

  void search(int row, int previousColumn) {
    if (found >= limit) return;
    if (row == size) {
      found++;
      return;
    }
    for (var column = 0; column < size; column++) {
      if (usedColumns[column]) continue;
      if (previousColumn >= 0 && (column - previousColumn).abs() <= 1) continue;
      final region = puzzle.regions[puzzle.cellAt(row, column)];
      if (usedRegions[region]) continue;
      usedColumns[column] = true;
      usedRegions[region] = true;
      search(row + 1, column);
      usedColumns[column] = false;
      usedRegions[region] = false;
      if (found >= limit) return;
    }
  }

  search(0, -1);
  return found;
}

class HumanSolveResult {
  final bool solved;
  final bool contradiction;

  /// Se necesitó razonar con la interacción región-fila o región-columna.
  final bool usedInteractions;

  const HumanSolveResult({
    required this.solved,
    required this.contradiction,
    required this.usedInteractions,
  });
}

/// Resuelve como lo haría una persona: solo deducciones forzadas, sin probar
/// hipótesis. Sirve para clasificar la dificultad.
HumanSolveResult humanSolve(Puzzle puzzle) {
  final size = puzzle.size;
  final possible = List<bool>.filled(puzzle.cellCount, true);
  final isCat = List<bool>.filled(puzzle.cellCount, false);
  final rowCat = List<bool>.filled(size, false);
  final colCat = List<bool>.filled(size, false);
  final regionCat = List<bool>.filled(size, false);
  var contradiction = false;
  var usedInteractions = false;

  final cellsByRow = List.generate(size, (row) => <int>[]);
  final cellsByCol = List.generate(size, (col) => <int>[]);
  final cellsByRegion = puzzle.regionCells;
  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      final cell = puzzle.cellAt(row, col);
      cellsByRow[row].add(cell);
      cellsByCol[col].add(cell);
    }
  }

  bool place(int cell) {
    if (isCat[cell]) return false;
    final row = puzzle.rowOf(cell);
    final col = puzzle.colOf(cell);
    final region = puzzle.regions[cell];
    if (rowCat[row] || colCat[col] || regionCat[region]) {
      contradiction = true;
      return false;
    }
    for (var adjacentRow = row - 1; adjacentRow <= row + 1; adjacentRow++) {
      if (adjacentRow < 0 || adjacentRow >= size) continue;
      for (var adjacentCol = col - 1; adjacentCol <= col + 1; adjacentCol++) {
        if (adjacentCol < 0 || adjacentCol >= size) continue;
        final other = puzzle.cellAt(adjacentRow, adjacentCol);
        if (other != cell && isCat[other]) {
          contradiction = true;
          return false;
        }
      }
    }
    isCat[cell] = true;
    rowCat[row] = true;
    colCat[col] = true;
    regionCat[region] = true;
    return true;
  }

  bool pass() {
    var changed = false;

    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      if (!isCat[cell]) continue;
      final row = puzzle.rowOf(cell);
      final col = puzzle.colOf(cell);
      final region = puzzle.regions[cell];
      for (final other in cellsByRow[row]) {
        if (other != cell && possible[other]) {
          possible[other] = false;
          changed = true;
        }
      }
      for (final other in cellsByCol[col]) {
        if (other != cell && possible[other]) {
          possible[other] = false;
          changed = true;
        }
      }
      for (final other in cellsByRegion[region]) {
        if (other != cell && possible[other]) {
          possible[other] = false;
          changed = true;
        }
      }
      for (final adjacentRow in [row - 1, row + 1]) {
        if (adjacentRow < 0 || adjacentRow >= size) continue;
        for (final adjacentCol in [col - 1, col, col + 1]) {
          if (adjacentCol < 0 || adjacentCol >= size) continue;
          final other = puzzle.cellAt(adjacentRow, adjacentCol);
          if (possible[other]) {
            possible[other] = false;
            changed = true;
          }
        }
      }
    }

    void checkUnit(List<int> cells, bool hasCat) {
      if (contradiction || hasCat) return;
      var count = 0;
      var last = -1;
      for (final cell in cells) {
        if (possible[cell]) {
          count++;
          last = cell;
        }
      }
      if (count == 0) {
        contradiction = true;
      } else if (count == 1) {
        if (place(last)) changed = true;
      }
    }

    for (var index = 0; index < size; index++) {
      checkUnit(cellsByRow[index], rowCat[index]);
      checkUnit(cellsByCol[index], colCat[index]);
      checkUnit(cellsByRegion[index], regionCat[index]);
      if (contradiction) return changed;
    }

    // Si todos los candidatos de una región están en una fila (o columna),
    // el conejo de esa fila (o columna) pertenece a la región.
    for (var region = 0; region < size; region++) {
      if (regionCat[region]) continue;
      final candidates = <int>[
        for (final cell in cellsByRegion[region])
          if (possible[cell]) cell,
      ];
      if (candidates.length < 2) continue;
      final rows = <int>{for (final cell in candidates) puzzle.rowOf(cell)};
      if (rows.length == 1) {
        final row = rows.first;
        if (rowCat[row]) {
          contradiction = true;
          return changed;
        }
        for (final cell in cellsByRow[row]) {
          if (puzzle.regions[cell] != region && possible[cell]) {
            possible[cell] = false;
            changed = true;
            usedInteractions = true;
          }
        }
      }
      final cols = <int>{for (final cell in candidates) puzzle.colOf(cell)};
      if (cols.length == 1) {
        final col = cols.first;
        if (colCat[col]) {
          contradiction = true;
          return changed;
        }
        for (final cell in cellsByCol[col]) {
          if (puzzle.regions[cell] != region && possible[cell]) {
            possible[cell] = false;
            changed = true;
            usedInteractions = true;
          }
        }
      }
    }

    return changed;
  }

  while (!contradiction) {
    final changed = pass();
    if (contradiction) break;
    if (!changed) break;
  }

  var bunnies = 0;
  for (final value in isCat) {
    if (value) bunnies++;
  }
  return HumanSolveResult(
    solved: !contradiction && bunnies == size,
    contradiction: contradiction,
    usedInteractions: usedInteractions,
  );
}

Difficulty ratePuzzle(Puzzle puzzle) {
  final result = humanSolve(puzzle);
  if (!result.solved) return Difficulty.hard;
  return result.usedInteractions ? Difficulty.medium : Difficulty.easy;
}
