import 'board.dart';

/// A position at a turn boundary. Instances are immutable.
class GameState {
  GameState({
    required List<int> board,
    required List<bool> open,
    required List<int> collected,
    required List<int> reserve,
    required this.currentPlayer,
    required this.roundStarter,
    required this.roundNumber,
    this.winner,
  }) : board = List.unmodifiable(board),
       open = List.unmodifiable(open),
       collected = List.unmodifiable(collected),
       reserve = List.unmodifiable(reserve);

  factory GameState.initial() => GameState(
    board: List.filled(holeCount, stonesPerHole),
    open: List.filled(holeCount, true),
    collected: const [0, 0],
    reserve: const [0, 0],
    currentPlayer: Player.one,
    roundStarter: Player.one,
    roundNumber: 1,
  );

  /// Stones per hole, in clockwise index order.
  final List<int> board;
  final List<bool> open;

  /// Stones collected in the current round, indexed by [Player.index].
  final List<int> collected;
  final List<int> reserve;
  final Player currentPlayer;
  final Player roundStarter;
  final int roundNumber;
  final Player? winner;

  bool get isFinished => winner != null;

  int stonesOnSide(Player player) {
    var sum = 0;
    for (final hole in holesOf(player)) {
      sum += board[hole];
    }
    return sum;
  }

  int openCount(Player player) =>
      holesOf(player).where((hole) => open[hole]).length;

  /// Stones the opponent can no longer take this round.
  int secured(Player player) => collected[player.index] + reserve[player.index];
}
