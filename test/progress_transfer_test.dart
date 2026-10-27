import 'dart:convert';
import 'dart:io';

import 'package:conillet_amagat/data/game_store.dart';
import 'package:conillet_amagat/data/puzzle_repository.dart';
import 'package:conillet_amagat/game/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameStore> createStore() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return GameStore(prefs);
}

void main() {
  test('exporta e importa todo el progreso', () async {
    final repository = PuzzleRepository.fromJson(
      File('assets/puzzles.json').readAsStringSync(),
    );
    final store = await createStore();
    final puzzle = repository.levelPuzzle(6, 1);
    final saved = SavedGame(
      puzzle: puzzle,
      marks: List<int>.filled(puzzle.cellCount, 0),
      elapsedSeconds: 42,
      hintsUsed: 3,
      mode: 'level',
      levelIndex: 1,
      lives: 2,
      given: [puzzle.solution.first],
    );

    await store.writeSettings(
      const SettingsData(
        themeMode: ThemeMode.dark,
        autoCross: false,
        language: 'ca',
        nickname: 'Daizan',
      ),
    );
    await store.writeStats(
      StatsData(
        solved: 12,
        solvedBySize: {6: 4, 7: 3, 8: 3, 9: 2},
        dailyStreak: 5,
        lastDaily: '2026-10-26',
        hintsUsed: 7,
        points: 1234,
        carrots: 22,
        lastDailyScore: 210,
        lastDailySeconds: 95,
        lastDailyLives: 2,
        lastDailySize: 7,
      ),
    );
    await store.writeCampaignStage(37);
    await store.writeTutorialSeen(true);
    await store.writeUnlockedSkins({'white', 'gray', 'lilac'});
    await store.writeSelectedSkin('lilac');
    await store.writePlayerId('player-123');
    for (final size in supportedSizes) {
      await store.setCompletedLevels(size, size * 2);
    }
    await store.writeGame(saved);

    final payload = store.exportProgress();
    expect(payload['format'], GameStore.progressFormat);
    expect(payload['version'], GameStore.progressVersion);

    final decoded = (jsonDecode(jsonEncode(payload)) as Map)
        .cast<String, Object?>();

    SharedPreferences.setMockInitialValues({});
    final otherPrefs = await SharedPreferences.getInstance();
    final restored = GameStore(otherPrefs);
    await restored.importProgress(decoded);

    final settings = restored.readSettings();
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.autoCross, isFalse);
    expect(settings.language, 'ca');
    expect(settings.nickname, 'Daizan');

    final stats = restored.readStats();
    expect(stats.solved, 12);
    expect(stats.solvedBySize[6], 4);
    expect(stats.solvedBySize[9], 2);
    expect(stats.dailyStreak, 5);
    expect(stats.lastDaily, '2026-10-26');
    expect(stats.hintsUsed, 7);
    expect(stats.points, 1234);
    expect(stats.carrots, 22);
    expect(stats.lastDailyScore, 210);
    expect(stats.lastDailySeconds, 95);
    expect(stats.lastDailyLives, 2);
    expect(stats.lastDailySize, 7);

    expect(restored.readCampaignStage(), 37);
    expect(restored.readTutorialSeen(), isTrue);
    expect(
      restored.readUnlockedSkins(),
      containsAll(<String>['white', 'gray', 'lilac']),
    );
    expect(restored.readSelectedSkin(), 'lilac');
    expect(restored.readPlayerId(), 'player-123');

    for (final size in supportedSizes) {
      expect(restored.completedLevels(size), size * 2);
    }

    final restoredGame = restored.readGame();
    expect(restoredGame, isNotNull);
    expect(restoredGame!.puzzle.size, 6);
    expect(restoredGame.elapsedSeconds, 42);
    expect(restoredGame.hintsUsed, 3);
    expect(restoredGame.lives, 2);
    expect(restoredGame.marks, hasLength(puzzle.cellCount));
  });

  test('rechaza copias con formato o versión desconocidos', () async {
    final store = await createStore();
    await expectLater(
      store.importProgress({'format': 'otro', 'version': 1, 'data': {}}),
      throwsFormatException,
    );
    await expectLater(
      store.importProgress({
        'format': GameStore.progressFormat,
        'version': 99,
        'data': {},
      }),
      throwsFormatException,
    );
    await expectLater(
      store.importProgress({'format': GameStore.progressFormat, 'version': 1}),
      throwsFormatException,
    );
  });

  test('una partida guardada inválida no impide importar el resto', () async {
    final store = await createStore();
    await store.writeStats(StatsData(points: 1));
    final payload = store.exportProgress();
    final data = (payload['data'] as Map).cast<String, Object?>();
    data['savedGame'] = {
      'marks': [1, 2, 3],
    };
    data['stats'] = {'points': 99};

    await store.importProgress(payload);

    expect(store.readStats().points, 99);
    expect(store.readGame(), isNull);
  });
}
