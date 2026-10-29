import 'dart:convert';
import 'dart:io';

import 'package:conillet_amagat/app_state.dart';
import 'package:conillet_amagat/data/game_store.dart';
import 'package:conillet_amagat/data/puzzle_repository.dart';
import 'package:conillet_amagat/ranking/ranking_api.dart';
import 'package:conillet_amagat/ui/ranking_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> createApp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repository = PuzzleRepository.fromJson(
    File('assets/puzzles.json').readAsStringSync(),
  );
  final store = GameStore(prefs);
  await store.writeTutorialSeen(true);
  final app = AppState(store: store, repository: repository);
  await app.setNickname('Tester');
  final today = AppState.dayKeyString(DateTime.now());
  app.stats
    ..lastDaily = today
    ..lastDailyScore = 1500
    ..lastDailySeconds = 120
    ..lastDailyLives = 3
    ..lastDailySize = 6
    ..points = 18450;
  return app;
}

void main() {
  testWidgets('sincroniza al abrir y permite reintentar', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = await createApp();
    var dailySubmissions = 0;
    var pointSubmissions = 0;
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        if (request.url.path.endsWith('/submit')) dailySubmissions++;
        if (request.url.path.endsWith('/points')) pointSubmissions++;
        return http.Response(
          jsonEncode({
            'ok': true,
            'improved': true,
            'score': 1500,
            'total': 1500,
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/history')) {
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
            'my': null,
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/general')) {
        return http.Response(
          jsonEncode({
            'entries': [
              {'rank': 1, 'nickname': 'Tester', 'points': 18450, 'me': true},
            ],
            'my': null,
          }),
          200,
        );
      }
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
          'my': null,
        }),
        200,
      );
    });
    final api = RankingApi(client: client);

    await tester.pumpWidget(
      MaterialApp(
        home: RankingPage(app: app, api: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('Tester'), findsOneWidget);
    expect(find.textContaining('1.500'), findsWidgets);
    expect(dailySubmissions, greaterThanOrEqualTo(1));
    expect(pointSubmissions, greaterThanOrEqualTo(1));

    await tester.tap(find.text('Volver a sincronizar').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Marca enviada'), findsOneWidget);

    await tester.tap(find.text('Histórico'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('4.500'), findsOneWidget);

    await tester.tap(find.text('General'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('18.450'), findsWidgets);
    await tester.tap(find.text('Volver a sincronizar').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Puntos enviados'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    api.close();
  });
}
