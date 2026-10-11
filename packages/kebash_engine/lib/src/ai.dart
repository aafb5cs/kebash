import 'dart:math';

import 'board.dart';
import 'engine.dart';
import 'game_state.dart';

enum Difficulty { easy, medium, hard, expert }

const int _winScore = 1000000;
const int _infinity = 1 << 30;

// Search limits, to be tuned by playtesting.
const double _easyGreedyChance = 0.3;
const int _hardDepth = 5;
const int _expertMaxDepth = 14;
const int _expertNodeBudget = 150000;

/// Picks a hole for the current player. Pass a seeded [random] for
/// reproducible choices.
int chooseMove(GameState state, Difficulty difficulty, {Random? random}) {
  final rng = random ?? Random();
  final moves = legalMoves(state)..shuffle(rng);
  if (moves.isEmpty) throw StateError('No legal move');
  if (moves.length == 1) return moves.first;

  switch (difficulty) {
    case Difficulty.easy:
      if (rng.nextDouble() >= _easyGreedyChance) return moves.first;
      return _bestMove(state, moves, 1, _Budget(_infinity))!;
    case Difficulty.medium:
      return _bestMove(state, moves, 1, _Budget(_infinity))!;
    case Difficulty.hard:
      return _bestMove(state, moves, _hardDepth, _Budget(_infinity))!;
    case Difficulty.expert:
      // Iterative deepening: keep the answer from the deepest finished pass.
      final budget = _Budget(_expertNodeBudget);
      var best = moves.first;
      for (var depth = 1; depth <= _expertMaxDepth; depth++) {
        final move = _bestMove(state, moves, depth, budget);
        if (move == null) break;
        best = move;
        // Try the previous best first so deeper passes prune more.
        moves
          ..remove(best)
          ..insert(0, best);
      }
      return best;
  }
}

class _Budget {
  _Budget(this.nodes);
  int nodes;
}

class _OutOfBudget implements Exception {
  const _OutOfBudget();
}

/// Returns the best of [moves] at [depth] turns, or null if the budget ran out.
int? _bestMove(GameState state, List<int> moves, int depth, _Budget budget) {
  try {
    int? best;
    var alpha = -_infinity;
    for (final move in moves) {
      final score = _scoreMove(state, move, depth, alpha, _infinity, budget);
      if (score != null && score > alpha) {
        alpha = score;
        best = move;
      }
    }
    return best;
  } on _OutOfBudget {
    return null;
  }
}

/// Score of playing [hole], from the mover's point of view. Null if illegal.
int? _scoreMove(
  GameState state,
  int hole,
  int depth,
  int alpha,
  int beta,
  _Budget budget,
) {
  final result = tryTurn(state, hole);
  if (result == null) return null;
  if (--budget.nodes < 0) throw const _OutOfBudget();

  final mover = state.currentPlayer;
  final next = result.state;
  if (next.isFinished) {
    // Prefer quicker wins and slower losses.
    return next.winner == mover ? _winScore + depth : -_winScore - depth;
  }
  // A round end is a search leaf: the new setup is scored exactly.
  if (result.roundEnded) return _evaluate(next, mover, freshSetup: true);
  if (depth <= 1) return _evaluate(next, mover, freshSetup: false);

  var best = -_infinity;
  var replyAlpha = -beta;
  for (final reply in holesOf(next.currentPlayer)) {
    final score = _scoreMove(
      next,
      reply,
      depth - 1,
      replyAlpha,
      -alpha,
      budget,
    );
    if (score == null) continue;
    if (score > best) best = score;
    if (best > replyAlpha) replyAlpha = best;
    if (replyAlpha >= -alpha) break;
  }
  return -best;
}

/// Secured stones count in full; stones still on a player's side count for a
/// quarter because either player may yet take them. On a fresh setup nothing
/// is at stake yet, so board stones count in full too.
int _evaluate(GameState state, Player player, {required bool freshSetup}) {
  final boardWeight = freshSetup ? 4 : 1;
  int value(Player p) =>
      4 * state.secured(p) + boardWeight * state.stonesOnSide(p);
  return value(player) - value(player.opponent);
}
