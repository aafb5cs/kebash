import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'home_screen.dart';
import 'l10n.dart';

void main() => runApp(const KebashApp());

class KebashApp extends StatefulWidget {
  const KebashApp({super.key, this.initialLocale});

  /// Defaults to the device language when it is supported.
  final Locale? initialLocale;

  @override
  State<KebashApp> createState() => _KebashAppState();
}

class _KebashAppState extends State<KebashApp> {
  late Locale? _locale = widget.initialLocale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => Strings.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: Strings.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8D5A2B)),
      ),
      home: HomeScreen(
        onToggleLanguage: (current) => setState(() {
          _locale = current.languageCode == 'ar'
              ? const Locale('en')
              : const Locale('ar');
        }),
      ),
    );
  }
}
