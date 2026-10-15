import 'package:flutter/material.dart';
import 'package:kebash_engine/kebash_engine.dart';

import 'game_controller.dart';
import 'game_screen.dart';
import 'l10n.dart';

/// Shown in place of the game once a match is over. Closing it returns to the
/// home screen.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.winner,
    required this.stats,
  });

  final GameMode mode;
  final Difficulty difficulty;
  final Player winner;
  final MatchStats stats;

  String _name(Strings s, Player player) =>
      GameController.seatIsComputer(mode, player)
      ? s.computer
      : s.player(player);

  String _pair(List<int> values) => '${values[0]} – ${values[1]}';

  static String _clock(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final loser = winner.opponent;
    final lastRound = stats.rounds.last;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.matchResult),
        leading: IconButton(
          tooltip: s.home,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: theme.colorScheme.primaryContainer,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.wins(_name(s, winner)),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.cannotOpen(_name(s, loser)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mode == GameMode.vsComputer
                              ? '${s.vsComputer} · ${s.difficultyName(difficulty)}'
                              : s.twoPlayers,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, box) {
                    final columns = box.maxWidth > 500 ? 4 : 2;
                    final width = (box.maxWidth - 12 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final tile in [
                          _Tile(s.roundsPlayed, '${stats.rounds.length}'),
                          _Tile(s.turns, '${stats.turns[0] + stats.turns[1]}'),
                          _Tile(s.duration, _clock(stats.duration)),
                          _Tile(
                            s.longestTurn,
                            s.stonesSown(stats.longestTurn),
                            detail: stats.longestTurnBy == null
                                ? null
                                : _name(s, stats.longestTurnBy!),
                          ),
                        ])
                          SizedBox(width: width, child: tile),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Table(
                      columnWidths: const {0: FlexColumnWidth(2)},
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          children: [
                            const SizedBox(),
                            for (final player in Player.values)
                              _cell(_name(s, player), bold: true),
                          ],
                        ),
                        _row(s.turns, stats.turns),
                        _row(s.groupsCollected, stats.groups),
                        _row(s.fromOpponent, stats.groupsFromOpponent),
                        _row(s.finalStones, lastRound.available),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(s.roundByRound, style: theme.textTheme.titleMedium),
                Text(
                  s.pairOrder(_name(s, Player.one), _name(s, Player.two)),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final round in stats.rounds)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${round.number}')),
                      title: Text(
                        '${s.startedBy(_name(s, round.starter))} · '
                        '${s.turns}: ${round.turns}',
                      ),
                      subtitle: Text(
                        '${s.openHoles}: ${_pair(round.openHoles)}\n'
                        '${s.stonesAfter}: ${_pair(round.available)}',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          GameScreen(mode: mode, difficulty: difficulty),
                    ),
                  ),
                  icon: const Icon(Icons.replay),
                  label: Text(s.playAgain),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home),
                  label: Text(s.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _row(String label, List<int> values) => TableRow(
    children: [_cell(label), for (final value in values) _cell('$value')],
  );

  Widget _cell(String text, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    child: Text(
      text,
      style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, {this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // One line each, with the detail line always present, so tiles match.
    Widget line(String text, TextStyle? style) =>
        Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            line(label, theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            line(value, theme.textTheme.titleLarge),
            line(detail ?? '', theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
