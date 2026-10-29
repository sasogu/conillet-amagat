import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_info.dart';
import '../game/puzzle.dart';

enum CellMark { none, bunny, cross }

/// Vidas disponibles al empezar o reiniciar un puzle.
const int startingLives = 3;

class SettingsData {
  final ThemeMode themeMode;
  final bool autoCross;
  final String language; // 'es' o 'ca'
  final String nickname;

  const SettingsData({
    this.themeMode = ThemeMode.system,
    this.autoCross = true,
    this.language = 'ca',
    this.nickname = '',
  });

  SettingsData copyWith({
    ThemeMode? themeMode,
    bool? autoCross,
    String? language,
    String? nickname,
  }) => SettingsData(
    themeMode: themeMode ?? this.themeMode,
    autoCross: autoCross ?? this.autoCross,
    language: language ?? this.language,
    nickname: nickname ?? this.nickname,
  );

  Map<String, Object?> toJson() => {
    'theme': themeMode.name,
    'autoCross': autoCross,
    'language': language,
    'nickname': nickname,
  };

  factory SettingsData.fromJson(Map<String, Object?> json) => SettingsData(
    themeMode: ThemeMode.values.firstWhere(
      (value) => value.name == json['theme'],
      orElse: () => ThemeMode.system,
    ),
    autoCross: json['autoCross'] as bool? ?? true,
    language: json['language'] as String? ?? 'ca',
    nickname: json['nickname'] as String? ?? '',
  );
}

class StatsData {
  int solved;
  Map<int, int> solvedBySize;
  int dailyStreak;
  String? lastDaily;
  int hintsUsed;
  int points;
  int carrots;
  int lastDailyScore;
  int lastDailySeconds;
  int lastDailyLives;
  int lastDailySize;

  StatsData({
    this.solved = 0,
    Map<int, int>? solvedBySize,
    this.dailyStreak = 0,
    this.lastDaily,
    this.hintsUsed = 0,
    this.points = 0,
    this.carrots = 0,
    this.lastDailyScore = 0,
    this.lastDailySeconds = 0,
    this.lastDailyLives = 0,
    this.lastDailySize = 0,
  }) : solvedBySize = solvedBySize ?? {};

