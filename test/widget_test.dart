import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebash/game_controller.dart';
import 'package:kebash/main.dart';
import 'package:kebash_engine/kebash_engine.dart';

void main() {
  testWidgets('starts a two-player game and plays a tapped hole', (
    tester,
  ) async {
    await tester.pumpWidget(const KebashApp(initialLocale: Locale('en')));
    await tester.tap(find.text('Two players'));
    await tester.pump();
    await tester.tap(find.text('Start game'));
    await tester.pumpAndSettle();

    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Player 1 to move'), findsOneWidget);
    expect(find.text('4'), findsNWidgets(12));

    await tester.tap(find.byKey(const ValueKey('hole-A1')));
    // The opening move sows 26 stones at 300 ms a step.
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Player 2 to move'), findsOneWidget);
  });

  testWidgets('shows Arabic and keeps the board left to right', (tester) async {
    await tester.pumpWidget(const KebashApp(initialLocale: Locale('ar')));
    expect(find.text('كباش'), findsOneWidget);
    await tester.tap(find.text('ابدأ اللعب'));
    await tester.pumpAndSettle();

    expect(find.text('الجولة 1'), findsOneWidget);
    final a1 = tester.getCenter(find.byKey(const ValueKey('hole-A1')));
    final a6 = tester.getCenter(find.byKey(const ValueKey('hole-A6')));
    final b6 = tester.getCenter(find.byKey(const ValueKey('hole-B6')));
    expect(a1.dx, lessThan(a6.dx));
    expect(b6.dy, lessThan(a6.dy));
    expect(b6.dx, a6.dx);
  });

  testWidgets('fits a small phone in both languages', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (code, start) in [
      ('en', 'Start game'),
      ('ar', 'ابدأ اللعب'),
      ('ja', 'ゲーム開始'),
    ]) {
      await tester.pumpWidget(
        KebashApp(key: ValueKey(code), initialLocale: Locale(code)),
      );
      await tester.tap(find.text(start));
      await tester.pumpAndSettle();
      // A layout overflow would fail the test here.
      expect(find.byKey(const ValueKey('hole-B6')), findsOneWidget);
    }
  });

  testWidgets('landscape phone shows the whole board without scrolling', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final size in const [Size(568, 320), Size(844, 390)]) {
      tester.view.physicalSize = size;
      for (final (code, start) in [
        ('en', 'Start game'),
        ('ar', 'ابدأ اللعب'),
        ('ja', 'ゲーム開始'),
      ]) {
        await tester.pumpWidget(
          KebashApp(key: UniqueKey(), initialLocale: Locale(code)),
        );
        await tester.ensureVisible(find.text(start));
        await tester.tap(find.text(start));
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsNothing);
        final screen = Offset.zero & size;
        for (final hole in ['A1', 'A6', 'B1', 'B6']) {
          final rect = tester.getRect(find.byKey(ValueKey('hole-$hole')));
          expect(screen.contains(rect.topLeft), isTrue);
          expect(screen.contains(rect.bottomRight), isTrue);
        }
      }
    }
  });

  testWidgets('rules open from home and from the game in both languages', (
    tester,
  ) async {
    for (final (code, howTo, start, goal) in [
      ('en', 'How to play', 'Start game', 'Goal'),
      ('ar', 'طريقة اللعب', 'ابدأ اللعب', 'الهدف'),
      ('ja', '遊び方', 'ゲーム開始', '目的'),
    ]) {
      await tester.pumpWidget(
        KebashApp(key: UniqueKey(), initialLocale: Locale(code)),
      );
      await tester.tap(find.text(howTo));
      await tester.pumpAndSettle();
      expect(find.text(goal), findsOneWidget);
      await tester.scrollUntilVisible(find.text('9'), 300);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text(start));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(howTo));
      await tester.pumpAndSettle();
      expect(find.text(goal), findsOneWidget);
    }
  });

  testWidgets('switches to Japanese from the language menu', (tester) async {
    await tester.pumpWidget(const KebashApp(initialLocale: Locale('en')));
    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日本語').last);
    await tester.pumpAndSettle();

    expect(find.text('ケバシュ'), findsOneWidget);
    await tester.tap(find.text('遊び方'));
    await tester.pumpAndSettle();
    expect(find.text('目的'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ゲーム開始'));
    await tester.pumpAndSettle();
    expect(find.text('ラウンド 1'), findsOneWidget);
    expect(find.text('プレイヤー1の番'), findsOneWidget);
  });

  test('the computer replies and a whole match reaches a winner', () async {
    final game = GameController(
      mode: GameMode.vsComputer,
      difficulty: Difficulty.medium,
      speed: speedDelays.length - 1,
      random: Random(1),
    );
    var rounds = 0;
    game.onRoundEnd = (_) async => rounds++;

    final rng = Random(2);
    while (!game.state.isFinished) {
      expect(game.state.currentPlayer, Player.one);
      final moves = game.selectableHoles;
      await game.play(moves[rng.nextInt(moves.length)]);
      // Wait for the computer's reply, if it is its turn.
      while (game.busy || game.isComputer(game.state.currentPlayer)) {
        if (game.state.isFinished && !game.busy) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }
    expect(game.state.winner, isNotNull);
    expect(rounds, greaterThan(0));
    expect(game.board, everyElement(0));
  });
}
