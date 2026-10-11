import 'dart:math';

import 'package:kebash_engine/kebash_engine.dart';
import 'package:test/test.dart';

/// Builds a mid-round position from hole labels. Holes not listed are empty;
/// [closed] holes are closed. Stones not on the board are split between the
/// two collections so the total is 48.
GameState position(
  Map<String, int> stones, {
  List<String> closed = const [],
  Player toMove = Player.one,
  List<int>? collected,
  List<int> reserve = const [0, 0],
  Player roundStarter = Player.one,
  int roundNumber = 1,
}) {
  final board = List.filled(holeCount, 0);
  stones.forEach((name, count) => board[holeIndex(name)] = count);
  final open = List.filled(holeCount, true);
  for (final name in closed) {
    open[holeIndex(name)] = false;
  }
  final onBoard = board.fold(0, (a, b) => a + b);
  final rest = totalStones - onBoard - reserve[0] - reserve[1];
  return GameState(
    board: board,
    open: open,
    collected: collected ?? [rest ~/ 2, rest - rest ~/ 2],
    reserve: reserve,
    currentPlayer: toMove,
    roundStarter: roundStarter,
    roundNumber: roundNumber,
  );
}

TurnResult play(GameState state, String hole) =>
    playTurn(state, holeIndex(hole));

int at(GameState state, String hole) => state.board[holeIndex(hole)];

int stonesInPlay(GameState s) =>
    s.board.fold(0, (a, b) => a + b) +
    s.collected[0] +
    s.collected[1] +
    s.reserve[0] +
    s.reserve[1];

