import 'dart:io';

import 'package:conillet_amagat/app_state.dart';
import 'package:conillet_amagat/data/game_store.dart';
import 'package:conillet_amagat/data/puzzle_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> createApp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repository = PuzzleRepository.fromJson(
    File('assets/puzzles.json').readAsStringSync(),
  );
  return AppState(store: GameStore(prefs), repository: repository);
}

void main() {
  test('el conejo blanco está desbloqueado y equipado por defecto', () async {
    final app = await createApp();
    expect(app.selectedSkin, 'white');
    expect(app.unlockedSkins, contains('white'));
    expect(app.skin.id, 'white');
  });

  test('el conejo lila cuesta 40 zanahorias', () async {
    final app = await createApp();
    app.stats.carrots = 50;
    await app.store.writeStats(app.stats);
    expect(await app.unlockSkin('lilac'), isTrue);
    expect(app.selectedSkin, 'lilac');
    expect(app.stats.carrots, 10);
    expect(app.skin.body.toARGB32(), 0xFFC9A7E8);
  });

  test('desbloquear un aspecto gasta zanahorias y lo equipa', () async {
    final app = await createApp();
    app.stats.carrots = 20;
    await app.store.writeStats(app.stats);

    expect(await app.unlockSkin('gray'), isTrue);
    expect(app.selectedSkin, 'gray');
    expect(app.unlockedSkins, contains('gray'));
    expect(app.stats.carrots, 10);
    expect(app.store.readStats().carrots, 10);
    expect(app.store.readSelectedSkin(), 'gray');

    expect(await app.selectSkin('white'), isTrue);
    expect(app.selectedSkin, 'white');
    expect(app.store.readSelectedSkin(), 'white');
  });

  test('sin zanahorias suficientes no se desbloquea un aspecto', () async {
    final app = await createApp();
    app.stats.carrots = 5;
    await app.store.writeStats(app.stats);

    expect(await app.unlockSkin('carrot'), isFalse);
    expect(app.selectedSkin, 'white');
    expect(app.unlockedSkins, isNot(contains('carrot')));
    expect(app.stats.carrots, 5);
  });
}
