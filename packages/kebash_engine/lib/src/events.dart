import 'board.dart';

/// Why a player received stones.
enum CollectReason {
  /// A hole reached four while the mover still held stones; its owner collects.
  ownerDuringSowing,

  /// The mover's final stone made four; the mover collects.
  moverFinalStone,
}

/// Something that happened during a turn, in order. The UI animates these
/// instead of re-implementing the rules.
sealed class GameEvent {
  const GameEvent();
}

class PickedUp extends GameEvent {
  const PickedUp(this.hole, this.count, {required this.isRelay});
  final int hole;
  final int count;
  final bool isRelay;
}

class Sowed extends GameEvent {
  const Sowed(this.hole, this.countAfter, this.handAfter);
  final int hole;
  final int countAfter;
  final int handAfter;
}

class Collected extends GameEvent {
  const Collected(this.hole, this.player, this.count, this.reason);
  final int hole;
  final Player player;
  final int count;
  final CollectReason reason;
}

class TurnEnded extends GameEvent {
  const TurnEnded(this.mover, this.lastHole);
  final Player mover;
  final int lastHole;
}

/// The round is over. Lists are indexed by [Player.index].
class RoundEnded extends GameEvent {
  const RoundEnded(this.roundNumber, this.swept, this.available);
  final int roundNumber;

  /// Stones each player took from their own side in the cleanup.
  final List<int> swept;
  final List<int> available;
}

class RoundStarted extends GameEvent {
  const RoundStarted(
    this.roundNumber,
    this.starter,
    this.openHoles,
    this.reserve,
  );
  final int roundNumber;
  final Player starter;
  final List<int> openHoles;
  final List<int> reserve;
}

class MatchEnded extends GameEvent {
  const MatchEnded(this.winner);
  final Player winner;
}