void main() {
  group('board', () {
    test('clockwise route is B1..B6 then A6..A1', () {
      expect([
        for (var i = 0; i < holeCount; i++) holeName(i),
      ], 'B1 B2 B3 B4 B5 B6 A6 A5 A4 A3 A2 A1'.split(' '));
      for (var i = 0; i < holeCount; i++) {
        expect(holeIndex(holeName(i)), i);
      }
    });

    test('each player closes from their own left: A1 and B6 first', () {
      expect(closedHoles(Player.one, 4).map(holeName), ['A1', 'A2']);
      expect(closedHoles(Player.two, 4).map(holeName), ['B6', 'B5']);
      expect(closedHoles(Player.one, 6), isEmpty);
    });
  });

  group('initial setup', () {
    test('twelve open holes of four, Player 1 starts, nothing collected', () {
      final s = GameState.initial();
      expect(s.board, everyElement(4));
      expect(s.open, everyElement(true));
      expect(s.collected, [0, 0]);
      expect(s.reserve, [0, 0]);
      expect(s.currentPlayer, Player.one);
      expect(s.roundStarter, Player.one);
      expect(s.roundNumber, 1);
      expect(legalMoves(s).map(holeName), ['A6', 'A5', 'A4', 'A3', 'A2', 'A1']);
    });
  });

  group('choosing a hole', () {
    final s = position({'A1': 1, 'A3': 2, 'B2': 3});

    test('rejects opponent, empty and closed holes', () {
      expect(() => play(s, 'B2'), throwsArgumentError);
      expect(() => play(s, 'A2'), throwsArgumentError);
      final closed = position({'A3': 2, 'B2': 3}, closed: ['A1']);
      expect(() => play(closed, 'A1'), throwsArgumentError);
      expect(legalMoves(s).map(holeName), ['A3', 'A1']);
    });
  });

  group('final stone', () {
    test('into an empty hole: one stone stays and the turn ends', () {
      final r = play(position({'A2': 1, 'B3': 5}), 'A2');
      expect(at(r.state, 'A1'), 1);
      expect(at(r.state, 'A2'), 0);
      expect(r.state.currentPlayer, Player.two);
      expect(r.roundEnded, isFalse);
    });

    test(
      'into a hole of three: the mover collects, even from the opponent',
      () {
        final s = position({'A1': 1, 'B1': 3, 'B3': 5}, collected: [20, 19]);
        final r = play(s, 'A1');
        expect(at(r.state, 'B1'), 0);
        expect(r.state.open[holeIndex('B1')], isTrue);
        expect(r.state.collected, [24, 19]);
        expect(r.state.currentPlayer, Player.two);
      },
    );

    test('into a hole of two: relay pickup of three, same turn', () {
      final r = play(position({'A1': 1, 'B1': 2, 'B6': 5}), 'A1');
      expect(at(r.state, 'B1'), 0);
      expect(
        [at(r.state, 'B2'), at(r.state, 'B3'), at(r.state, 'B4')],
        [1, 1, 1],
      );
      expect(
        r.events.whereType<PickedUp>().where((e) => e.isRelay),
        hasLength(1),
      );
      expect(r.state.currentPlayer, Player.two);
    });

    test('into a hole of four: relay pickup of five, nothing collected', () {
      final s = position({'A1': 1, 'B1': 4}, collected: [22, 21]);
      final r = play(s, 'A1');
      expect(at(r.state, 'B1'), 0);
      expect(
        [for (final h in 'B2 B3 B4 B5 B6'.split(' ')) at(r.state, h)],
        [1, 1, 1, 1, 1],
      );
      expect(r.state.collected, [22, 21]);
    });
  });

  group('stones still in hand', () {
    test('a hole reaching four goes to its owner and sowing continues', () {
      final s = position({'A1': 2, 'B1': 3, 'B5': 5}, collected: [19, 19]);
      final r = play(s, 'A1');
      expect(at(r.state, 'B1'), 0);
      expect(at(r.state, 'B2'), 1);
      expect(r.state.collected, [19, 23]);
      final collected = r.events.whereType<Collected>().single;
      expect(collected.player, Player.two);
      expect(collected.reason, CollectReason.ownerDuringSowing);
    });

    test('the mover collects their own hole the same way', () {
      final s = position({'A3': 2, 'A2': 3, 'B5': 5}, collected: [19, 19]);
      final r = play(s, 'A3');
      expect(at(r.state, 'A2'), 0);
      expect(at(r.state, 'A1'), 1);
      expect(r.state.collected, [23, 19]);
    });
  });

  group('route', () {
    test('skips closed holes on both rows', () {
      final p1 = position({'A4': 1, 'B2': 5}, closed: ['A1', 'A2', 'A3']);
      expect(at(play(p1, 'A4').state, 'B1'), 1);

      final p2 = position(
        {'B4': 1, 'A2': 5},
        closed: ['B5', 'B6'],
        toMove: Player.two,
      );
      final r = play(p2, 'B4');
      expect(at(r.state, 'A6'), 1);
      expect(at(r.state, 'B5'), 0);
      expect(at(r.state, 'B6'), 0);
    });

    test('a full lap puts a stone back in the starting hole', () {
      final r = play(position({'A6': 12}), 'A6');
      expect(r.state.board, everyElement(1));
    });
  });

  group('round end', () {
    test('emptying your own side mid-turn does not end the round', () {
      final r = play(position({'A1': 1, 'B1': 2, 'B6': 2}), 'A1');
      expect(r.state.stonesOnSide(Player.one), 0);
      expect(r.roundEnded, isFalse);
      expect(r.state.currentPlayer, Player.two);
      expect(r.state.roundNumber, 1);
    });

    // Example F of the spec with the players swapped.
    final exampleF = position(
      {'A3': 1, 'A4': 7},
      collected: [16, 16],
      reserve: [5, 3],
    );

    test('next player with an empty side ends the round; the other sweeps', () {
      final r = play(exampleF, 'A3');
      expect(r.roundEnded, isTrue);
      final ended = r.events.whereType<RoundEnded>().single;
      expect(ended.swept, [8, 0]);
      expect(ended.available, [29, 19]);
    });

    test('setup: 29 stones open six with five in reserve, 19 open four', () {
      final s = play(exampleF, 'A3').state;
      expect(s.openCount(Player.one), 6);
      expect(s.openCount(Player.two), 4);
      expect(s.reserve, [5, 3]);
      expect(s.collected, [0, 0]);
      expect(
        [for (final h in 'B1 B2 B3 B4 B5 B6'.split(' ')) at(s, h)],
        [4, 4, 4, 4, 0, 0],
      );
      expect(s.open[holeIndex('B5')], isFalse);
      expect(s.open[holeIndex('B6')], isFalse);
      expect(s.stonesOnSide(Player.one), 24);
      expect(stonesInPlay(s), totalStones);
    });

    test('the round starter alternates regardless of who moved last', () {
      final s = play(exampleF, 'A3').state;
      expect(s.roundNumber, 2);
      expect(s.roundStarter, Player.two);
      expect(s.currentPlayer, Player.two);

      final round2 = position(
        {'A3': 1, 'A4': 7},
        collected: [16, 16],
        reserve: [5, 3],
        roundStarter: Player.two,
        roundNumber: 2,
      );
      final next = play(round2, 'A3').state;
      expect(next.roundNumber, 3);
      expect(next.currentPlayer, Player.one);
    });

    test('closed holes reopen when the owner can afford them', () {
      final s = position(
        {'B1': 1, 'B2': 3},
        closed: ['A1', 'A2'],
        toMove: Player.two,
        collected: [23, 21],
      );
      final next = play(s, 'B1').state;
      expect(next.roundNumber, 2);
      expect(next.openCount(Player.one), 5);
      expect(next.open[holeIndex('A1')], isFalse);
      expect(next.open[holeIndex('A2')], isTrue);
      expect(next.reserve, [3, 1]);
    });

    test('collecting mid-round does not reopen holes', () {
      final s = position(
        {'A3': 1, 'B1': 3, 'B4': 5},
        closed: ['A1', 'A2'],
        collected: [20, 19],
      );
      final next = play(s, 'A3').state;
      expect(next.collected[0], 24);
      expect(next.open, s.open);
    });

    test('fewer than four available stones loses the match', () {
      final s = position({'A6': 1}, collected: [44, 3]);
      final r = play(s, 'A6');
      expect(r.state.winner, Player.one);
      expect(r.state.isFinished, isTrue);
      expect(r.events.last, isA<MatchEnded>());
      expect(legalMoves(r.state), isEmpty);
      expect(stonesInPlay(r.state), totalStones);
    });
  });

  group('never-ending relay', () {
    // Nothing ever reaches four here, and the position repeats after 50 relays.
    final s = position(
      {'B1': 1, 'B3': 2, 'B4': 1, 'A2': 2, 'A3': 1, 'A5': 1},
      closed: ['B5', 'B6'],
    );

    test('the looping hole is not a legal move', () {
      expect(legalMoves(s).map(holeName), isNot(contains('A2')));
      expect(legalMoves(s), isNotEmpty);
      expect(() => play(s, 'A2'), throwsArgumentError);
    });
  });

  group('whole matches', () {
    test('every possible round setup gives the starter a legal move', () {
      for (var p1 = 4; p1 <= 44; p1++) {
        for (final starter in Player.values) {
          // Reach the setup through the engine: Player 1 plays the last stone.
          final s = position(
            {'A2': 1},
            collected: [p1 - 1, totalStones - p1],
            roundStarter: starter.opponent,
          );
          final next = play(s, 'A2').state;
          expect(next.currentPlayer, starter);
          expect(legalMoves(next), isNotEmpty);
        }
      }
    });

    test('random matches keep every invariant and reach a winner', () {
      final rng = Random(42);
      for (var match = 0; match < 300; match++) {
        var s = GameState.initial();
        var turns = 0;
        while (!s.isFinished) {
          final moves = legalMoves(s);
          expect(moves, isNotEmpty);
          final r = playTurn(s, moves[rng.nextInt(moves.length)]);
          final before = s;
          s = r.state;

          expect(stonesInPlay(s), totalStones);
          for (var hole = 0; hole < holeCount; hole++) {
            expect(s.board[hole], greaterThanOrEqualTo(0));
            if (!s.open[hole]) expect(s.board[hole], 0);
          }
          if (r.roundEnded) {
            if (!s.isFinished) {
              expect(s.roundNumber, before.roundNumber + 1);
              expect(s.roundStarter, before.roundStarter.opponent);
              for (var hole = 0; hole < holeCount; hole++) {
                expect(s.board[hole], s.open[hole] ? stonesPerHole : 0);
              }
            }
          } else {
            expect(s.open, before.open);
            expect(s.currentPlayer, before.currentPlayer.opponent);
          }
          expect(++turns, lessThan(200000));
        }
        final loser = s.winner!.opponent;
        expect(s.secured(loser), lessThan(stonesPerHole));
      }
    });

    test('events account for every stone moved in a turn', () {
      final rng = Random(7);
      var s = GameState.initial();
      for (var turn = 0; turn < 500 && !s.isFinished; turn++) {
        final moves = legalMoves(s);
        final r = playTurn(s, moves[rng.nextInt(moves.length)]);
        final picked = r.events.whereType<PickedUp>().fold(
          0,
          (a, e) => a + e.count,
        );
        expect(r.events.whereType<Sowed>(), hasLength(picked));
        expect(r.events.whereType<TurnEnded>(), hasLength(1));
        s = r.state;
      }
    });
  });
}
