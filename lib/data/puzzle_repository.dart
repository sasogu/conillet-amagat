import 'dart:convert';

import 'package:flutter/services.dart';

import '../game/puzzle.dart';

/// Colección de puzles verificados que viaja dentro de la aplicación.
class PuzzleRepository {
  PuzzleRepository._(this._bySize);

  final Map<int, List<Puzzle>> _bySize;

  static Future<PuzzleRepository> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString('assets/puzzles.json');
    return PuzzleRepository.fromJson(raw);
  }

  factory PuzzleRepository.fromJson(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final bySize = <int, List<Puzzle>>{};
    decoded.forEach((key, value) {
      final size = int.parse(key);
      final puzzles = (value as List)
          .map((item) => Puzzle.fromJson((item as Map).cast<String, Object?>()))
          .toList(growable: false);
      if (puzzles.isEmpty) {
        throw StateError('No hay puzles de $size×$size');
      }
      for (final puzzle in puzzles) {
        if (puzzle.size != size) {
          throw StateError('Puzle de tamaño incorrecto en el lote $size');
        }
      }
      bySize[size] = puzzles;
    });
    for (final size in supportedSizes) {
      if (!bySize.containsKey(size)) {
        throw StateError('Faltan puzles de $size×$size');
      }
    }
    return PuzzleRepository._(bySize);
  }

  List<Puzzle> puzzlesFor(int size) => _bySize[size] ?? const [];

  /// Nivel sin fin: los puzles se reciclan cuando se agota el lote.
  Puzzle levelPuzzle(int size, int level) {
    final puzzles = puzzlesFor(size);
    return puzzles[(level - 1) % puzzles.length];
  }

  /// Cada día de la semana usa un tamaño distinto.
  static const dailySizes = [6, 7, 8, 9, 8, 7, 9];

  Puzzle dailyPuzzle(DateTime date) {
    final size = dailySizes[date.weekday - 1];
    final puzzles = puzzlesFor(size);
    final index = dailySeed(date, size) % puzzles.length;
    return puzzles[index];
  }

  int dailySizeFor(DateTime date) => dailySizes[date.weekday - 1];
}
