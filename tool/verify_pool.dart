import 'dart:convert';
import 'dart:io';

import 'package:conillet_amagat/game/puzzle.dart';
import 'package:conillet_amagat/game/solver.dart';

void main() {
  final data =
      jsonDecode(File('assets/puzzles.json').readAsStringSync())
          as Map<String, dynamic>;
  var total = 0;
  var bad = 0;
  for (final entry in data.entries) {
    final size = int.parse(entry.key);
    final list = entry.value as List;
    for (var i = 0; i < list.length; i++) {
      total++;
      final puzzle = Puzzle.fromJson((list[i] as Map).cast<String, Object?>());
      final counts = List<int>.filled(size, 0);
      for (final region in puzzle.regions) {
        counts[region]++;
      }
      var connected = true;
      for (var region = 0; region < size; region++) {
        final cells = [
          for (var c = 0; c < puzzle.cellCount; c++)
            if (puzzle.regions[c] == region) c,
        ];
        final seen = <int>{cells.first};
        final queue = [cells.first];
        while (queue.isNotEmpty) {
          final cell = queue.removeLast();
          final row = puzzle.rowOf(cell), col = puzzle.colOf(cell);
          for (final other in [
            if (row > 0) cell - size,
            if (row < size - 1) cell + size,
            if (col > 0) cell - 1,
            if (col < size - 1) cell + 1,
          ]) {
            if (puzzle.regions[other] == region && seen.add(other))
              queue.add(other);
          }
        }
        if (seen.length != cells.length) connected = false;
      }
      final unique = countSolutions(puzzle) == 1;
      if (!puzzle.isValid || !unique || !connected) {
        bad++;
        print(
          'MAL $size #$i válido=${puzzle.isValid} único=$unique conexo=$connected',
        );
      }
    }
    final allSizes = <int>[];
    for (final item in list) {
      final puzzle = Puzzle.fromJson((item as Map).cast<String, Object?>());
      final counts = List<int>.filled(size, 0);
      for (final region in puzzle.regions) {
        counts[region]++;
      }
      allSizes.addAll(counts);
    }
    allSizes.sort();
    print(
      '$size×$size: ${list.length} puzles · regiones min=${allSizes.first} max=${allSizes.last} · OK',
    );
  }
  print('Total $total, malos $bad');
}
