import 'package:flutter/widgets.dart';
import 'package:kebash_engine/kebash_engine.dart';

/// App strings in English, Arabic and Japanese.
class Strings {
  const Strings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ar'), Locale('ja')];

  /// Each language's name, written in that language, for the picker.
  static const languageNames = {'en': 'English', 'ar': 'العربية', 'ja': '日本語'};

  static Strings of(BuildContext context) =>
      Strings(Localizations.localeOf(context));

  /// Picks the text for the current language; English is the fallback.
  T _t<T>(T en, T ar, T ja) => switch (locale.languageCode) {
    'ar' => ar,
    'ja' => ja,
    _ => en,
  };

  String get appTitle => _t('Kebash', 'كباش', 'ケバシュ');
  String get twoPlayers => _t('Two players', 'لاعبان', '2人で対戦');
  String get vsComputer =>
      _t('Against the computer', 'ضد الحاسوب', 'コンピューターと対戦');
  String get difficulty => _t('Difficulty', 'المستوى', '難易度');
  String get start => _t('Start game', 'ابدأ اللعب', 'ゲーム開始');
  String get language => _t('Language', 'اللغة', '言語');
  String get computer => _t('Computer', 'الحاسوب', 'コンピューター');
  String get collected => _t('Collected', 'الحصيلة', '獲得');
  String get reserve => _t('Reserve', 'الاحتياط', '予備');
  String get inHand => _t('In hand', 'في اليد', '手持ち');
  String get speed => _t('Animation speed', 'سرعة الحركة', 'アニメーション速度');
  String get newGame => _t('New game', 'لعبة جديدة', '新しいゲーム');
  String get continueLabel => _t('Continue', 'متابعة', '続ける');
  String get home => _t('Home', 'الرئيسية', 'ホーム');
  String get fromBoard => _t('Taken from board', 'من اللوح', '盤から回収');
  String get available => _t('Available', 'المتاح', '持ち石');
  String get openHoles => _t('Open holes', 'الحفر المفتوحة', '開く穴');

  String difficultyName(Difficulty level) => switch (level) {
    Difficulty.easy => _t('Easy', 'سهل', 'かんたん'),
    Difficulty.medium => _t('Medium', 'متوسط', 'ふつう'),
    Difficulty.hard => _t('Hard', 'صعب', 'むずかしい'),
    Difficulty.expert => _t('Expert', 'خبير', 'エキスパート'),
  };

  String speedName(int level) => switch (level) {
    0 => _t('Slow', 'بطيئة', '遅い'),
    1 => _t('Normal', 'عادية', '普通'),
    2 => _t('Fast', 'سريعة', '速い'),
    _ => _t('No animation', 'بدون حركة', 'アニメーションなし'),
  };

  String player(Player player) => switch (player) {
    Player.one => _t('Player 1', 'اللاعب 1', 'プレイヤー1'),
    Player.two => _t('Player 2', 'اللاعب 2', 'プレイヤー2'),
  };

  String round(int number) =>
      _t('Round $number', 'الجولة $number', 'ラウンド $number');
  String turnOf(String name) => _t('$name to move', 'دور $name', '$nameの番');
  String roundOver(int number) =>
      _t('Round $number is over', 'انتهت الجولة $number', 'ラウンド $number 終了');
  String starts(String name) => _t(
    '$name starts the next round',
    '$name يبدأ الجولة التالية',
    '次のラウンドは$nameから',
  );
  String wins(String name) => _t('$name wins', 'فاز $name', '$nameの勝ち');
  String cannotOpen(String name) => _t(
    '$name does not have four stones to open a hole',
    '$name لا يملك أربعة أحجار لفتح حفرة',
    '$nameは穴を開けるための石が4個ありません',
  );

  String collectedBecause(String name, CollectReason reason) =>
      switch (reason) {
        CollectReason.ownerDuringSowing => _t(
          '$name collects 4: their hole reached four during sowing',
          '$name يجمع 4: اكتملت حفرته أثناء التوزيع',
          '$nameが4個獲得：配っている途中で自分の穴が4個になりました',
        ),
        CollectReason.moverFinalStone => _t(
          '$name collects 4 with the last stone',
          '$name يجمع 4 بآخر حجر',
          '$nameが最後の石で4個獲得',
        ),
      };

