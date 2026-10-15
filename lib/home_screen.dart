import 'package:flutter/material.dart';
import 'package:kebash_engine/kebash_engine.dart';

import 'game_controller.dart';
import 'game_screen.dart';
import 'l10n.dart';
import 'rules_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onLanguageChanged});

  final void Function(Locale locale) onLanguageChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameMode _mode = GameMode.vsComputer;
  Difficulty _difficulty = Difficulty.medium;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.appTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 32),
                  SegmentedButton<GameMode>(
                    segments: [
                      ButtonSegment(
                        value: GameMode.vsComputer,
                        label: Text(s.vsComputer),
                      ),
                      ButtonSegment(
                        value: GameMode.twoPlayers,
                        label: Text(s.twoPlayers),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (value) =>
                        setState(() => _mode = value.single),
                  ),
                  const SizedBox(height: 24),
                  if (_mode == GameMode.vsComputer) ...[
                    Text(s.difficulty, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final level in Difficulty.values)
                          ChoiceChip(
                            label: Text(s.difficultyName(level)),
                            selected: _difficulty == level,
                            onSelected: (_) =>
                                setState(() => _difficulty = level),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            GameScreen(mode: _mode, difficulty: _difficulty),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(s.start),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => RulesScreen.open(context),
                    icon: const Icon(Icons.menu_book),
                    label: Text(s.howToPlay),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: PopupMenuButton<Locale>(
                      tooltip: s.language,
                      initialValue: s.locale,
                      onSelected: widget.onLanguageChanged,
                      itemBuilder: (context) => [
                        for (final locale in Strings.supportedLocales)
                          PopupMenuItem(
                            value: locale,
                            child: Text(
                              Strings.languageNames[locale.languageCode]!,
                            ),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language),
                            const SizedBox(width: 8),
                            Text(
                              Strings.languageNames[s.locale.languageCode] ??
                                  Strings.languageNames['en']!,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
