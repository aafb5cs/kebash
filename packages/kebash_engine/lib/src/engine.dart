import 'board.dart';
import 'events.dart';
import 'game_state.dart';

class TurnResult {
  const TurnResult(this.state, this.events, {required this.roundEnded});

  /// The position at the next turn boundary, after any round cleanup and setup.
  final GameState state;

  /// Empty unless events were requested.
  final List<GameEvent> events;
  final bool roundEnded;
}

/// Holes the current player may choose: nonempty open holes on their own side
/// whose turn terminates. A move that would relay forever is not legal.
List<int> legalMoves(GameState state) => [
  if (!state.isFinished)
    for (final hole in holesOf(state.currentPlayer))
      if (_sow(state, hole, null) != null) hole,
];

/// Plays the complete turn starting at [hole] and returns its events.
TurnResult playTurn(GameState state, int hole) {
  final result = tryTurn(state, hole, withEvents: true);
  if (result == null) {
    throw ArgumentError.value(hole, 'hole', 'Not a legal move');
  }
  return result;
}

/// Like [playTurn], but returns null when the move is not legal. Skips event
/// recording unless [withEvents] is set, which keeps AI search cheap.
TurnResult? tryTurn(GameState state, int hole, {bool withEvents = false}) {
  if (state.isFinished) return null;
  final events = withEvents ? <GameEvent>[] : null;
  final sown = _sow(state, hole, events);
  if (sown == null) return null;

  final mover = state.currentPlayer;
  final next = GameState(
    board: sown.board,
    open: state.open,
    collected: sown.collected,
    reserve: state.reserve,
    currentPlayer: mover.opponent,
    roundStarter: state.roundStarter,
    roundNumber: state.roundNumber,
  );
  if (_hasLegalMove(next)) {
    return TurnResult(next, events ?? const [], roundEnded: false);
  }
  return TurnResult(
    _finishRound(next, events),
    events ?? const [],
    roundEnded: true,
  );
}

class _Sown {
  _Sown(this.board, this.collected);
  final List<int> board;
  final List<int> collected;
}

/// Distributes from [hole] until the turn ends. Returns null if the hole
/// cannot be chosen or the relay never terminates.
_Sown? _sow(GameState state, int hole, List<GameEvent>? events) {
  final mover = state.currentPlayer;
  if (hole < 0 || hole >= holeCount) return null;
  if (ownerOf(hole) != mover || !state.open[hole] || state.board[hole] == 0) {
    return null;
  }

  final board = List<int>.of(state.board);
  final collected = List<int>.of(state.collected);
  // Positions seen at relay pickups since the last collection. A repeat means
  // the turn would cycle forever, because sowing is deterministic.
  final seen = <String>{};

  var hand = board[hole];
  board[hole] = 0;
  var pos = hole;
  events?.add(PickedUp(hole, hand, isRelay: false));

  while (true) {
    pos = nextOpenHole(state.open, pos);
    board[pos]++;
    hand--;
    events?.add(Sowed(pos, board[pos], hand));

    if (hand > 0) {
      if (board[pos] == stonesPerHole) {
        final owner = ownerOf(pos);
        collected[owner.index] += stonesPerHole;
        board[pos] = 0;
        seen.clear();
        events?.add(
          Collected(pos, owner, stonesPerHole, CollectReason.ownerDuringSowing),
        );
      }
      continue;
    }

    if (board[pos] == stonesPerHole) {
      collected[mover.index] += stonesPerHole;
      board[pos] = 0;
      events?.add(
        Collected(pos, mover, stonesPerHole, CollectReason.moverFinalStone),
      );
      break;
    }
    if (board[pos] == 1) break;

    if (!seen.add(String.fromCharCodes([...board, pos]))) return null;
    hand = board[pos];
    board[pos] = 0;
    events?.add(PickedUp(pos, hand, isRelay: true));
  }

  events?.add(TurnEnded(mover, pos));
  return _Sown(board, collected);
}

bool _hasLegalMove(GameState state) {
  for (final hole in holesOf(state.currentPlayer)) {
    if (_sow(state, hole, null) != null) return true;
  }
  return false;
}

/// Sweeps the board, then either ends the match or sets up the next round.
///
/// Each player takes the stones left on their own side. Normally the player to
/// move has none, so only the other player collects.
GameState _finishRound(GameState state, List<GameEvent>? events) {
  final swept = [
    for (final player in Player.values) state.stonesOnSide(player),
  ];
  final available = [
    for (final player in Player.values)
      state.secured(player) + swept[player.index],
  ];
  events?.add(RoundEnded(state.roundNumber, swept, available));

  for (final player in Player.values) {
    if (available[player.index] < stonesPerHole) {
      events?.add(MatchEnded(player.opponent));
      return GameState(
        board: List.filled(holeCount, 0),
        open: state.open,
        collected: [
          for (final p in Player.values)
            state.collected[p.index] + swept[p.index],
        ],
        reserve: state.reserve,
        currentPlayer: state.currentPlayer,
        roundStarter: state.roundStarter,
        roundNumber: state.roundNumber,
        winner: player.opponent,
      );
    }
  }

  final board = List.filled(holeCount, 0);
  final open = List.filled(holeCount, false);
  final openHoles = <int>[];
  final reserve = <int>[];
  for (final player in Player.values) {
    final stones = available[player.index];
    final count = stones ~/ stonesPerHole < holesPerSide
        ? stones ~/ stonesPerHole
        : holesPerSide;
    openHoles.add(count);
    reserve.add(stones - count * stonesPerHole);
    final closed = closedHoles(player, count);
    for (final hole in holesOf(player)) {
      if (closed.contains(hole)) continue;
      open[hole] = true;
      board[hole] = stonesPerHole;
    }
  }
  final starter = state.roundStarter.opponent;
  events?.add(RoundStarted(state.roundNumber + 1, starter, openHoles, reserve));
  return GameState(
    board: board,
    open: open,
    collected: const [0, 0],
    reserve: reserve,
    currentPlayer: starter,
    roundStarter: starter,
    roundNumber: state.roundNumber + 1,
  );
}