  String get matchResult => _t('Match result', 'نتيجة المباراة', '試合結果');
  String get roundsPlayed => _t('Rounds', 'الجولات', 'ラウンド数');
  String get turns => _t('Turns', 'الأدوار', '手数');
  String get duration => _t('Time', 'المدة', '時間');
  String get longestTurn => _t('Longest turn', 'أطول دور', '最長の手');
  String get groupsCollected =>
      _t('Groups of four collected', 'مجموعات الأربعة', '獲得した4個の組');
  String get fromOpponent =>
      _t('Taken from the opponent', 'من حفر الخصم', '相手の穴から');
  String get finalStones =>
      _t('Stones at the end', 'الأحجار في النهاية', '最後の石数');
  String get roundByRound =>
      _t('Round by round', 'الجولات بالتفصيل', 'ラウンドごとの記録');
  String get stonesAfter => _t('Stones after', 'الأحجار بعدها', '終了時の石');
  String get playAgain => _t('Play again', 'العب مجددًا', 'もう一度遊ぶ');
  String stonesSown(int count) =>
      _t('$count stones', 'أحجار: $count', '$count個');
  String startedBy(String name) =>
      _t('Started by $name', 'بدأها $name', '$nameが先手');
  String pairOrder(String first, String second) => _t(
    'Pairs show $first – $second',
    'الأرقام بترتيب $first – $second',
    '数字は $first – $second の順',
  );

  String get tutorialTap => _t(
    'Your row is at the bottom. Tap an outlined hole to pick up its stones '
        'and sow them.',
    'صفّك في الأسفل. اضغط حفرة محاطة بإطار لترفع أحجارها وتوزعها.',
    'あなたの列は下側です。枠のある穴をタップすると、石を取って配ります。',
  );
  String get tutorialCollect => _t(
    'Stones travel clockwise. If your last stone makes exactly four, you '
        'collect them.',
    'تتحرك الأحجار مع عقارب الساعة. إذا جعل آخر حجر الحفرة أربعة، تجمعها أنت.',
    '石は時計回りに進みます。最後の石でちょうど4個になったら、その4個を獲得できます。',
  );
  String get gotIt => _t('Got it', 'فهمت', 'わかった');
  String get skip => _t('Skip', 'تخطَّ', 'スキップ');
  String get showHintsAgain => _t(
    'Show the first-game hints again',
    'أظهر تلميحات أول لعبة مجددًا',
    '最初のヒントをもう一度表示',
  );
  String get hintsWillShow => _t(
    'The hints will show in your next game.',
    'ستظهر التلميحات في لعبتك القادمة.',
    '次のゲームでヒントが表示されます。',
  );

  String get howToPlay => _t('How to play', 'طريقة اللعب', '遊び方');

  /// Rule sections as (title, points), in the order a new player needs them.
  List<(String, List<String>)> get rules => _t(_rulesEn, _rulesAr, _rulesJa);

  static const _rulesEn = [
    (
      'Goal',
      [
        'Leave your opponent with fewer than four stones at the start of a '
            'round, so they cannot open a single hole.',
      ],
    ),
    (
      'The board',
      [
        'Two rows of six holes. The bottom row belongs to Player 1, the top '
            'row to Player 2.',
        'Every hole starts with four stones, so each player has 24.',
        'Stones always travel clockwise, as the arrow in the middle shows.',
      ],
    ),
    (
      'Your turn',
      [
        'Tap one of your own holes that has stones. Playable holes are '
            'outlined.',
        'All its stones are picked up and dropped one by one into the next '
            'holes, going clockwise.',
        'Closed holes are skipped.',
      ],
    ),
    (
      'Making four while sowing',
      [
        'If a hole reaches exactly four while you still hold stones, its '
            'owner takes the four, even if that is your opponent.',
      ],
    ),
    (
      'Where the last stone lands',
      [
        'In an empty hole: it stays there and your turn ends.',
        'It makes four: you take those four, whoever owns the hole, and your '
            'turn ends.',
        'Any other number: pick up every stone in that hole and keep sowing. '
            'It is still your turn.',
      ],
    ),
    (
      'End of a round',
      [
        'When it is a player\'s turn and their row is empty, the round ends.',
        'The other player takes every stone left in their own row.',
      ],
    ),
    (
      'The next round',
      [
        'Each player fills their holes with the stones they have, four per '
            'hole, up to six holes.',
        'Holes you cannot fill are closed, starting from your left. Leftover '
            'stones stay in your reserve.',
        'Closed holes stay closed for the whole round and can reopen next '
            'round.',
        'Players take turns starting each round.',
      ],
    ),
    (
      'Winning',
      [
        'A player with fewer than four stones at the start of a round cannot '
            'open a hole and loses the match.',
      ],
    ),
    (
      'On the screen',
      [
        'The number at the corner of a hole is how many stones it holds.',
        'The gold ring shows where the stone is being dropped right now.',
        'A move that would send stones around forever is not allowed, so '
            'that hole is not outlined.',
      ],
    ),
  ];

