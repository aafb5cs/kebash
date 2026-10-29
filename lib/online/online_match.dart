import 'package:kebash_engine/kebash_engine.dart';

/// How long a player has to make each move in a correspondence match.
const Duration turnTimeLimit = Duration(days: 3);

enum MatchStatus { waiting, active, finished }

enum EndReason {
  /// A player could not open a hole.
  normal,
  resigned,

  /// The player to move ran out of time.
  timeout,
}

/// A match between two people on different devices.
///
/// The move list is the source of truth: replaying it gives the position.
/// [toMove] and [fingerprint] are stored alongside so the server can check
/// whose turn it is, and the other device can check that the position agrees.
/// Pairs are indexed by [Player.index].
class OnlineMatch {
  const OnlineMatch({
    required this.id,
    required this.rulesVersion,
    required this.status,
    required this.players,
    required this.names,
    required this.moves,
    required this.toMove,
    required this.fingerprint,
    required this.createdAt,
    required this.updatedAt,
    this.turnDeadline,
    this.winner,
    this.endReason,
    this.inviteCode,
  });

  final String id;
  final int rulesVersion;
  final MatchStatus status;

  /// User id in each seat; null while that seat is empty.
  final List<String?> players;
  final List<String?> names;
  final List<int> moves;
  final Player toMove;
  final String fingerprint;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? turnDeadline;
  final Player? winner;
  final EndReason? endReason;

  /// Set for a match waiting for a particular friend; null for a stranger
  /// match.
  final String? inviteCode;

  /// Which seat [uid] has, or null if they are not in this match.
  Player? seatOf(String uid) {
    for (final player in Player.values) {
      if (players[player.index] == uid) return player;
    }
    return null;
  }

  bool isTurnOf(String uid) =>
      status == MatchStatus.active && players[toMove.index] == uid;

  bool hasTimedOut(DateTime now) =>
      status == MatchStatus.active &&
      turnDeadline != null &&
      now.isAfter(turnDeadline!);

  OnlineMatch copyWith({
    MatchStatus? status,
    List<String?>? players,
    List<String?>? names,
    List<int>? moves,
    Player? toMove,
    String? fingerprint,
    DateTime? updatedAt,
    DateTime? turnDeadline,
    Player? winner,
    EndReason? endReason,
    bool clearInviteCode = false,
  }) => OnlineMatch(
    id: id,
    rulesVersion: rulesVersion,
    status: status ?? this.status,
    players: players ?? this.players,
    names: names ?? this.names,
    moves: moves ?? this.moves,
    toMove: toMove ?? this.toMove,
    fingerprint: fingerprint ?? this.fingerprint,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    turnDeadline: turnDeadline ?? this.turnDeadline,
    winner: winner ?? this.winner,
    endReason: endReason ?? this.endReason,
    inviteCode: clearInviteCode ? null : inviteCode,
  );
}

/// Why a request to change a match was refused.
class MatchRefused implements Exception {
  const MatchRefused(this.reason);
  final String reason;

  @override
  String toString() => 'MatchRefused: $reason';
}

/// The rules for changing a match, shared by every backend so they all accept
/// and refuse exactly the same requests.
abstract final class MatchRules {
  static OnlineMatch create({
    required String id,
    required String uid,
    required String name,
    required DateTime now,
    String? inviteCode,
  }) => OnlineMatch(
    id: id,
    rulesVersion: rulesVersion,
    status: MatchStatus.waiting,
    players: [uid, null],
    names: [name, null],
    moves: const [],
    toMove: Player.one,
    fingerprint: fingerprint(GameState.initial()),
    createdAt: now,
    updatedAt: now,
    inviteCode: inviteCode,
  );

  /// Seats the second player and starts the match. When [joinerFirst] is set
  /// the joiner takes Player 1's seat; callers choose it at random so neither
  /// the creator nor the joiner always gets the same seat.
  static OnlineMatch join(
    OnlineMatch match, {
    required String uid,
    required String name,
    required bool joinerFirst,
    required DateTime now,
  }) {
    if (match.status != MatchStatus.waiting) {
      throw const MatchRefused('This match has already started.');
    }
    final creator = match.players[0]!;
    if (creator == uid) {
      throw const MatchRefused('You cannot join your own match.');
    }
    final creatorName = match.names[0];
    return match.copyWith(
      status: MatchStatus.active,
      players: joinerFirst ? [uid, creator] : [creator, uid],
      names: joinerFirst ? [name, creatorName] : [creatorName, name],
      updatedAt: now,
      turnDeadline: now.add(turnTimeLimit),
      clearInviteCode: true,
    );
  }

  /// Applies move number [moveIndex] by [uid]. The index guards against a
  /// move being sent twice or two moves racing.
  static OnlineMatch move(
    OnlineMatch match, {
    required String uid,
    required int moveIndex,
    required int hole,
    required DateTime now,
  }) {
    if (match.status != MatchStatus.active) {
      throw const MatchRefused('This match is not in progress.');
    }
    if (match.rulesVersion != rulesVersion) {
      throw const MatchRefused('This match uses a different rules version.');
    }
    if (moveIndex != match.moves.length) {
      throw const MatchRefused('This move has already been played.');
    }
    if (!match.isTurnOf(uid)) {
      throw const MatchRefused('It is not your turn.');
    }
    if (match.hasTimedOut(now)) {
      throw const MatchRefused('Your time for this move has run out.');
    }
    final before = replay(match.moves);
    final result = tryTurn(before, hole);
    if (result == null) throw const MatchRefused('That move is not legal.');

    final after = result.state;
    return match.copyWith(
      status: after.isFinished ? MatchStatus.finished : null,
      moves: [...match.moves, hole],
      toMove: after.currentPlayer,
      fingerprint: fingerprint(after),
      updatedAt: now,
      turnDeadline: now.add(turnTimeLimit),
      winner: after.winner,
      endReason: after.isFinished ? EndReason.normal : null,
    );
  }

  static OnlineMatch resign(
    OnlineMatch match, {
    required String uid,
    required DateTime now,
  }) {
    final seat = match.seatOf(uid);
    if (seat == null || match.status != MatchStatus.active) {
      throw const MatchRefused('You cannot resign this match.');
    }
    return match.copyWith(
      status: MatchStatus.finished,
      winner: seat.opponent,
      endReason: EndReason.resigned,
      updatedAt: now,
    );
  }

  /// Lets the waiting player win once the other player's time has run out.
  static OnlineMatch claimTimeout(
    OnlineMatch match, {
    required String uid,
    required DateTime now,
  }) {
    final seat = match.seatOf(uid);
    if (seat == null || match.toMove == seat || !match.hasTimedOut(now)) {
      throw const MatchRefused('The other player still has time.');
    }
    return match.copyWith(
      status: MatchStatus.finished,
      winner: seat,
      endReason: EndReason.timeout,
      updatedAt: now,
    );
  }
}
