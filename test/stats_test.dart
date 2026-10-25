import 'package:conillet_amagat/data/game_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los puntos y las zanahorias se guardan en las estadísticas', () {
    final stats = StatsData(points: 18450, carrots: 27);
    final restored = StatsData.fromJson(stats.toJson());
    expect(restored.points, 18450);
    expect(restored.carrots, 27);
  });
}
