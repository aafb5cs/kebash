import 'dart:math';

import 'package:kebash_engine/kebash_engine.dart';
import 'package:test/test.dart';

void main() {
  test('replaying a move list reproduces the match exactly', () {
    final rng = Random(11);
    for (var match = 0; match < 10; match++) {
      var state = GameState.initial();
      final moves = <int>[];
      while (!state.isFinished) {
        final legal = legalMoves(state);
        moves.add(legal[rng.nextInt(legal.length)]);
        state = playTurn(state, moves.last).state;

        final replayed = replay(moves);
        expect(fingerprint(replayed), fingerprint(state));
      }
      expect(replay(moves).winner, state.winner);
    }
  });

  test('an illegal move in the list is reported with its position', () {
    final opening = holeIndex('A1');
    final afterOne = playTurn(GameState.initial(), opening).state;
    final ownHoleOfMover = holesOf(afterOne.currentPlayer.opponent).first;
    expect(
      () => replay([opening, ownHoleOfMover]),
      throwsA(
        isA<ReplayException>()
            .having((e) => e.moveIndex, 'moveIndex', 1)
            .having((e) => e.hole, 'hole', ownHoleOfMover),
      ),
    );
  });

  test('different positions give different fingerprints', () {
    final start = GameState.initial();
    final seen = <String>{fingerprint(start)};
    for (final hole in legalMoves(start)) {
      seen.add(fingerprint(playTurn(start, hole).state));
    }
    expect(seen, hasLength(legalMoves(start).length + 1));
    expect(fingerprint(start), matches(RegExp(r'^[0-9a-f]{8}$')));
  });
}