  static const _rulesAr = [
    (
      'الهدف',
      ['اترك خصمك بأقل من أربعة أحجار في بداية جولة، فلا يستطيع فتح أي حفرة.'],
    ),
    (
      'اللوح',
      [
        'صفّان من ست حفر. الصف السفلي للاعب 1 والصف العلوي للاعب 2.',
        'تبدأ كل حفرة بأربعة أحجار، أي 24 حجرًا لكل لاعب.',
        'تتحرك الأحجار دائمًا مع عقارب الساعة كما يشير السهم في وسط اللوح.',
      ],
    ),
    (
      'دورك',
      [
        'اضغط حفرة من صفّك فيها أحجار. الحفر المتاحة محاطة بإطار.',
        'تُرفع كل أحجارها ويوضع حجر واحد في كل حفرة تالية مع عقارب الساعة.',
        'الحفر المغلقة تُتخطّى.',
      ],
    ),
    (
      'تكوين أربعة أثناء التوزيع',
      [
        'إذا وصلت حفرة إلى أربعة أحجار بالضبط وما زال في يدك أحجار، يأخذها '
            'صاحب الحفرة، حتى لو كان خصمك.',
      ],
    ),
    (
      'أين يقع آخر حجر',
      [
        'في حفرة فارغة: يبقى فيها وينتهي دورك.',
        'إذا جعل الحفرة أربعة: تأخذ الأربعة أنت، أيًّا كان صاحب الحفرة، '
            'وينتهي دورك.',
        'أي عدد آخر: ارفع كل أحجار تلك الحفرة وتابع التوزيع، وما زال الدور '
            'دورك.',
      ],
    ),
    (
      'نهاية الجولة',
      [
        'إذا جاء دور لاعب وصفّه فارغ تمامًا، تنتهي الجولة.',
        'يأخذ اللاعب الآخر كل الأحجار الباقية في صفّه.',
      ],
    ),
    (
      'الجولة التالية',
      [
        'يملأ كل لاعب حفره بما لديه من أحجار، أربعة في كل حفرة وحتى ست حفر.',
        'الحفر التي لا تستطيع ملأها تُغلق بدءًا من يسارك، وما يتبقى من أحجار '
            'يبقى في احتياطك.',
        'تبقى الحفر المغلقة مغلقة طوال الجولة، ويمكن أن تُفتح في الجولة '
            'التالية.',
        'يتناوب اللاعبان على بدء الجولات.',
      ],
    ),
    (
      'الفوز',
      [
        'من يملك أقل من أربعة أحجار في بداية جولة لا يستطيع فتح حفرة ويخسر '
            'المباراة.',
      ],
    ),
    (
      'على الشاشة',
      [
        'الرقم في زاوية الحفرة هو عدد أحجارها.',
        'الحلقة الذهبية تُظهر مكان وضع الحجر الآن.',
        'الحركة التي تجعل الأحجار تدور بلا نهاية غير مسموحة، فلا تظهر حفرتها '
            'محاطة بإطار.',
      ],
    ),
  ];

  static const _rulesJa = [
    ('目的', ['ラウンド開始時に相手の石を4個未満にして、穴を1つも開けられないようにしましょう。']),
    (
      '盤',
      [
        '6つの穴が2列あります。下の列がプレイヤー1、上の列がプレイヤー2のものです。',
        '最初は各穴に4個ずつ石が入っていて、各プレイヤーの石は24個です。',
        '石は常に時計回りに進みます。盤の中央の矢印が向きを示しています。',
      ],
    ),
    (
      '自分の番',
      [
        '石が入っている自分の穴を1つタップします。選べる穴は枠で囲まれています。',
        'その穴の石をすべて取り、時計回りに次の穴から1個ずつ入れていきます。',
        '閉じた穴は飛ばします。',
      ],
    ),
    (
      '配っている途中で4個になったら',
      ['まだ手に石が残っているときに、ある穴の石がちょうど4個になったら、その穴の持ち主が4個を獲得します。相手の穴でも同じです。'],
    ),
    (
      '最後の石が入った穴',
      [
        '空の穴：石はそのまま残り、番が終わります。',
        '4個になった：穴の持ち主に関係なく、あなたが4個を獲得し、番が終わります。',
        'それ以外の数：その穴の石をすべて取り、続けて配ります。まだあなたの番です。',
      ],
    ),
    (
      'ラウンドの終わり',
      [
        '番が来たプレイヤーの列に石が1個もなければ、ラウンドが終わります。',
        'もう一方のプレイヤーは、自分の列に残っている石をすべて獲得します。',
      ],
    ),
    (
      '次のラウンド',
      [
        '各プレイヤーは持っている石を穴に4個ずつ入れます。開けられる穴は最大6つです。',
        '埋められない穴は自分から見て左側から閉じます。余った石は予備になります。',
        '閉じた穴はそのラウンドの間ずっと閉じたままで、次のラウンドで再び開くことがあります。',
        'ラウンドを始めるプレイヤーは交互に替わります。',
      ],
    ),
    ('勝ち負け', ['ラウンド開始時に石が4個未満のプレイヤーは穴を開けられず、負けになります。']),
    (
      '画面の見方',
      [
        '穴の角の数字は、その穴に入っている石の数です。',
        '金色の輪は、いま石が置かれている穴を示します。',
        '石が永遠に回り続ける手は選べないため、その穴は枠で囲まれません。',
      ],
    ),
  ];
}
