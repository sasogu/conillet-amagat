import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/puzzle.dart';

enum CellMark { none, bunny, cross }

/// Vidas disponibles al empezar o reiniciar un puzle.
const int startingLives = 3;

class SettingsData {
  final ThemeMode themeMode;
  final bool autoCross;
  final String language; // 'es' o 'ca'

  const SettingsData({
    this.themeMode = ThemeMode.system,
    this.autoCross = true,
    this.language = 'es',
  });

  SettingsData copyWith({
    ThemeMode? themeMode,
    bool? autoCross,
    String? language,
  }) => SettingsData(
    themeMode: themeMode ?? this.themeMode,
    autoCross: autoCross ?? this.autoCross,
    language: language ?? this.language,
  );

  Map<String, Object?> toJson() => {
    'theme': themeMode.name,
    'autoCross': autoCross,
    'language': language,
  };

  factory SettingsData.fromJson(Map<String, Object?> json) => SettingsData(
    themeMode: ThemeMode.values.firstWhere(
      (value) => value.name == json['theme'],
      orElse: () => ThemeMode.system,
    ),
    autoCross: json['autoCross'] as bool? ?? true,
    language: json['language'] as String? ?? 'es',
  );
}

class StatsData {
  int solved;
  Map<int, int> solvedBySize;
  int dailyStreak;
  String? lastDaily;
  int hintsUsed;

  StatsData({
    this.solved = 0,
    Map<int, int>? solvedBySize,
    this.dailyStreak = 0,
    this.lastDaily,
    this.hintsUsed = 0,
  }) : solvedBySize = solvedBySize ?? {};

  Map<String, Object?> toJson() => {
    'solved': solved,
    'bySize': {
      for (final entry in solvedBySize.entries) '${entry.key}': entry.value,
    },
    'dailyStreak': dailyStreak,
    'lastDaily': lastDaily,
    'hintsUsed': hintsUsed,
  };

  factory StatsData.fromJson(Map<String, Object?> json) {
    final bySize = <int, int>{};
    final raw = json['bySize'];
    if (raw is Map) {
      raw.forEach((key, value) {
        final size = int.tryParse('$key');
        if (size != null && value is num) bySize[size] = value.toInt();
      });
    }
    return StatsData(
      solved: (json['solved'] as num?)?.toInt() ?? 0,
      solvedBySize: bySize,
      dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
      lastDaily: json['lastDaily'] as String?,
      hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
    );
  }
}

class SavedGame {
  final Puzzle puzzle;
  final List<int> marks;
  final int elapsedSeconds;
  final int hintsUsed;
  final String mode;
  final int levelIndex;
  final int lives;
  final List<int> given;

  SavedGame({
    required this.puzzle,
    required this.marks,
    required this.elapsedSeconds,
    required this.hintsUsed,
    required this.mode,
    required this.levelIndex,
    this.lives = startingLives,
    this.given = const [],
  });

  Map<String, Object?> toJson() => {
    'puzzle': puzzle.toJson(),
    'marks': marks,
    'elapsed': elapsedSeconds,
    'hints': hintsUsed,
    'mode': mode,
    'level': levelIndex,
    'lives': lives,
    'given': given,
  };

  factory SavedGame.fromJson(Map<String, Object?> json) => SavedGame(
    puzzle: Puzzle.fromJson((json['puzzle'] as Map).cast<String, Object?>()),
    marks: (json['marks'] as List)
        .map((value) => (value as num).toInt())
        .toList(),
    elapsedSeconds: (json['elapsed'] as num?)?.toInt() ?? 0,
    hintsUsed: (json['hints'] as num?)?.toInt() ?? 0,
    mode: json['mode'] as String? ?? 'level',
    levelIndex: (json['level'] as num?)?.toInt() ?? 1,
    lives: (json['lives'] as num?)?.toInt() ?? startingLives,
    given: ((json['given'] as List?) ?? const [])
        .map((value) => (value as num).toInt())
        .toList(),
  );
}

class GameStore {
  GameStore(this._prefs);

  final SharedPreferences _prefs;

  static const _settingsKey = 'ronron.settings.v1';
  static const _statsKey = 'ronron.stats.v1';
  static const _gameKey = 'ronron.game.v1';
  static const _levelKeyPrefix = 'ronron.level.';
  static const _stageKey = 'ronron.campaign.stage';

  SettingsData readSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const SettingsData();
    try {
      return SettingsData.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return const SettingsData();
    }
  }

  Future<void> writeSettings(SettingsData settings) =>
      _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));

  StatsData readStats() {
    final raw = _prefs.getString(_statsKey);
    if (raw == null) return StatsData();
    try {
      return StatsData.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return StatsData();
    }
  }

  Future<void> writeStats(StatsData stats) =>
      _prefs.setString(_statsKey, jsonEncode(stats.toJson()));

  SavedGame? readGame() {
    final raw = _prefs.getString(_gameKey);
    if (raw == null) return null;
    try {
      final saved = SavedGame.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
      if (!saved.puzzle.isValid) return null;
      if (saved.marks.length != saved.puzzle.cellCount) return null;
      return saved;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeGame(SavedGame game) =>
      _prefs.setString(_gameKey, jsonEncode(game.toJson()));

  Future<void> clearGame() => _prefs.remove(_gameKey);

  int completedLevels(int size) => _prefs.getInt('$_levelKeyPrefix$size') ?? 0;

  Future<void> setCompletedLevels(int size, int value) =>
      _prefs.setInt('$_levelKeyPrefix$size', value);

  int readCampaignStage() => _prefs.getInt(_stageKey) ?? 1;

  Future<void> writeCampaignStage(int stage) =>
      _prefs.setInt(_stageKey, stage);
}
