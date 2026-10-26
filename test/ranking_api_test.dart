import 'dart:convert';

import 'package:conillet_amagat/ranking/player_id.dart';
import 'package:conillet_amagat/ranking/ranking_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('el identificador de jugador es un UUID v4', () {
    final id = generatePlayerId();
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(generatePlayerId(), isNot(id));
  });

  test('lee el ranking diario y el histórico', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/daily')) {
        return http.Response(
          jsonEncode({
            'day': '2026-10-26',
            'entries': [
              {
                'rank': 1,
                'nickname': 'Tester',
                'score': 1500,
                'seconds': 120,
                'lives': 3,
                'size': 6,
                'me': true,
              },
            ],
            'my': {
              'rank': 1,
              'nickname': 'Tester',
              'score': 1500,
              'seconds': 120,
              'lives': 3,
              'size': 6,
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response(
        jsonEncode({
          'entries': [
            {
              'rank': 1,
              'nickname': 'Tester',
              'total': 4500,
              'days': 3,
              'me': true,
            },
          ],
          'my': {
            'rank': 1,
            'nickname': 'Tester',
            'total': 4500,
            'days': 3,
          },
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = RankingApi(client: client);

    final daily = await api.daily(day: '2026-10-26', deviceId: 'test');
    expect(daily.entries.single.nickname, 'Tester');
    expect(daily.entries.single.score, 1500);
    expect(daily.my?.rank, 1);

    final history = await api.history(deviceId: 'test');
    expect(history.entries.single.total, 4500);
    expect(history.my?.days, 3);

    api.close();
  });

  test('envía la marca y convierte los errores del servidor', () async {
    final client = MockClient((request) async {
      if (request.body.contains('"score":9999')) {
        return http.Response(
          jsonEncode({'message': 'Puntuación no válida.', 'status': 400}),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response(
        jsonEncode({'ok': true, 'improved': true, 'score': 1500, 'total': 1500}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = RankingApi(client: client);

    final result = await api.submitDaily(
      deviceId: 'test-device-0000000001',
      nickname: 'Tester',
      day: '2026-10-26',
      score: 1500,
      seconds: 120,
      lives: 3,
      size: 6,
    );
    expect(result.improved, isTrue);
    expect(result.total, 1500);

    expect(
      () => api.submitDaily(
        deviceId: 'test-device-0000000001',
        nickname: 'Tester',
        day: '2026-10-26',
        score: 9999,
        seconds: 120,
        lives: 3,
        size: 6,
      ),
      throwsA(
        isA<RankingException>().having(
          (error) => error.message,
          'message',
          'Puntuación no válida.',
        ),
      ),
    );

    api.close();
  });
}
