import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kebash_engine/kebash_engine.dart';

import 'game_controller.dart';
import 'l10n.dart';
import 'onboarding.dart';
import 'result_screen.dart';
import 'rules_screen.dart';

const _wood = Color(0xFF8D5A2B);
const _pit = Color(0xFF5C3A1A);
const _stone = Color(0xFFF3E9DC);

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode, required this.difficulty});

  final GameMode mode;
  final Difficulty difficulty;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// The first-game hints, in the order they appear.
enum _Tip { none, tapHole, collect }

class _GameScreenState extends State<GameScreen> {
  late final GameController _game =
      GameController(mode: widget.mode, difficulty: widget.difficulty)
        ..onRoundEnd = _showRoundSummary
        ..onMatchEnd = _showResult
        ..addListener(_advanceTip);

  _Tip _tip = _Tip.none;

  @override
  void initState() {
    super.initState();
    Onboarding.isSeen().then((seen) {
      if (!seen && mounted) setState(() => _tip = _Tip.tapHole);
    });
  }

  /// Moves on to the second hint once Player 1's first turn has played out.
  void _advanceTip() {
    if (_tip == _Tip.tapHole &&
        !_game.busy &&
        _game.stats.turns[Player.one.index] > 0) {
      setState(() => _tip = _Tip.collect);
    }
  }

  void _finishTips() {
    setState(() => _tip = _Tip.none);
    Onboarding.markSeen();
  }

  /// The hole the animated hand points at: one Player 1 can play now.
  int? get _hintHole {
    if (_tip != _Tip.tapHole) return null;
    final selectable = _game.selectableHoles;
    if (selectable.isEmpty || _game.state.currentPlayer != Player.one) {
      return null;
    }
    final preferred = holeIndex('A3');
    return selectable.contains(preferred) ? preferred : selectable.first;
  }

  /// Replaces the game, so closing the result returns to the home screen.
  void _showResult() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          mode: widget.mode,
          difficulty: widget.difficulty,
          winner: _game.state.winner!,
          stats: _game.stats,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  String _name(Strings s, Player player) =>
      _game.isComputer(player) ? s.computer : s.player(player);

  Future<void> _showRoundSummary(RoundSummary summary) async {
    // The last round is covered by the result page.
    if (!mounted || summary.winner != null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final s = Strings.of(context);
        final winner = summary.winner;
        final started = summary.started;
        return AlertDialog(
          title: Text(
            winner != null
                ? s.wins(_name(s, winner))
                : s.roundOver(summary.ended.roundNumber),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      const SizedBox(),
                      for (final player in Player.values)
                        _cell(_name(s, player), bold: true),
                    ],
                  ),
                  _row(s.fromBoard, summary.ended.swept),
                  _row(s.available, summary.ended.available),
                  if (started != null) ...[
                    _row(s.openHoles, started.openHoles),
                    _row(s.reserve, started.reserve),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(
                winner != null
                    ? s.cannotOpen(_name(s, winner.opponent))
                    : s.starts(_name(s, started!.starter)),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.continueLabel),
            ),
          ],
        );
      },
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

  Widget _rulesButton(Strings s) => IconButton(
    tooltip: s.howToPlay,
    icon: const Icon(Icons.help_outline),
    onPressed: () => RulesScreen.open(context),
  );

  Widget _speedMenu(Strings s) => PopupMenuButton<int>(
    tooltip: s.speed,
    icon: const Icon(Icons.speed),
    initialValue: _game.speed,
    onSelected: _game.setSpeed,
    itemBuilder: (context) => [
      for (var i = 0; i < speedDelays.length; i++)
        PopupMenuItem(value: i, child: Text(s.speedName(i))),
    ],
  );

  /// Whose turn it is or what is in hand, then the latest collection.
  List<Widget> _status(BuildContext context, Strings s) {
    if (_tip != _Tip.none) {
      final first = _tip == _Tip.tapHole;
      return [
        _TipCard(
          text: first ? s.tutorialTap : s.tutorialCollect,
          action: first ? s.skip : s.gotIt,
          onAction: _finishTips,
        ),
      ];
    }
    final winner = _game.state.winner;
    final collection = _game.lastCollection;
    return [
      Text(
        winner != null
            ? s.wins(_name(s, winner))
            : _game.hand > 0
            ? '${s.inHand}: ${_game.hand}'
            : s.turnOf(_name(s, _game.state.currentPlayer)),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      if (winner != null)
        TextButton(onPressed: _game.restart, child: Text(s.newGame))
      else if (collection != null)
        Text(
          s.collectedBecause(_name(s, collection.player), collection.reason),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
    ];
  }

  Widget _portrait(BuildContext context, Strings s) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _PlayerPanel(game: _game, player: Player.two),
            const SizedBox(height: 12),
            _Board(game: _game, hintHole: _hintHole),
            const SizedBox(height: 12),
            _PlayerPanel(game: _game, player: Player.one),
            const SizedBox(height: 16),
            ConstrainedBox(
              // Keeps the board from jumping as messages come and go.
              constraints: const BoxConstraints(minHeight: 72),
              child: Column(children: _status(context, s)),
            ),
          ],
        ),
      ),
    ),
  );

  /// On a short, wide screen the board takes the full height. Each player's
  /// panel sits beside their own row, with the controls between them.
  Widget _landscape(BuildContext context, Strings s) => Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      children: [
        SizedBox(
          width: 168,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PlayerPanel(game: _game, player: Player.two, compact: true),
              Column(
                children: [
                  Text(
                    s.round(_game.state.roundNumber),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const BackButton(),
                      _rulesButton(s),
                      _speedMenu(s),
                    ],
                  ),
                ],
              ),
              _PlayerPanel(game: _game, player: Player.one, compact: true),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Center(
                    child: SizedBox(
                      width: math.min(
                        box.maxWidth,
                        _Board.widthForHeight(box.maxHeight),
                      ),
                      child: _Board(game: _game, hintHole: _hintHole),
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _status(context, s),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height && size.height < 500;
    return ListenableBuilder(
      listenable: _game,
      builder: (context, _) => Scaffold(
        appBar: landscape
            ? null
            : AppBar(
                title: Text(s.round(_game.state.roundNumber)),
                actions: [_rulesButton(s), _speedMenu(s)],
              ),
        body: SafeArea(
          child: landscape ? _landscape(context, s) : _portrait(context, s),
        ),
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.game,
    required this.player,
    this.compact = false,
  });

  final GameController game;
  final Player player;

  /// Stacks the three lines for the narrow side column in landscape.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final toMove = !game.state.isFinished && game.state.currentPlayer == player;
    final lines = [
      Text(
        game.isComputer(player) ? s.computer : s.player(player),
        style: theme.textTheme.titleMedium,
      ),
      Text('${s.collected}: ${game.collected[player.index]}'),
      Text('${s.reserve}: ${game.state.reserve[player.index]}'),
    ];
    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: toMove
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: toMove ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  DefaultTextStyle.merge(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: line,
                  ),
              ],
            )
          : Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 4,
              children: lines,
            ),
    );
  }
}

