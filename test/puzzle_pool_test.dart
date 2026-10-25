import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:conillet_amagat/game/puzzle.dart';
import 'package:conillet_amagat/game/solver.dart';

void main() {
  final data =
      jsonDecode(File('assets/puzzles.json').readAsStringSync())
          as Map<String, dynamic>;

  test('el lote contiene puzles válidos, conexos y únicos', () {
    var total = 0;
    for (final entry in data.entries) {
      final size = int.parse(entry.key);
      final list = entry.value as List;
      expect(list, isNotEmpty, reason: 'Sin puzles de $size×$size');
      for (var index = 0; index < list.length; index++) {
        total++;
        final puzzle = Puzzle.fromJson(
          (list[index] as Map).cast<String, Object?>(),
        );
        expect(puzzle.size, size);
        expect(puzzle.isValid, isTrue, reason: '$size #$index no válido');

        final counts = List<int>.filled(size, 0);
        for (final region in puzzle.regions) {
          counts[region]++;
        }
        expect(counts.every((count) => count > 0), isTrue);

        for (var region = 0; region < size; region++) {
          final cells = [
            for (var cell = 0; cell < puzzle.cellCount; cell++)
              if (puzzle.regions[cell] == region) cell,
          ];
          final seen = <int>{cells.first};
          final queue = <int>[cells.first];
          while (queue.isNotEmpty) {
            final cell = queue.removeLast();
            final row = puzzle.rowOf(cell);
            final col = puzzle.colOf(cell);
            for (final other in [
              if (row > 0) cell - size,
              if (row < size - 1) cell + size,
              if (col > 0) cell - 1,
              if (col < size - 1) cell + 1,
            ]) {
              if (puzzle.regions[other] == region && seen.add(other)) {
                queue.add(other);
              }
            }
          }
          expect(
            seen.length,
            cells.length,
            reason: 'Región $region desconectada en $size #$index',
          );
        }

        expect(
          countSolutions(puzzle, limit: 2),
          1,
          reason: 'Solución no única en $size #$index',
        );
      }
    }
    expect(total, greaterThanOrEqualTo(350));
  });
}
