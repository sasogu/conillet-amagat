import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronron/app.dart';
import 'package:ronron/app_state.dart';
import 'package:ronron/data/game_store.dart';
import 'package:ronron/data/puzzle_repository.dart';
import 'package:ronron/ui/board_view.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la portada carga y abre un nivel', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = await createApp();
    await tester.pumpWidget(RonronApp(app: app));
    await tester.pump();
    expect(find.text('Ronrón'), findsOneWidget);
    expect(find.text('Puzle diario'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('level-6')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('level-6')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(BoardView), findsOneWidget);
    expect(find.text('Nivel 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('los ajustes cambian el idioma de toda la app', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = await createApp();
    await tester.pumpWidget(RonronApp(app: app));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);

    await tester.tap(find.text('Valencià'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustos'), findsOneWidget);
    expect(app.settings.language, 'ca');

    await tester.tap(find.text('Tanca'));
    await tester.pumpAndSettle();
    expect(find.text('Nivells'), findsOneWidget);
  });

  testWidgets('el tablero distingue un toque de un doble toque', (
    tester,
  ) async {
    final app = await createApp();
    final puzzle = app.repository.levelPuzzle(6, 1);
    int? single;
    int? doubleTapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 360,
              child: BoardView(
                puzzle: puzzle,
                marks: List.filled(puzzle.cellCount, CellMark.none),
                blocked: const {},
                conflicts: const {},
                onTap: (cell) => single = cell,
                onDoubleTap: (cell) => doubleTapped = cell,
                onDragMark: (_) {},
                onDragEnd: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final rect = tester.getRect(find.byType(BoardView));
    final cellSize = rect.width / puzzle.size;
    final first = rect.topLeft + Offset(cellSize * 0.5, cellSize * 0.5);
    await tester.tapAt(first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(single, puzzle.cellAt(0, 0));

    final second = rect.topLeft + Offset(cellSize * 1.5, cellSize * 0.5);
    await tester.tapAt(second);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(second);
    await tester.pump(const Duration(milliseconds: 400));
    expect(doubleTapped, puzzle.cellAt(0, 1));
  });
}
