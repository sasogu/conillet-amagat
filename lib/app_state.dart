import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'data/game_store.dart';
import 'data/puzzle_repository.dart';
import 'game/bunny_skin.dart';
import 'game/puzzle.dart';
import 'game/scoring.dart';
import 'l10n/strings.dart';

class AppState extends ChangeNotifier {
  AppState({required this.store, required this.repository}) {
    settings = store.readSettings();
    stats = store.readStats();
    savedGame = store.readGame();
    campaignStage = store.readCampaignStage();
    tutorialSeen = store.readTutorialSeen();
    unlockedSkins = store.readUnlockedSkins();
    selectedSkin = _validSkin(store.readSelectedSkin());
  }

  final GameStore store;
  final PuzzleRepository repository;

  late SettingsData settings;
  late StatsData stats;
  SavedGame? savedGame;
  late int campaignStage;
  late bool tutorialSeen;
  late Set<String> unlockedSkins;
  late String selectedSkin;

  BunnySkin get skin => skinById(selectedSkin);

  Strings get strings => Strings(catalan: settings.language == 'ca');

  ThemeMode get themeMode => settings.themeMode;

  Locale get locale => Locale(settings.language == 'ca' ? 'ca' : 'es');

  void reloadFromStore() {
    settings = store.readSettings();
    stats = store.readStats();
    savedGame = store.readGame();
    campaignStage = store.readCampaignStage();
    tutorialSeen = store.readTutorialSeen();
    unlockedSkins = store.readUnlockedSkins();
    selectedSkin = _validSkin(store.readSelectedSkin());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    settings = settings.copyWith(themeMode: mode);
    await store.writeSettings(settings);
    notifyListeners();
  }

  String _validSkin(String id) =>
      unlockedSkins.contains(id) ? id : 'white';

  Future<bool> selectSkin(String id) async {
    if (!unlockedSkins.contains(id)) return false;
    selectedSkin = id;
    await store.writeSelectedSkin(id);
    notifyListeners();
    return true;
  }

  Future<bool> unlockSkin(String id) async {
    final skin = skinById(id);
    if (unlockedSkins.contains(id)) return selectSkin(id);
    if (stats.carrots < skin.cost) return false;
    stats.carrots -= skin.cost;
    unlockedSkins = {...unlockedSkins, id};
    selectedSkin = id;
    await store.writeStats(stats);
    await store.writeUnlockedSkins(unlockedSkins);
    await store.writeSelectedSkin(id);
    notifyListeners();
    return true;
  }

  Future<void> markTutorialSeen() async {
    if (tutorialSeen) return;
    tutorialSeen = true;
    await store.writeTutorialSeen(true);
    notifyListeners();
  }

  Future<bool> spendCarrots(int amount) async {
    if (amount <= 0 || stats.carrots < amount) return false;
    stats.carrots -= amount;
    await store.writeStats(stats);
    notifyListeners();
    return true;
  }

  Future<void> setAutoCross(bool enabled) async {
    settings = settings.copyWith(autoCross: enabled);
    await store.writeSettings(settings);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    settings = settings.copyWith(language: language);
    await store.writeSettings(settings);
    notifyListeners();
  }

  int completedLevels(int size) => store.completedLevels(size);

  Future<void> setCampaignStage(int stage) async {
    campaignStage = stage;
    await store.writeCampaignStage(stage);
    notifyListeners();
  }

  bool get dailyCompletedToday => stats.lastDaily == _dayKey(DateTime.now());

  Future<void> saveGame(SavedGame game) async {
    savedGame = game;
    await store.writeGame(game);
  }

  Future<void> clearSavedGame() async {
    savedGame = null;
    await store.clearGame();
  }

  Future<void> recordCompletion({
    required Puzzle puzzle,
    required String mode,
    required int levelIndex,
    required int hintsUsed,
    required int seconds,
    int lives = 0,
    DateTime? now,
  }) async {
    final date = now ?? DateTime.now();
    stats.solved += 1;
    stats.solvedBySize.update(
      puzzle.size,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    stats.hintsUsed += hintsUsed;
    final score = scoreFor(puzzle: puzzle, seconds: seconds, lives: lives);
    stats.points += score.points;
    stats.carrots += score.carrots;

    if (mode == 'daily') {
      final today = _dayKey(date);
      if (stats.lastDaily != today) {
        final yesterday = _dayKey(date.subtract(const Duration(days: 1)));
        stats.dailyStreak = stats.lastDaily == yesterday
            ? stats.dailyStreak + 1
            : 1;
        stats.lastDaily = today;
      }
    } else {
      final completed = math.max(
        store.completedLevels(puzzle.size),
        levelIndex,
      );
      await store.setCompletedLevels(puzzle.size, completed);
      if (mode == 'campaign') {
        final next = math.max(campaignStage, levelIndex + 1);
        campaignStage = next;
        await store.writeCampaignStage(next);
      }
    }

    await store.writeStats(stats);
    await clearSavedGame();
    notifyListeners();
  }

  static int dateKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static String _dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado');
    return scope!.notifier!;
  }
}

void unawaitedPersist(Future<void> future) {
  unawaited(future);
}
