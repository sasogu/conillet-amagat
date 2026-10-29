import 'package:conillet_amagat/data/game_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los puntos y las zanahorias se guardan en las estadísticas', () {
    final stats = StatsData(
      points: 18450,
      carrots: 27,
      lastDailyScore: 1500,
      lastDailySeconds: 120,
      lastDailyLives: 3,
      lastDailySize: 6,
    );
    final restored = StatsData.fromJson(stats.toJson());
    expect(restored.points, 18450);
    expect(restored.carrots, 27);
    expect(restored.lastDailyScore, 1500);
    expect(restored.lastDailySeconds, 120);
    expect(restored.lastDailyLives, 3);
    expect(restored.lastDailySize, 6);
  });

  test('el apodo se guarda en los ajustes', () {
    const settings = SettingsData(nickname: 'Tester');
    final restored = SettingsData.fromJson(settings.toJson());
    expect(restored.nickname, 'Tester');
  });

  test('el valencià és el valor per defecte i es conserva el castellà', () {
    expect(const SettingsData().language, 'ca');
    expect(SettingsData.fromJson(const {}).language, 'ca');
    const spanish = SettingsData(language: 'es');
    expect(SettingsData.fromJson(spanish.toJson()).language, 'es');
  });
}
