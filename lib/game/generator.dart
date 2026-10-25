import 'puzzle.dart';
import 'rng.dart';
import 'solver.dart';

class _BudgetExceeded implements Exception {}

/// Genera un puzle determinista para [size] y [seed].
///
/// Estrategia: se parte de una solución válida y cada gato empieza siendo una
/// región de una casilla. Después se reparten las casillas libres entre las
/// regiones vecinas comprobando, tras cada asignación, que la solución sigue
/// siendo única. Así las regiones son conexas y el puzle acaba con solución
/// única. Se reintenta con otra solución cuando una rama se atasca.
Puzzle generatePuzzle({
  required int size,
  required int seed,
  int maxAttempts = 3000,
  int nodeBudget = 1800,
}) {
  if (size < 4 || size > 12) {
    throw ArgumentError.value(size, 'size', 'Tamaño no admitido');
  }
  final rng = Rng(seed ^ 0x5EED5EED);
  final maxRegionSize = (size * 2.5).ceil();

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final solution = _randomSolution(size, rng);
    if (solution == null) continue;

    final regions = List<int>.filled(size * size, -1);
    final regionSizes = List<int>.filled(size, 1);
    for (var region = 0; region < size; region++) {
      regions[solution[region]] = region;
    }

    var nodes = 0;
    var ok = false;
    try {
      ok = _growRegions(size, regions, regionSizes, rng, () {
        if (++nodes > nodeBudget) throw _BudgetExceeded();
      });
    } on _BudgetExceeded {
      ok = false;
    }
    if (!ok) continue;
    if (regions.contains(-1)) continue;
    if (regionSizes.any((value) => value < 2)) continue;
    if (regionSizes.any((value) => value > maxRegionSize)) continue;

    final puzzle = Puzzle(
      size: size,
      seed: seed,
      regions: regions,
      solution: solution,
      difficulty: _difficultyForSize(size),
    );
    if (countSolutions(puzzle, limit: 2) != 1) continue;
    return puzzle;
  }

  throw StateError('No se pudo generar un puzle de $size×$size');
}

Difficulty _difficultyForSize(int size) => switch (size) {
  4 || 5 || 6 => Difficulty.easy,
  7 => Difficulty.medium,
  8 => Difficulty.hard,
  _ => Difficulty.expert,
};

bool _growRegions(
  int size,
  List<int> regions,
  List<int> regionSizes,
  Rng rng,
  void Function() countNode,
) {
  countNode();
  final total = size * size;
  final boundary = <int>[];
  var fewestOptions = 1 << 30;

  for (var cell = 0; cell < total; cell++) {
    if (regions[cell] != -1) continue;
    final options = _regionOptions(size, regions, cell);
    if (options.isEmpty) continue;
    boundary.add(cell);
    if (options.length < fewestOptions) fewestOptions = options.length;
  }
  if (boundary.isEmpty) return !regions.contains(-1);

  final cells = <int>[
    for (final cell in boundary)
      if (_regionOptions(size, regions, cell).length == fewestOptions) cell,
  ];
  rng.shuffle(cells);

  for (final cell in cells) {
    final options = _regionOptions(size, regions, cell);
    rng.shuffle(options);
    options.sort((a, b) => regionSizes[a].compareTo(regionSizes[b]));

    for (final region in options) {
      regions[cell] = region;
      regionSizes[region]++;
      if (countSolutionsPartial(size, regions, limit: 2) == 1 &&
          _growRegions(size, regions, regionSizes, rng, countNode)) {
        return true;
      }
      regions[cell] = -1;
      regionSizes[region]--;
    }
  }
  return false;
}

List<int> _regionOptions(int size, List<int> regions, int cell) {
  final options = <int>[];
  for (final neighbour in _neighbours(cell, size)) {
    final region = regions[neighbour];
    if (region != -1 && !options.contains(region)) options.add(region);
  }
  return options;
}

/// Cuenta soluciones de un tablero parcial. Las casillas sin región asignada
/// todavía no pueden contener gatos.
int countSolutionsPartial(int size, List<int> regions, {int limit = 2}) {
  final allowed = List<int>.filled(size, 0);
  final fullMask = (1 << size) - 1;
  for (var row = 0; row < size; row++) {
    var mask = 0;
    for (var col = 0; col < size; col++) {
      if (regions[row * size + col] != -1) mask |= 1 << col;
    }
    allowed[row] = mask;
  }

  final forbidden = List<int>.filled(size, 0);
  final usedRegions = List<bool>.filled(size, false);
  final rowAssigned = List<bool>.filled(size, false);
  var usedColumns = 0;
  var found = 0;

  void search(int assignedCount) {
    if (found >= limit) return;
    if (assignedCount == size) {
      found++;
      return;
    }

    var bestRow = -1;
    var bestCount = 1 << 30;
    for (var row = 0; row < size; row++) {
      if (rowAssigned[row]) continue;
      final count = _popcount(allowed[row] & ~forbidden[row] & ~usedColumns);
      if (count == 0) return;
      if (count < bestCount) {
        bestCount = count;
        bestRow = row;
        if (count == 1) break;
      }
    }

    rowAssigned[bestRow] = true;
    var mask = allowed[bestRow] & ~forbidden[bestRow] & ~usedColumns;
    while (mask != 0) {
      final bit = mask & -mask;
      final col = bit.bitLength - 1;
      final region = regions[bestRow * size + col];
      if (region != -1 && !usedRegions[region]) {
        usedRegions[region] = true;
        usedColumns |= bit;
        final adjacencyMask = ((bit << 1) | bit | (bit >> 1)) & fullMask;
        final beforeAbove = bestRow > 0 ? forbidden[bestRow - 1] : 0;
        final beforeBelow = bestRow < size - 1 ? forbidden[bestRow + 1] : 0;
        if (bestRow > 0) forbidden[bestRow - 1] |= adjacencyMask;
        if (bestRow < size - 1) forbidden[bestRow + 1] |= adjacencyMask;

        search(assignedCount + 1);

        if (bestRow > 0) forbidden[bestRow - 1] = beforeAbove;
        if (bestRow < size - 1) forbidden[bestRow + 1] = beforeBelow;
        usedColumns &= ~bit;
        usedRegions[region] = false;
        if (found >= limit) break;
      }
      mask &= ~bit;
    }
    rowAssigned[bestRow] = false;
  }

  search(0);
  return found;
}

int _popcount(int value) {
  var count = 0;
  while (value != 0) {
    value &= value - 1;
    count++;
  }
  return count;
}

List<int>? _randomSolution(int size, Rng rng) {
  final solution = List<int>.filled(size, -1);

  bool place(int row) {
    if (row == size) return true;
    final columns = List<int>.generate(size, (index) => index);
    rng.shuffle(columns);
    for (final column in columns) {
      if (row > 0 && (column - solution[row - 1]).abs() <= 1) continue;
      var used = false;
      for (var previous = 0; previous < row; previous++) {
        if (solution[previous] == column) {
          used = true;
          break;
        }
      }
      if (used) continue;
      solution[row] = column;
      if (place(row + 1)) return true;
      solution[row] = -1;
    }
    return false;
  }

  if (!place(0)) return null;
  return [for (var row = 0; row < size; row++) row * size + solution[row]];
}

Iterable<int> _neighbours(int cell, int size) sync* {
  final row = cell ~/ size;
  final col = cell % size;
  if (row > 0) yield cell - size;
  if (row < size - 1) yield cell + size;
  if (col > 0) yield cell - 1;
  if (col < size - 1) yield cell + 1;
}