  Map<String, Object?> toJson() => {
    'solved': solved,
    'bySize': {
      for (final entry in solvedBySize.entries) '${entry.key}': entry.value,
    },
    'dailyStreak': dailyStreak,
    'lastDaily': lastDaily,
    'hintsUsed': hintsUsed,
    'points': points,
    'carrots': carrots,
    'lastDailyScore': lastDailyScore,
    'lastDailySeconds': lastDailySeconds,
    'lastDailyLives': lastDailyLives,
    'lastDailySize': lastDailySize,
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
      points: (json['points'] as num?)?.toInt() ?? 0,
      carrots: (json['carrots'] as num?)?.toInt() ?? 0,
      lastDailyScore: (json['lastDailyScore'] as num?)?.toInt() ?? 0,
      lastDailySeconds: (json['lastDailySeconds'] as num?)?.toInt() ?? 0,
      lastDailyLives: (json['lastDailyLives'] as num?)?.toInt() ?? 0,
      lastDailySize: (json['lastDailySize'] as num?)?.toInt() ?? 0,
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
  static const _tutorialKey = 'ronron.tutorial.v1';
  static const _skinsKey = 'ronron.skins.unlocked';
  static const _selectedSkinKey = 'ronron.skins.selected';
  static const _playerIdKey = 'ronron.player.id';

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

  Future<void> writeCampaignStage(int stage) => _prefs.setInt(_stageKey, stage);

  bool readTutorialSeen() => _prefs.getBool(_tutorialKey) ?? false;

  Future<void> writeTutorialSeen(bool value) =>
      _prefs.setBool(_tutorialKey, value);

  Set<String> readUnlockedSkins() {
    final stored = _prefs.getStringList(_skinsKey);
    final skins = stored == null ? <String>{} : stored.toSet();
    skins.add('white');
    return skins;
  }

  Future<void> writeUnlockedSkins(Set<String> skins) =>
      _prefs.setStringList(_skinsKey, skins.toList(growable: false));

  String readSelectedSkin() => _prefs.getString(_selectedSkinKey) ?? 'white';

  Future<void> writeSelectedSkin(String id) =>
      _prefs.setString(_selectedSkinKey, id);

  String readPlayerId() => _prefs.getString(_playerIdKey) ?? '';

  Future<void> writePlayerId(String id) => _prefs.setString(_playerIdKey, id);

  static const String progressFormat = 'conillet-amagat.progress';
  static const int progressVersion = 1;

  Map<String, Object?> exportProgress() {
    final skins = readUnlockedSkins().toList()..sort();
    final saved = readGame();
    return {
      'format': progressFormat,
      'version': progressVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion': appVersion,
      'data': {
        'settings': readSettings().toJson(),
        'stats': readStats().toJson(),
        'campaignStage': readCampaignStage(),
        'tutorialSeen': readTutorialSeen(),
        'unlockedSkins': skins,
        'selectedSkin': readSelectedSkin(),
        'playerId': readPlayerId(),
        'completedLevels': {
          for (final size in supportedSizes) '$size': completedLevels(size),
        },
        'savedGame': saved?.toJson(),
      },
    };
  }

  Future<void> importProgress(Map<String, Object?> payload) async {
    if (payload['format'] != progressFormat) {
      throw const FormatException('Formato de progreso desconocido');
    }
    final version = payload['version'];
    if (version is! num || version.toInt() != progressVersion) {
      throw const FormatException('Versión de progreso no compatible');
    }
    final rawData = payload['data'];
    if (rawData is! Map) {
      throw const FormatException('El archivo no contiene datos de progreso');
    }
    final data = rawData.cast<String, Object?>();

    final SettingsData settings;
    final StatsData stats;
    try {
      settings = SettingsData.fromJson(
        ((data['settings'] as Map?) ?? const {}).cast<String, Object?>(),
      );
      stats = StatsData.fromJson(
        ((data['stats'] as Map?) ?? const {}).cast<String, Object?>(),
      );
    } catch (_) {
      throw const FormatException('Ajustes o estadísticas no válidos');
    }

    final rawSkins = data['unlockedSkins'];
    final skins = <String>{'white'};
    if (rawSkins is List) {
      for (final id in rawSkins) {
        if (id is String && id.isNotEmpty) skins.add(id);
      }
    }
    final rawSelected = data['selectedSkin'];
    final selected = rawSelected is String && skins.contains(rawSelected)
        ? rawSelected
        : 'white';

    final levels = <int, int>{for (final size in supportedSizes) size: 0};
    final rawLevels = data['completedLevels'];
    if (rawLevels is Map) {
      for (final size in supportedSizes) {
        final value = rawLevels['$size'];
        if (value is num) {
          levels[size] = value.toInt().clamp(0, 1 << 30).toInt();
        }
      }
    }

    SavedGame? saved;
    final rawSaved = data['savedGame'];
    if (rawSaved is Map) {
      try {
        final candidate = SavedGame.fromJson(rawSaved.cast<String, Object?>());
        if (candidate.puzzle.isValid &&
            candidate.marks.length == candidate.puzzle.cellCount) {
          saved = candidate;
        }
      } catch (_) {
        saved = null;
      }
    }

    final rawStage = data['campaignStage'];
    final stage = rawStage is num ? rawStage.toInt() : 1;
    final rawPlayerId = data['playerId'];
    final playerId = rawPlayerId is String ? rawPlayerId.trim() : '';

    await writeSettings(settings);
    await writeStats(stats);
    await writeCampaignStage(stage < 1 ? 1 : stage);
    await writeTutorialSeen(data['tutorialSeen'] == true);
    await writeUnlockedSkins(skins);
    await writeSelectedSkin(selected);
    if (playerId.isNotEmpty) await writePlayerId(playerId);
    for (final size in supportedSizes) {
      await setCompletedLevels(size, levels[size] ?? 0);
    }
    if (saved != null) {
      await writeGame(saved);
    } else {
      await clearGame();
    }
  }
}
