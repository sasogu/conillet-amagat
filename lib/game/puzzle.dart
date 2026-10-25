import 'rng.dart';

enum Difficulty { easy, medium, hard, expert }

const List<int> supportedSizes = [6, 7, 8, 9];

/// Un puzle de gatos: cuadrícula n×n dividida en n regiones conexas.
/// La solución coloca un gato por fila, columna y región, sin que dos gatos
/// se toquen (ni siquiera en diagonal).
class Puzzle {
  final int size;
  final int seed;

  /// Identificador de región (0..size-1) para cada casilla, en orden de filas.
  final List<int> regions;

  /// Casillas (índice fila × tamaño + columna) ocupadas por gatos.
  final List<int> solution;

  final Difficulty difficulty;

  Puzzle({
    required this.size,
    required this.seed,
    required List<int> regions,
    required List<int> solution,
    required this.difficulty,
  }) : regions = List.unmodifiable(regions),
       solution = List.unmodifiable(solution) {
    if (size < 4 || size > 12) {
      throw ArgumentError.value(size, 'size', 'Tamaño no admitido');
    }
    if (regions.length != size * size) {
      throw ArgumentError('La lista de regiones no coincide con el tamaño');
    }
    if (solution.length != size) {
      throw ArgumentError('La solución debe tener $size gatos');
    }
  }

  int get cellCount => size * size;

  int rowOf(int cell) => cell ~/ size;

  int colOf(int cell) => cell % size;

  int cellAt(int row, int col) => row * size + col;

  /// Casillas agrupadas por región.
  List<List<int>> get regionCells {
    final groups = List.generate(size, (_) => <int>[]);
    for (var cell = 0; cell < cellCount; cell++) {
      groups[regions[cell]].add(cell);
    }
    return groups;
  }

  bool isSolution(Iterable<int> cats) {
    if (cats.length != size) return false;
    final placed = cats.toSet();
    if (placed.length != size) return false;
    for (var i = 0; i < size; i++) {
      if (!placed.contains(solution[i])) return false;
    }
    return true;
  }

  /// Comprueba las invariantes internas del puzle. Se usa en tests y al
  /// restaurar una partida guardada.
  bool get isValid {
    if (regions.length != cellCount || solution.length != size) return false;
    final perRegion = List<int>.filled(size, 0);
    final rows = List<int>.filled(size, 0);
    final cols = List<int>.filled(size, 0);
    for (final region in regions) {
      if (region < 0 || region >= size) return false;
      perRegion[region]++;
    }
    if (perRegion.any((count) => count == 0)) return false;
    for (final cell in solution) {
      if (cell < 0 || cell >= cellCount) return false;
      rows[rowOf(cell)]++;
      cols[colOf(cell)]++;
    }
    if (rows.any((count) => count != 1)) return false;
    if (cols.any((count) => count != 1)) return false;

    final sorted = [...solution]..sort();
    for (var i = 1; i < sorted.length; i++) {
      final previous = sorted[i - 1];
      final current = sorted[i];
      final rowDistance = (rowOf(previous) - rowOf(current)).abs();
      final colDistance = (colOf(previous) - colOf(current)).abs();
      if (rowDistance <= 1 && colDistance <= 1) return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
    'size': size,
    'seed': seed,
    'regions': regions,
    'solution': solution,
    'difficulty': difficulty.name,
  };

  factory Puzzle.fromJson(Map<String, Object?> json) {
    final difficultyName = json['difficulty'] as String? ?? 'medium';
    return Puzzle(
      size: (json['size'] as num).toInt(),
      seed: (json['seed'] as num).toInt(),
      regions: (json['regions'] as List)
          .map((value) => (value as num).toInt())
          .toList(),
      solution: (json['solution'] as List)
          .map((value) => (value as num).toInt())
          .toList(),
      difficulty: Difficulty.values.firstWhere(
        (value) => value.name == difficultyName,
        orElse: () => Difficulty.medium,
      ),
    );
  }

  Puzzle withDifficulty(Difficulty value) => Puzzle(
    size: size,
    seed: seed,
    regions: regions,
    solution: solution,
    difficulty: value,
  );
}

int dailySeed(DateTime date, int size) =>
    stableSeed('ronron-daily-$size-${date.year}-${date.month}-${date.day}');