/// The board keeps its canonical orientation in every language: Player 2's row
/// on top running B1..B6 left to right, Player 1's row below running A1..A6.
class _Board extends StatelessWidget {
  const _Board({required this.game, this.hintHole});

  final GameController game;

  /// Where the first-game hint's hand points, if anywhere.
  final int? hintHole;

  static const double _padding = 8;
  static const double _middleHeight = 24;

  /// The widest the board can be and still fit in [height].
  static double widthForHeight(double height) =>
      (height - 2 * _padding - _middleHeight - 2) / 2 * holesPerSide +
      2 * _padding +
      2;

  @override
  Widget build(BuildContext context) {
    final selectable = game.selectableHoles;
    Widget row(String letter) => Row(
      children: [
        for (var n = 1; n <= holesPerSide; n++)
          Expanded(
            child: _Hole(
              game: game,
              hole: holeIndex('$letter$n'),
              selectable: selectable.contains(holeIndex('$letter$n')),
              hint: hintHole == holeIndex('$letter$n'),
            ),
          ),
      ],
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          // Lit from the top left, like the pits and stones.
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB07A42), _wood, Color(0xFF6E4420)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x33FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 14,
              offset: Offset(4, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row('B'),
            const SizedBox(
              height: _middleHeight,
              child: Icon(Icons.rotate_right, color: _stone, size: 20),
            ),
            row('A'),
          ],
        ),
      ),
    );
  }
}

class _Hole extends StatelessWidget {
  const _Hole({
    required this.game,
    required this.hole,
    required this.selectable,
    this.hint = false,
  });

  final GameController game;
  final int hole;
  final bool selectable;
  final bool hint;

