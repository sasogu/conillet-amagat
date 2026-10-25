import 'package:flutter_test/flutter_test.dart';
import 'package:conillet_amagat/game/generator.dart';
import 'package:conillet_amagat/game/solver.dart';

void main() {
  for (final size in [6, 7]) {
    test('genera un $size×$size determinista y con solución única', () {
      final first = generatePuzzle(size: size, seed: 424242);
      final second = generatePuzzle(size: size, seed: 424242);
      expect(first.regions, second.regions);
      expect(first.solution, second.solution);
      expect(first.isValid, isTrue);
      expect(countSolutions(first), 1);

      final linked = <int>{first.solution.first};
      final queue = <int>[first.solution.first];
      final region = first.regions[first.solution.first];
      while (queue.isNotEmpty) {
        final cell = queue.removeLast();
        final row = first.rowOf(cell);
        final col = first.colOf(cell);
        for (final other in [
          if (row > 0) cell - size,
          if (row < size - 1) cell + size,
          if (col > 0) cell - 1,
          if (col < size - 1) cell + 1,
        ]) {
          if (first.regions[other] == region && linked.add(other)) {
            queue.add(other);
          }
        }
      }
      expect(
        linked.length,
        first.regions.where((value) => value == region).length,
      );
    });
  }
}
