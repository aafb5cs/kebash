/// Board geometry. Holes are indexed 0..11 in clockwise order:
/// 0..5 are B1..B6 (Player 2), 6..11 are A6..A1 (Player 1).
library;

enum Player {
  one,
  two;

  Player get opponent => this == one ? two : one;
}

const int holeCount = 12;
const int holesPerSide = 6;
const int stonesPerHole = 4;
const int totalStones = 48;

Player ownerOf(int hole) => hole < holesPerSide ? Player.two : Player.one;

/// Canonical label, e.g. `A1` or `B6`.
String holeName(int hole) =>
    hole < holesPerSide ? 'B${hole + 1}' : 'A${holeCount - hole}';

int holeIndex(String name) {
  final n = int.parse(name.substring(1));
  if (n < 1 || n > holesPerSide) throw ArgumentError.value(name, 'name');
  return switch (name[0]) {
    'A' => holeCount - n,
    'B' => n - 1,
    _ => throw ArgumentError.value(name, 'name'),
  };
}

/// The player's holes in clockwise order.
List<int> holesOf(Player player) => player == Player.two
    ? const [0, 1, 2, 3, 4, 5]
    : const [6, 7, 8, 9, 10, 11];

/// Holes closed when [player] can open only [openCount] holes. Each player
/// closes from their own left as they sit: A1, A2, ... and B6, B5, ...
List<int> closedHoles(Player player, int openCount) => [
  for (var k = 0; k < holesPerSide - openCount; k++)
    player == Player.one ? holeCount - 1 - k : holesPerSide - 1 - k,
];

int nextOpenHole(List<bool> open, int from) {
  var pos = (from + 1) % holeCount;
  while (!open[pos]) {
    pos = (pos + 1) % holeCount;
  }
  return pos;
}