  @override
  Widget build(BuildContext context) {
    final open = game.state.open[hole];
    final count = game.board[hole];
    final active = game.activeHole == hole;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: AspectRatio(
        aspectRatio: 1,
        child: Semantics(
          button: selectable,
          label: '${holeName(hole)}: ${open ? count : 'closed'}',
          child: GestureDetector(
            key: ValueKey('hole-${holeName(hole)}'),
            onTap: selectable ? () => game.play(hole) : null,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  painter: _HolePainter(
                    count: count,
                    open: open,
                    ring: active
                        ? Colors.amber
                        : selectable
                        ? _stone
                        : null,
                    seed: hole,
                  ),
                ),
                if (open)
                  Align(
                    alignment: Alignment.topRight,
                    child: _CountBadge(count),
                  ),
                if (hint) const _TapHint(key: ValueKey('tap-hint')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A hand that repeatedly taps the hole, with a ripple at each tap.
class _TapHint extends StatefulWidget {
  const _TapHint({super.key});

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest.shortestSide;
          final iconSize = size * 0.75;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              // Approach, press, then rest away from the hole.
              final approach = Curves.easeOut.transform(
                (t / 0.4).clamp(0.0, 1.0),
              );
              final lift = Curves.easeIn.transform(
                ((t - 0.6) / 0.4).clamp(0.0, 1.0),
              );
              final distance = (1 - approach + lift) * size * 0.25;
              final pressed = t > 0.4 && t < 0.55;
              final ripple = ((t - 0.42) / 0.45).clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (ripple > 0 && ripple < 1)
                    Center(
                      child: Container(
                        width: size * (0.3 + 0.9 * ripple),
                        height: size * (0.3 + 0.9 * ripple),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.9 * (1 - ripple),
                            ),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  // The fingertip of the icon sits near its top middle.
                  Positioned(
                    left: size / 2 - iconSize * 0.42 + distance,
                    top: size / 2 - iconSize * 0.08 + distance,
                    child: Transform.scale(
                      scale: pressed ? 0.88 : 1,
                      child: Icon(
                        Icons.touch_app,
                        size: iconSize,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// A first-game hint shown where the turn status normally is.
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
              ),
            ),
            TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: count == 0 ? _wood : _stone,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _pit),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 3,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: ExcludeSemantics(
        child: Text(
          '$count',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: count == 0 ? _stone.withValues(alpha: 0.6) : _pit,
            fontSize: 11,
            height: 1.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Paints one hole with depth: a carved pit (or a filled plug when closed)
/// holding rounded stones. Everything is lit from the top left.
class _HolePainter extends CustomPainter {
  const _HolePainter({
    required this.count,
    required this.open,
    required this.ring,
    required this.seed,
  });

  final int count;
  final bool open;

  /// Outline for the active or selectable hole.
  final Color? ring;

  /// Turns the cluster so neighbouring holes do not look identical.
  final int seed;

  static const _goldenAngle = 2.39996323;
  static const _shades = [
    Color(0xFFF3E9DC),
    Color(0xFFDCC8A8),
    Color(0xFFC9D0D6),
    Color(0xFFE8D2AE),
    Color(0xFFBFB3A4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    if (open) {
      _paintPit(canvas, center, radius, bounds);
      _paintStones(canvas, center, radius);
    } else {
      _paintPlug(canvas, center, radius, bounds);
    }

    final ring = this.ring;
    if (ring != null) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ring;
      canvas
        ..drawCircle(
          center,
          radius - 1.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = ring.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        )
        ..drawCircle(center, radius - 1.5, stroke);
    }
  }

  /// A bowl: the wall nearest the light is in shadow, the far floor is lit.
  void _paintPit(Canvas canvas, Offset center, double radius, Rect bounds) {
    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0.3, 0.4),
            radius: 0.95,
            colors: [Color(0xFF7A4E24), _pit, Color(0xFF2B1A0B)],
            stops: [0, 0.55, 1],
          ).createShader(bounds),
      )
      // Carved rim: dark edge towards the light, bright lip opposite.
      ..drawCircle(
        center,
        radius - radius * 0.03,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.06
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x99000000), Color(0x00000000), Color(0x66FFE0B0)],
          ).createShader(bounds),
      );
  }

  /// A closed hole is filled level with the board and slightly raised.
  void _paintPlug(Canvas canvas, Offset center, double radius, Rect bounds) {
    final plug = radius * 0.8;
    canvas
      ..drawCircle(
        center + Offset(radius * 0.05, radius * 0.08),
        plug,
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.1),
      )
      ..drawCircle(
        center,
        plug,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.35, -0.45),
            colors: [Color(0xFFA9763F), _wood, Color(0xFF6E4420)],
          ).createShader(Rect.fromCircle(center: center, radius: plug)),
      );
  }

  void _paintStones(Canvas canvas, Offset center, double holeRadius) {
    if (count == 0) return;
    final stoneRadius = holeRadius * (0.6 / math.sqrt(count)).clamp(0.1, 0.27);
    final spread = holeRadius - stoneRadius - holeRadius * 0.12;

    for (var i = 0; i < count; i++) {
      final distance = count == 1 ? 0.0 : spread * math.sqrt((i + 0.5) / count);
      final angle = seed + i * _goldenAngle;
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final shade = _shades[(i + seed) % _shades.length];
      canvas
        // Shadow cast away from the light onto the pit floor.
        ..drawCircle(
          position + Offset(stoneRadius * 0.3, stoneRadius * 0.4),
          stoneRadius,
          Paint()
            ..color = const Color(0x88000000)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              stoneRadius * 0.35,
            ),
        )
        // A sphere: bright highlight, body colour, dark far edge.
        ..drawCircle(
          position,
          stoneRadius,
          Paint()
            ..shader =
                RadialGradient(
                  center: const Alignment(-0.4, -0.5),
                  radius: 1.1,
                  colors: [
                    Colors.white,
                    shade,
                    Color.lerp(shade, Colors.black, 0.55)!,
                  ],
                  stops: const [0, 0.4, 1],
                ).createShader(
                  Rect.fromCircle(center: position, radius: stoneRadius),
                ),
        );
    }
  }

  @override
  bool shouldRepaint(_HolePainter old) =>
      old.count != count ||
      old.open != open ||
      old.ring != ring ||
      old.seed != seed;
}
