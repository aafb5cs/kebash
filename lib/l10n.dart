import 'package:flutter/widgets.dart';
import 'package:kebash_engine/kebash_engine.dart';

/// App strings in English and Arabic.
class Strings {
  const Strings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static Strings of(BuildContext context) =>
      Strings(Localizations.localeOf(context));

  bool get _ar => locale.languageCode == 'ar';

  String get appTitle => _ar ? 'كباش' : 'Kebash';
  String get twoPlayers => _ar ? 'لاعبان' : 'Two players';
  String get vsComputer => _ar ? 'ضد الحاسوب' : 'Against the computer';
  String get difficulty => _ar ? 'المستوى' : 'Difficulty';
  String get start => _ar ? 'ابدأ اللعب' : 'Start game';
  String get otherLanguage => _ar ? 'English' : 'العربية';
  String get computer => _ar ? 'الحاسوب' : 'Computer';
  String get collected => _ar ? 'الحصيلة' : 'Collected';
  String get reserve => _ar ? 'الاحتياط' : 'Reserve';
  String get inHand => _ar ? 'في اليد' : 'In hand';
  String get speed => _ar ? 'سرعة الحركة' : 'Animation speed';
  String get newGame => _ar ? 'لعبة جديدة' : 'New game';
  String get continueLabel => _ar ? 'متابعة' : 'Continue';
  String get home => _ar ? 'الرئيسية' : 'Home';
  String get fromBoard => _ar ? 'من اللوح' : 'Taken from board';
  String get available => _ar ? 'المتاح' : 'Available';
  String get openHoles => _ar ? 'الحفر المفتوحة' : 'Open holes';

  String difficultyName(Difficulty level) => switch (level) {
    Difficulty.easy => _ar ? 'سهل' : 'Easy',
    Difficulty.medium => _ar ? 'متوسط' : 'Medium',
    Difficulty.hard => _ar ? 'صعب' : 'Hard',
    Difficulty.expert => _ar ? 'خبير' : 'Expert',
  };

  String speedName(int level) => switch (level) {
    0 => _ar ? 'بطيئة' : 'Slow',
    1 => _ar ? 'عادية' : 'Normal',
    2 => _ar ? 'سريعة' : 'Fast',
    _ => _ar ? 'بدون حركة' : 'No animation',
  };

  String player(Player player) => switch (player) {
    Player.one => _ar ? 'اللاعب 1' : 'Player 1',
    Player.two => _ar ? 'اللاعب 2' : 'Player 2',
  };

  String round(int number) => _ar ? 'الجولة $number' : 'Round $number';
  String turnOf(String name) => _ar ? 'دور $name' : '$name to move';
  String roundOver(int number) =>
      _ar ? 'انتهت الجولة $number' : 'Round $number is over';
  String starts(String name) =>
      _ar ? '$name يبدأ الجولة التالية' : '$name starts the next round';
  String wins(String name) => _ar ? 'فاز $name' : '$name wins';
  String cannotOpen(String name) => _ar
      ? '$name لا يملك أربعة أحجار لفتح حفرة'
      : '$name does not have four stones to open a hole';

  String collectedBecause(String name, CollectReason reason) =>
      switch (reason) {
        CollectReason.ownerDuringSowing =>
          _ar
              ? '$name يجمع 4: اكتملت حفرته أثناء التوزيع'
              : '$name collects 4: their hole reached four during sowing',
        CollectReason.moverFinalStone =>
          _ar
              ? '$name يجمع 4 بآخر حجر'
              : '$name collects 4 with the last stone',
      };
}
