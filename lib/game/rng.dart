/// Generador pseudoaleatorio pequeño y determinista.
///
/// Se usa xorshift32 para que una misma semilla produzca siempre el mismo
/// puzle en cualquier plataforma y versión de Dart.
class Rng {
  int _state;

  Rng(int seed)
    : _state = (seed & 0xFFFFFFFF) == 0 ? 0x9E3779B9 : seed & 0xFFFFFFFF;

  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return _state;
  }

  /// Entero en [0, max). `max` debe ser mayor que cero.
  int below(int max) => nextUint32() % max;

  double nextDouble() => nextUint32() / 0x100000000;

  T pick<T>(List<T> values) => values[below(values.length)];

  void shuffle<T>(List<T> values) {
    for (var i = values.length - 1; i > 0; i--) {
      final j = below(i + 1);
      final tmp = values[i];
      values[i] = values[j];
      values[j] = tmp;
    }
  }
}

/// Hash estable (FNV-1a de 32 bits) para convertir textos en semillas.
int stableSeed(String text) {
  var hash = 0x811C9DC5;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
