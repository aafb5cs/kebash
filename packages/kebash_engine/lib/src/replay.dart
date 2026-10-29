import 'engine.dart';
import 'game_state.dart';

/// Version of the rules a stored move list was played under. Bump it whenever
/// a rule change could make an existing move list replay differently, so
/// matches in progress keep the rules they started with.
const int rulesVersion = 1;

/// Thrown when a stored move list contains a move that is not legal.
class ReplayException implements Exception {
  const ReplayException(this.moveIndex, this.hole);

  /// Zero-based position of the bad move in the list.
  final int moveIndex;
  final int hole;

  @override
  String toString() => 'Move $moveIndex (hole $hole) is not legal';
}

/// Rebuilds a match from the start by playing [moves] in order. A match is
/// fully described by its move list, because the rules have no randomness.
GameState replay(Iterable<int> moves) {
  var state = GameState.initial();
  var index = 0;
  for (final hole in moves) {
    final result = tryTurn(state, hole);
    if (result == null) throw ReplayException(index, hole);
    state = result.state;
    index++;
  }
  return state;
}

/// A short, stable fingerprint of [state], so two devices can confirm they
/// reached the same position without exchanging it. It is the same on every
/// platform, including the web.
String fingerprint(GameState state) {
  // 32-bit FNV-1a over every field that affects play.
  var hash = 0x811c9dc5;
  void add(int value) {
    hash ^= value & 0xff;
    hash = (hash * 0x01000193) & 0xffffffff;
  }

  for (final count in state.board) {
    add(count);
  }
  for (final open in state.open) {
    add(open ? 1 : 0);
  }
  for (final value in [...state.collected, ...state.reserve]) {
    add(value);
  }
  add(state.currentPlayer.index);
  add(state.roundStarter.index);
  add(state.roundNumber);
  add(state.roundNumber >> 8);
  add(state.winner == null ? 2 : state.winner!.index);
  return hash.toRadixString(16).padLeft(8, '0');
}
