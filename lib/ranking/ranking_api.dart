import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ranking_config.dart';

class RankingException implements Exception {
  RankingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.nickname,
    required this.score,
    required this.seconds,
    required this.lives,
    required this.size,
    required this.me,
  });

  final int rank;
  final String nickname;
  final int score;
  final int seconds;
  final int lives;
  final int size;
  final bool me;

  factory RankingEntry.fromJson(Map<String, Object?> json) => RankingEntry(
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    nickname: json['nickname'] as String? ?? '',
    score: (json['score'] as num?)?.toInt() ?? 0,
    seconds: (json['seconds'] as num?)?.toInt() ?? 0,
    lives: (json['lives'] as num?)?.toInt() ?? 0,
    size: (json['size'] as num?)?.toInt() ?? 0,
    me: json['me'] as bool? ?? false,
  );
}

class DailyRanking {
  const DailyRanking({
    required this.day,
    required this.entries,
    required this.my,
  });

  final String day;
  final List<RankingEntry> entries;
  final RankingEntry? my;

  factory DailyRanking.fromJson(Map<String, Object?> json) => DailyRanking(
    day: json['day'] as String? ?? '',
    entries: ((json['entries'] as List?) ?? const [])
        .map((value) => RankingEntry.fromJson((value as Map).cast()))
        .toList(growable: false),
    my: json['my'] is Map
        ? RankingEntry.fromJson((json['my'] as Map).cast())
        : null,
  );
}

class HistoryEntry {
  const HistoryEntry({
    required this.rank,
    required this.nickname,
    required this.total,
    required this.days,
    required this.me,
  });

  final int rank;
  final String nickname;
  final int total;
  final int days;
  final bool me;

  factory HistoryEntry.fromJson(Map<String, Object?> json) => HistoryEntry(
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    nickname: json['nickname'] as String? ?? '',
    total: (json['total'] as num?)?.toInt() ?? 0,
    days: (json['days'] as num?)?.toInt() ?? 0,
    me: json['me'] as bool? ?? false,
  );
}

class HistoryRanking {
  const HistoryRanking({required this.entries, required this.my});

  final List<HistoryEntry> entries;
  final HistoryEntry? my;

  factory HistoryRanking.fromJson(Map<String, Object?> json) => HistoryRanking(
    entries: ((json['entries'] as List?) ?? const [])
        .map((value) => HistoryEntry.fromJson((value as Map).cast()))
        .toList(growable: false),
    my: json['my'] is Map
        ? HistoryEntry.fromJson((json['my'] as Map).cast())
        : null,
  );
}

class GeneralEntry {
  const GeneralEntry({
    required this.rank,
    required this.nickname,
    required this.points,
    required this.me,
  });

  final int rank;
  final String nickname;
  final int points;
  final bool me;

  factory GeneralEntry.fromJson(Map<String, Object?> json) => GeneralEntry(
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    nickname: json['nickname'] as String? ?? '',
    points: (json['points'] as num?)?.toInt() ?? 0,
    me: json['me'] as bool? ?? false,
  );
}

class GeneralRanking {
  const GeneralRanking({required this.entries, required this.my});

  final List<GeneralEntry> entries;
  final GeneralEntry? my;

  factory GeneralRanking.fromJson(Map<String, Object?> json) => GeneralRanking(
    entries: ((json['entries'] as List?) ?? const [])
        .map((value) => GeneralEntry.fromJson((value as Map).cast()))
        .toList(growable: false),
    my: json['my'] is Map
        ? GeneralEntry.fromJson((json['my'] as Map).cast())
        : null,
  );
}

class SubmitResult {
  const SubmitResult({
    required this.improved,
    required this.score,
    required this.total,
  });

  final bool improved;
  final int score;
  final int total;

  factory SubmitResult.fromJson(Map<String, Object?> json) => SubmitResult(
    improved: json['improved'] as bool? ?? false,
    score: (json['score'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );
}

class RankingApi {
  RankingApi({http.Client? client}) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 12);

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$rankingApiBase$path').replace(queryParameters: query);

  Future<SubmitResult> submitDaily({
    required String deviceId,
    required String nickname,
    required String day,
    required int score,
    required int seconds,
    required int lives,
    required int size,
  }) async {
    final response = await _client
        .post(
          _uri('/api/conillet/submit'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'deviceId': deviceId,
            'nickname': nickname,
            'day': day,
            'score': score,
            'seconds': seconds,
            'lives': lives,
            'size': size,
          }),
        )
        .timeout(_timeout);
    return SubmitResult.fromJson(_decode(response));
  }

  Future<DailyRanking> daily({
    required String day,
    required String deviceId,
  }) async {
    final response = await _client
        .get(
          _uri('/api/conillet/daily', {
            'day': day,
            'deviceId': deviceId,
          }),
        )
        .timeout(_timeout);
    return DailyRanking.fromJson(_decode(response));
  }

  Future<HistoryRanking> history({required String deviceId}) async {
    final response = await _client
        .get(_uri('/api/conillet/history', {'deviceId': deviceId}))
        .timeout(_timeout);
    return HistoryRanking.fromJson(_decode(response));
  }

  Future<void> submitPoints({
    required String deviceId,
    required String nickname,
    required int points,
  }) async {
    final response = await _client
        .post(
          _uri('/api/conillet/points'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'deviceId': deviceId,
            'nickname': nickname,
            'points': points,
          }),
        )
        .timeout(_timeout);
    _decode(response);
  }

  Future<GeneralRanking> general({required String deviceId}) async {
    final response = await _client
        .get(_uri('/api/conillet/general', {'deviceId': deviceId}))
        .timeout(_timeout);
    return GeneralRanking.fromJson(_decode(response));
  }

  Map<String, Object?> _decode(http.Response response) {
    Map<String, Object?> data = {};
    try {
      data = (jsonDecode(utf8.decode(response.bodyBytes)) as Map).cast();
    } catch (_) {
      data = {};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RankingException(
        data['message'] as String? ?? 'No se pudo conectar con el ranking.',
      );
    }
    return data;
  }

  void close() => _client.close();
}
