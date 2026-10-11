// Measures AI strength and thinking time: dart run tool/bench.dart
import 'dart:math';

import 'package:kebash_engine/kebash_engine.dart';

void main() {
  final rng = Random(3);
  void duel(Difficulty a, Difficulty b, int matches) {
    var aWins = 0, seatOneWins = 0, turns = 0, rounds = 0;
    final slowest = {a: 0, b: 0};
    final clock = Stopwatch();
    for (var i = 0; i < matches; i++) {
      final aSeat = i.isEven ? Player.one : Player.two;
      var s = GameState.initial();
      while (!s.isFinished) {
        final level = s.currentPlayer == aSeat ? a : b;
        clock
          ..reset()
          ..start();
        final move = chooseMove(s, level, random: rng);
        if (clock.elapsedMilliseconds > slowest[level]!) {
          slowest[level] = clock.elapsedMilliseconds;
        }
        s = playTurn(s, move).state;
        turns++;
      }
      rounds += s.roundNumber;
      if (s.winner == aSeat) aWins++;
      if (s.winner == Player.one) seatOneWins++;
    }
    print(
      '${a.name} vs ${b.name}: ${a.name} won $aWins/$matches, '
      'Player 1 seat won $seatOneWins, avg ${rounds ~/ matches} rounds, '
      '${turns ~/ matches} turns, slowest move ${slowest[a]} ms / ${slowest[b]} ms',
    );
  }

  duel(Difficulty.medium, Difficulty.easy, 200);
  duel(Difficulty.hard, Difficulty.medium, 200);
  duel(Difficulty.expert, Difficulty.hard, 60);
  duel(Difficulty.hard, Difficulty.hard, 200);
}
