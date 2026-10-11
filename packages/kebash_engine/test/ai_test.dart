import 'dart:math';

import 'package:kebash_engine/kebash_engine.dart';
import 'package:test/test.dart';

/// Plays one match and returns the winner. Player 1 uses [one], Player 2 [two].
Player playMatch(Difficulty one, Difficulty two, Random rng) {
  var s = GameState.initial();
  while (!s.isFinished) {
    final level = s.currentPlayer == Player.one ? one : two;
    s = playTurn(s, chooseMove(s, level, random: rng)).state;
  }
  return s.winner!;
}

void main() {
  test('every level returns a legal move', () {
    final rng = Random(1);
    for (final level in Difficulty.values) {
      var s = GameState.initial();
      for (var turn = 0; turn < 12 && !s.isFinished; turn++) {
        final move = chooseMove(s, level, random: rng);
        expect(legalMoves(s), contains(move));
        s = playTurn(s, move).state;
      }
    }
  });

  test('the same seed gives the same Easy choices', () {
    List<int> run() {
      final rng = Random(99);
      var s = GameState.initial();
      final moves = <int>[];
      for (var turn = 0; turn < 30 && !s.isFinished; turn++) {
        moves.add(chooseMove(s, Difficulty.easy, random: rng));
        s = playTurn(s, moves.last).state;
      }
      return moves;
    }

    expect(run(), run());
  });

  test('medium takes a free group of four', () {
    final board = List.filled(holeCount, 0);
    board[holeIndex('A1')] = 1;
    board[holeIndex('B1')] = 3;
    board[holeIndex('A4')] = 1;
    board[holeIndex('B4')] = 5;
    final s = GameState(
      board: board,
      open: List.filled(holeCount, true),
      collected: const [19, 19],
      reserve: const [0, 0],
      currentPlayer: Player.one,
      roundStarter: Player.one,
      roundNumber: 1,
    );
    expect(holeName(chooseMove(s, Difficulty.medium)), 'A1');
  });

  test(
    'each level beats the one below it over a set of matches',
    () {
      int wins(Difficulty strong, Difficulty weak, int matches) {
        final rng = Random(5);
        var won = 0;
        for (var i = 0; i < matches; i++) {
          // Alternate seats so first-move advantage cancels out.
          final strongSeat = i.isEven ? Player.one : Player.two;
          final winner = strongSeat == Player.one
              ? playMatch(strong, weak, rng)
              : playMatch(weak, strong, rng);
          if (winner == strongSeat) won++;
        }
        return won;
      }

      expect(wins(Difficulty.medium, Difficulty.easy, 40), greaterThan(30));
      expect(wins(Difficulty.hard, Difficulty.medium, 40), greaterThan(24));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
