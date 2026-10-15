import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:kebash_engine/kebash_engine.dart';

enum GameMode { twoPlayers, vsComputer }

/// What the round summary shows once a round is over.
class RoundSummary {
  const RoundSummary(this.ended, this.started, this.winner);
  final RoundEnded ended;

  /// Null when the match is over.
  final RoundStarted? started;
  final Player? winner;
}

/// One round as it was played. Pairs are indexed by [Player.index].
class RoundRecord {
  RoundRecord(this.number, this.starter, this.openHoles);

  final int number;
  final Player starter;
  final List<int> openHoles;
  int turns = 0;

  /// Stones each player had once the round was over.
  List<int> available = const [0, 0];
}

/// Running totals for the result page. Pairs are indexed by [Player.index].
class MatchStats {
  MatchStats({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      startedAt = (clock ?? DateTime.now)();

  final DateTime Function() _clock;
  final DateTime startedAt;
  DateTime? finishedAt;

  final rounds = [
    RoundRecord(1, Player.one, const [holesPerSide, holesPerSide]),
  ];
  final turns = [0, 0];

  /// Groups of four each player collected during play, not counting cleanup.
  final groups = [0, 0];

  /// The part of [groups] taken from the other player's holes.
  final groupsFromOpponent = [0, 0];

  /// Most stones sown in a single turn, relays included.
  int longestTurn = 0;
  Player? longestTurnBy;

  Duration get duration => (finishedAt ?? _clock()).difference(startedAt);

  void record(Player mover, List<GameEvent> events) {
    turns[mover.index]++;
    rounds.last.turns++;
    var sown = 0;
    for (final event in events) {
      switch (event) {
        case Sowed():
          sown++;
        case Collected():
          groups[event.player.index]++;
          if (ownerOf(event.hole) != event.player) {
            groupsFromOpponent[event.player.index]++;
          }
        case RoundEnded():
          rounds.last.available = event.available;
        case RoundStarted():
          rounds.add(
            RoundRecord(event.roundNumber, event.starter, event.openHoles),
          );
        case MatchEnded():
          finishedAt = _clock();
        case PickedUp() || TurnEnded():
          break;
      }
    }
    if (sown > longestTurn) {
      longestTurn = sown;
      longestTurnBy = mover;
    }
  }
}

/// Step delays for the animation speed levels; the last one skips animation.
const List<Duration> speedDelays = [
  Duration(milliseconds: 600),
  Duration(milliseconds: 300),
  Duration(milliseconds: 120),
  Duration.zero,
];

/// Runs a match and replays each turn's engine events one step at a time.
///
/// [state] is the real position. The `board`, `collected` and `hand` fields are
/// what the screen shows, which lags behind while a turn is animating.
class GameController extends ChangeNotifier {
  GameController({
    required this.mode,
    this.difficulty = Difficulty.medium,
    this.speed = 1,
    Random? random,
  }) : _random = random ?? Random() {
    _showState();
  }

  final GameMode mode;
  final Difficulty difficulty;
  final Random _random;

  /// The computer always plays the top row.
  static const Player computerSeat = Player.two;

  /// Index into [speedDelays].
  int speed;

  /// Called when a round ends; the animation waits for it to complete.
  Future<void> Function(RoundSummary summary)? onRoundEnd;

  /// Called once the last turn of the match has finished animating.
  VoidCallback? onMatchEnd;

  MatchStats stats = MatchStats();

  GameState state = GameState.initial();
  List<int> board = const [];
  List<int> collected = const [];
  int hand = 0;
  int? activeHole;
  Collected? lastCollection;
  bool busy = false;
  bool _disposed = false;

  bool isComputer(Player player) => seatIsComputer(mode, player);

  static bool seatIsComputer(GameMode mode, Player player) =>
      mode == GameMode.vsComputer && player == computerSeat;

  /// Holes the person at the device may tap right now.
  List<int> get selectableHoles =>
      busy || isComputer(state.currentPlayer) ? const [] : legalMoves(state);

  void setSpeed(int value) {
    speed = value;
    notifyListeners();
  }

  void restart() {
    if (busy) return;
    state = GameState.initial();
    stats = MatchStats();
    lastCollection = null;
    _showState();
    notifyListeners();
  }

  Future<void> play(int hole) async {
    if (busy || !legalMoves(state).contains(hole)) return;
    busy = true;
    lastCollection = null;
    final result = playTurn(state, hole);
    stats.record(state.currentPlayer, result.events);

    for (final event in result.events) {
      switch (event) {
        case PickedUp():
          board[event.hole] = 0;
          hand = event.count;
          activeHole = event.hole;
        case Sowed():
          board[event.hole] = event.countAfter;
          hand = event.handAfter;
          activeHole = event.hole;
        case Collected():
          board[event.hole] = 0;
          collected[event.player.index] += event.count;
          lastCollection = event;
        case TurnEnded():
          activeHole = null;
        case RoundEnded():
          board = List.filled(holeCount, 0);
          for (final player in Player.values) {
            collected[player.index] += event.swept[player.index];
          }
          notifyListeners();
          await onRoundEnd?.call(
            RoundSummary(
              event,
              result.events.whereType<RoundStarted>().firstOrNull,
              result.state.winner,
            ),
          );
          continue;
        case RoundStarted() || MatchEnded():
          continue;
      }
      if (_disposed) return;
      notifyListeners();
      if (speedDelays[speed] > Duration.zero) {
        await Future<void>.delayed(speedDelays[speed]);
      }
    }
    if (_disposed) return;

    state = result.state;
    _showState();
    busy = false;
    notifyListeners();
    if (state.isFinished) {
      onMatchEnd?.call();
    } else {
      unawaited(playComputerTurn());
    }
  }

  /// Makes the computer's move if it is the computer's turn.
  Future<void> playComputerTurn() async {
    if (busy || state.isFinished || !isComputer(state.currentPlayer)) return;
    // Let the board repaint before the search blocks the UI thread.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_disposed || busy) return;
    await play(chooseMove(state, difficulty, random: _random));
  }

  void _showState() {
    board = List.of(state.board);
    collected = List.of(state.collected);
    hand = 0;
    activeHole = null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
