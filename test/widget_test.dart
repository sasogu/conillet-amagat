import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conillet_amagat/app.dart';
import 'package:conillet_amagat/app_state.dart';
import 'package:conillet_amagat/data/game_store.dart';
import 'package:conillet_amagat/data/puzzle_repository.dart';
import 'package:conillet_amagat/ui/board_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> createApp({bool tutorialSeen = true}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repository = PuzzleRepository.fromJson(
    File('assets/puzzles.json').readAsStringSync(),
  );
  final store = GameStore(prefs);
  await store.writeTutorialSeen(tutorialSeen);
  return AppState(store: store, repository: repository);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la portada carga y abre la etapa actual', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = await createApp();
    await tester.pumpWidget(ConilletAmagatApp(app: app));
    await tester.pump();
    expect(find.text('Conillet amagat'), findsOneWidget);
    expect(find.text('Puzle diario'), findsOneWidget);
    expect(find.text('Tu etapa'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('campaign-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(BoardView), findsOneWidget);
    expect(find.text('Etapa 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('el tutorial aparece la primera vez y se recuerda', (
    tester,
  ) async {
    final app = await createApp(tutorialSeen: false);
    await tester.pumpWidget(ConilletAmagatApp(app: app));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cómo jugar'), findsOneWidget);
    expect(find.text('Tres vidas por puzle'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(app.tutorialSeen, isTrue);
    expect(app.store.readTutorialSeen(), isTrue);
    expect(find.text('Cómo jugar'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('los ajustes cambian el idioma de toda la app', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = await createApp();
    await tester.pumpWidget(ConilletAmagatApp(app: app));
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
    expect(find.text('La teva etapa'), findsOneWidget);
  });

  testWidgets('los ajustes abren los aspectos del conejo', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = await createApp();
    await tester.pumpWidget(ConilletAmagatApp(app: app));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aspectos'));
    await tester.pumpAndSettle();

    expect(find.text('Blanco'), findsOneWidget);
    expect(find.text('Gris'), findsOneWidget);
    expect(find.text('En uso'), findsOneWidget);
    expect(find.textContaining('Desbloquear'), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('un fallo descuenta una vida y sin vidas pide reiniciar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = await createApp();
    await tester.pumpWidget(ConilletAmagatApp(app: app));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('campaign-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    final puzzle = app.repository.levelPuzzle(6, 1);
    final rect = tester.getRect(find.byType(BoardView));
    final cellSize = rect.width / puzzle.size;
    final wrongCells = [
      for (var cell = 0; cell < puzzle.cellCount; cell++)
        if (!puzzle.solution.contains(cell)) cell,
    ].take(3).toList();

    Future<void> doubleTap(int cell) async {
      final point =
          rect.topLeft +
          Offset(
            (cell % puzzle.size + 0.5) * cellSize,
            (cell ~/ puzzle.size + 0.5) * cellSize,
          );
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 400));
    }

    await doubleTap(wrongCells[0]);
    expect(find.text('Conejo mal colocado. Te quedan 2 vidas.'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await doubleTap(wrongCells[1]);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('Conejo mal colocado. Te queda 1 vida.'), findsOneWidget);

    await doubleTap(wrongCells[2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Sin vidas'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.text('Necesitas 3 zanahorias para revivir.'), findsOneWidget);
    expect(find.text('Revivir · 3 zanahorias'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Reiniciar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Sin vidas'), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('revivir gasta zanahorias y devuelve una vida', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = await createApp();
    app.stats.carrots = 5;
    await app.store.writeStats(app.stats);
    await tester.pumpWidget(ConilletAmagatApp(app: app));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('campaign-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    final puzzle = app.repository.levelPuzzle(6, 1);
    final rect = tester.getRect(find.byType(BoardView));
    final cellSize = rect.width / puzzle.size;
    final wrongCells = [
      for (var cell = 0; cell < puzzle.cellCount; cell++)
        if (!puzzle.solution.contains(cell)) cell,
    ].take(3).toList();

    for (final cell in wrongCells) {
      final point =
          rect.topLeft +
          Offset(
            (cell % puzzle.size + 0.5) * cellSize,
            (cell ~/ puzzle.size + 0.5) * cellSize,
          );
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Sin vidas'), findsOneWidget);
    expect(find.text('Tienes 5 zanahorias'), findsOneWidget);
    expect(find.text('Revivir · 3 zanahorias'), findsOneWidget);

    await tester.tap(find.text('Revivir · 3 zanahorias'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Sin vidas'), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(app.stats.carrots, 2);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('resolver una etapa suma puntos y zanahorias', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = await createApp();
    await tester.pumpWidget(ConilletAmagatApp(app: app));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('campaign-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    final puzzle = app.repository.levelPuzzle(6, 1);
    final given = puzzle.solution.take(2).toSet();
    final rect = tester.getRect(find.byType(BoardView));
    final cellSize = rect.width / puzzle.size;

    for (final cell in puzzle.solution.where((cell) => !given.contains(cell))) {
      final point =
          rect.topLeft +
          Offset(
            (cell % puzzle.size + 0.5) * cellSize,
            (cell ~/ puzzle.size + 0.5) * cellSize,
          );
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 450));
    }

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    expect(find.text('¡Puzle resuelto!'), findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Puntos')),
      findsOneWidget,
    );
    expect(find.text('3 zanahorias para el conejo'), findsOneWidget);
    expect(find.text('Salto rápido: 3 etapas'), findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.textContaining('+')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(app.stats.points, greaterThan(0));
    expect(app.stats.carrots, 3);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
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
