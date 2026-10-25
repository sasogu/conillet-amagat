import 'dart:convert';
import 'dart:io';

import 'package:conillet_amagat/game/generator.dart';

void main(List<String> args) {
  if (args.length != 4) {
    stderr.writeln(
      'Uso: dart run tool/gen_range.dart <size> <seedInicial> <cantidad> <salida>',
    );
    exit(2);
  }
  final size = int.parse(args[0]);
  final start = int.parse(args[1]);
  final count = int.parse(args[2]);
  final output = args[3];

  final puzzles = <Map<String, Object?>>[];
  var seed = start;
  final watch = Stopwatch()..start();
  while (puzzles.length < count && seed < start + 200000) {
    try {
      final puzzle = generatePuzzle(size: size, seed: seed);
      puzzles.add(puzzle.toJson());
      stdout.writeln(
        '$size $seed ok (${puzzles.length}/$count, ${watch.elapsed.inSeconds}s)',
      );
    } on StateError {
      // Semilla sin suerte: se prueba la siguiente.
    }
    seed++;
  }
  File(output).writeAsStringSync(jsonEncode(puzzles));
  stdout.writeln(
    'FIN $size $output ${puzzles.length} puzles, semillas $start..${seed - 1}, ${watch.elapsed.inSeconds}s',
  );
}
