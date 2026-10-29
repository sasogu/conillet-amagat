import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:conillet_amagat/app_state.dart';
import 'package:conillet_amagat/data/game_store.dart';
import 'package:conillet_amagat/data/puzzle_repository.dart';
import 'package:conillet_amagat/game/scoring.dart';
import 'package:conillet_amagat/ranking/ranking_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('al resolver el diario se envían la marca y los puntos', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final requests = <String, Map<String, dynamic>>{};
    final sent = Completer<void>();
    final api = RankingApi(
      client: MockClient((request) async {
        requests[request.url.path.split('/').last] =
            jsonDecode(request.body) as Map<String, dynamic>;
        if (requests.length == 2 && !sent.isCompleted) sent.complete();
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );
    addTearDown(api.close);
    final app = AppState(
      store: GameStore(prefs),
      repository: PuzzleRepository.fromJson(
        File('assets/puzzles.json').readAsStringSync(),
      ),
      rankingApi: api,
    );
    await app.setNickname('Tester');
    final puzzle = app.repository.levelPuzzle(6, 1);

    await app.recordCompletion(
      puzzle: puzzle,
      mode: 'daily',
      levelIndex: AppState.dateKey(DateTime.now()),
      hintsUsed: 0,
      seconds: 80,
      lives: 2,
    );
    await sent.future.timeout(const Duration(seconds: 2));

    final expected = scoreFor(puzzle: puzzle, seconds: 80, lives: 2).points;
    expect(requests['points']?['points'], expected);
    expect(requests['submit']?['score'], expected);
    expect(requests['submit']?['nickname'], 'Tester');
    expect(requests['submit']?['day'], AppState.dayKeyString(DateTime.now()));
  });
}
