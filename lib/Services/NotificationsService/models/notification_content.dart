/// Notification Content Model
/// Periyodik yerel hatırlatma bildirimlerinin içeriğini tutar.
///
/// İki ilke:
///  1) Her aralık için TEK sabit metin yerine bir mesaj HAVUZU vardır; her
///     gönderimde occurrence index'e göre farklı bir metin seçilir (aynı
///     bildirimin tekrar etmesini önler).
///  2) Metinler kullanıcının diline göre gelir. Uygulamanın desteklediği 12
///     dil burada tanımlıdır; desteklenmeyen kod gelirse İngilizce'ye düşer.
class NotificationContent {
  final String title;
  final String body;
  final String? payload;

  const NotificationContent({
    required this.title,
    required this.body,
    this.payload,
  });

  static const String _title = 'MindCoach';

  /// Uygulamanın desteklediği diller (lib/l10n/*.arb ile aynı).
  static const List<String> supportedLanguages = [
    'en', 'tr', 'de', 'es', 'fr', 'hi', 'it', 'ja', 'ko', 'pt', 'ru', 'zh',
  ];

  /// dil kodu → (aralık saati → mesaj havuzu)
  static const Map<String, Map<int, List<String>>> _localizedBodies = {
    'en': {
      2: [
        'Want to pause and take a breath?',
        'A short break refreshes your mind.',
        'How are you feeling right now?',
        'Take a minute just for yourself.',
        'Relax your shoulders, take a deep breath.',
      ],
      4: [
        'Anything on your mind?',
        'What wore you out today — shall we talk?',
        "We're here if you'd like to open up.",
        "Want to share what's on your mind?",
        "How's your day going?",
      ],
      8: [
        "You don't have to solve everything.",
        'Be a little kinder to yourself.',
        'Even a small step is enough today.',
        "If you're tired, resting is progress too.",
        "It's okay to have off days.",
      ],
      24: [
        'Taking a break is okay…',
        'How did you treat yourself today?',
        'Start the new day gently.',
        'How about picking up where you left off?',
        "We're here for a quick check-in.",
      ],
    },
    'tr': {
      2: [
        'Biraz durup nefes almak ister misin?',
        'Kısa bir mola, zihnini tazeler.',
        'Şu an nasıl hissediyorsun?',
        'Bir dakikanı kendine ayır.',
        'Omuzlarını gevşet, derin bir nefes al.',
      ],
      4: [
        'Zihninde kalan bir şey var mı?',
        'Bugün seni ne yordu, konuşalım mı?',
        'İçini dökmek istersen buradayız.',
        'Aklından geçenleri paylaşmak ister misin?',
        'Gün nasıl gidiyor?',
      ],
      8: [
        'Her şeyi çözmek zorunda değilsin.',
        'Kendine karşı biraz daha nazik ol.',
        'Bugün küçük bir adım bile yeterli.',
        'Yorulduysan dinlenmek de ilerlemektir.',
        'İyi hissetmediğin anlar da normal.',
      ],
      24: [
        'Ara vermen sorun değil…',
        'Bugün kendine nasıl davrandın?',
        'Yeni bir güne yumuşak bir başlangıç yap.',
        'Kaldığın yerden devam etmeye ne dersin?',
        'Küçük bir kontrol için buradayız.',
      ],
    },
    'de': {
      2: [
        'Möchtest du kurz innehalten und durchatmen?',
        'Eine kurze Pause erfrischt deinen Geist.',
        'Wie fühlst du dich gerade?',
        'Nimm dir eine Minute nur für dich.',
        'Entspann die Schultern, atme tief durch.',
      ],
      4: [
        'Beschäftigt dich etwas?',
        'Was hat dich heute erschöpft – reden wir?',
        'Wir sind da, wenn du dich öffnen möchtest.',
        'Möchtest du teilen, was dir durch den Kopf geht?',
        'Wie läuft dein Tag?',
      ],
      8: [
        'Du musst nicht alles lösen.',
        'Sei ein bisschen sanfter zu dir selbst.',
        'Auch ein kleiner Schritt reicht heute.',
        'Wenn du müde bist, ist Ausruhen auch Fortschritt.',
        'Es ist okay, auch mal schlechte Tage zu haben.',
      ],
      24: [
        'Eine Pause ist völlig in Ordnung …',
        'Wie bist du heute mit dir umgegangen?',
        'Beginne den neuen Tag ganz sanft.',
        'Wie wäre es, dort weiterzumachen, wo du aufgehört hast?',
        'Wir sind für ein kurzes Innehalten da.',
      ],
    },
    'es': {
      2: [
        '¿Quieres parar y respirar un momento?',
        'Una pausa corta refresca tu mente.',
        '¿Cómo te sientes ahora mismo?',
        'Tómate un minuto solo para ti.',
        'Relaja los hombros y respira hondo.',
      ],
      4: [
        '¿Tienes algo en la cabeza?',
        '¿Qué te agotó hoy? ¿Hablamos?',
        'Estamos aquí si quieres desahogarte.',
        '¿Quieres compartir lo que piensas?',
        '¿Cómo va tu día?',
      ],
      8: [
        'No tienes que resolverlo todo.',
        'Sé un poco más amable contigo.',
        'Hoy basta con un pequeño paso.',
        'Si estás cansado, descansar también es avanzar.',
        'Está bien tener días malos.',
      ],
      24: [
        'Tomarte un descanso está bien…',
        '¿Cómo te trataste hoy?',
        'Empieza el nuevo día con calma.',
        '¿Qué tal si continúas donde lo dejaste?',
        'Estamos aquí para un breve momento.',
      ],
    },
    'fr': {
      2: [
        'Envie de faire une pause et de respirer ?',
        "Une courte pause rafraîchit l'esprit.",
        'Comment te sens-tu en ce moment ?',
        'Accorde-toi une minute rien que pour toi.',
        'Détends les épaules, respire profondément.',
      ],
      4: [
        'Quelque chose te préoccupe ?',
        "Qu'est-ce qui t'a épuisé aujourd'hui, on en parle ?",
        'Nous sommes là si tu veux te confier.',
        'Envie de partager ce qui te passe par la tête ?',
        'Comment se passe ta journée ?',
      ],
      8: [
        "Tu n'as pas à tout résoudre.",
        'Sois un peu plus doux avec toi-même.',
        "Aujourd'hui, même un petit pas suffit.",
        'Si tu es fatigué, te reposer est aussi un progrès.',
        "C'est normal d'avoir des jours sans.",
      ],
      24: [
        "Faire une pause, c'est très bien…",
        "Comment t'es-tu traité aujourd'hui ?",
        'Commence la nouvelle journée en douceur.',
        "Et si tu reprenais là où tu t'étais arrêté ?",
        'Nous sommes là pour un petit point.',
      ],
    },
    'hi': {
      2: [
        'क्या थोड़ा रुककर साँस लेना चाहेंगे?',
        'एक छोटा ब्रेक आपके मन को तरोताज़ा करता है।',
        'अभी आप कैसा महसूस कर रहे हैं?',
        'एक मिनट सिर्फ़ अपने लिए निकालें।',
        'कंधे ढीले छोड़ें, गहरी साँस लें।',
      ],
      4: [
        'क्या मन में कुछ चल रहा है?',
        'आज किस बात ने थकाया, बात करें?',
        'मन हल्का करना हो तो हम यहाँ हैं।',
        'जो मन में है, साझा करना चाहेंगे?',
        'आपका दिन कैसा जा रहा है?',
      ],
      8: [
        'सब कुछ हल करना ज़रूरी नहीं है।',
        'अपने प्रति थोड़ा और नरम रहें।',
        'आज एक छोटा कदम भी काफ़ी है।',
        'थके हों तो आराम करना भी प्रगति है।',
        'कभी-कभी अच्छा महसूस न होना भी सामान्य है।',
      ],
      24: [
        'ब्रेक लेना कोई बुरी बात नहीं है…',
        'आज आपने खुद के साथ कैसा व्यवहार किया?',
        'नए दिन की शुरुआत सहजता से करें।',
        'जहाँ छोड़ा था, वहीं से जारी रखें?',
        'एक छोटी-सी हालचाल के लिए हम यहाँ हैं।',
      ],
    },
    'it': {
      2: [
        'Vuoi fermarti un attimo e respirare?',
        'Una breve pausa rinfresca la mente.',
        'Come ti senti in questo momento?',
        'Concediti un minuto solo per te.',
        'Rilassa le spalle, fai un respiro profondo.',
      ],
      4: [
        'Hai qualcosa in mente?',
        'Cosa ti ha stancato oggi, ne parliamo?',
        'Siamo qui se vuoi aprirti.',
        'Vuoi condividere ciò che pensi?',
        'Come sta andando la giornata?',
      ],
      8: [
        'Non devi risolvere tutto.',
        'Sii un po\' più gentile con te stesso.',
        'Oggi basta anche un piccolo passo.',
        'Se sei stanco, riposare è anch\'esso un progresso.',
        'È normale avere giornate storte.',
      ],
      24: [
        'Prendersi una pausa va bene…',
        'Come ti sei trattato oggi?',
        'Inizia il nuovo giorno con dolcezza.',
        'Che ne dici di riprendere da dove eri rimasto?',
        'Siamo qui per un piccolo momento insieme.',
      ],
    },
    'ja': {
      2: [
        '少し立ち止まって深呼吸しませんか？',
        '短い休憩は心をリフレッシュします。',
        '今どんな気分ですか？',
        '自分だけの時間を1分とりましょう。',
        '肩の力を抜いて、深く息を吸って。',
      ],
      4: [
        '気にかかっていることはありますか？',
        '今日は何に疲れましたか？話しませんか。',
        '打ち明けたくなったら、ここにいます。',
        '心に浮かんだことを話してみませんか？',
        '今日はどんな一日ですか？',
      ],
      8: [
        'すべてを解決しなくて大丈夫です。',
        '自分にもう少し優しくしてあげて。',
        '今日は小さな一歩でも十分です。',
        '疲れたら、休むことも前進です。',
        'うまくいかない日があっても大丈夫。',
      ],
      24: [
        '休むことは悪いことではありません…',
        '今日は自分にどう接しましたか？',
        '新しい一日を穏やかに始めましょう。',
        '続きから再開してみませんか？',
        'ちょっとした様子うかがいに来ました。',
      ],
    },
    'ko': {
      2: [
        '잠시 멈춰 숨을 고르는 건 어때요?',
        '짧은 휴식이 마음을 새롭게 해줘요.',
        '지금 기분은 어떤가요?',
        '잠깐 자신만을 위한 시간을 가져보세요.',
        '어깨의 힘을 풀고 깊게 숨을 쉬어요.',
      ],
      4: [
        '마음에 걸리는 게 있나요?',
        '오늘 무엇이 힘들었나요? 이야기해요.',
        '털어놓고 싶다면 저희가 있어요.',
        '떠오르는 생각을 나눠볼래요?',
        '오늘 하루는 어떻게 지나가고 있나요?',
      ],
      8: [
        '모든 걸 해결하지 않아도 괜찮아요.',
        '자신에게 조금 더 다정해지세요.',
        '오늘은 작은 한 걸음이면 충분해요.',
        '지쳤다면 쉬는 것도 나아가는 거예요.',
        '기분이 좋지 않은 날도 괜찮아요.',
      ],
      24: [
        '잠시 쉬어가도 괜찮아요…',
        '오늘 자신을 어떻게 대했나요?',
        '새로운 하루를 부드럽게 시작해요.',
        '멈췄던 곳부터 다시 시작해볼까요?',
        '가벼운 안부 차 들렀어요.',
      ],
    },
    'pt': {
      2: [
        'Quer parar um pouco e respirar?',
        'Uma pausa curta refresca a mente.',
        'Como você está se sentindo agora?',
        'Tire um minuto só para você.',
        'Relaxe os ombros e respire fundo.',
      ],
      4: [
        'Tem algo na sua cabeça?',
        'O que te cansou hoje? Vamos conversar?',
        'Estamos aqui se quiser desabafar.',
        'Quer compartilhar o que está pensando?',
        'Como está o seu dia?',
      ],
      8: [
        'Você não precisa resolver tudo.',
        'Seja um pouco mais gentil consigo.',
        'Hoje, um pequeno passo já basta.',
        'Se estiver cansado, descansar também é progredir.',
        'Tudo bem ter dias ruins.',
      ],
      24: [
        'Fazer uma pausa está tudo bem…',
        'Como você se tratou hoje?',
        'Comece o novo dia com calma.',
        'Que tal continuar de onde parou?',
        'Estamos aqui para um breve momento.',
      ],
    },
    'ru': {
      2: [
        'Хотите остановиться и сделать вдох?',
        'Короткая пауза освежает ум.',
        'Как вы себя чувствуете сейчас?',
        'Уделите минутку только себе.',
        'Расслабьте плечи, сделайте глубокий вдох.',
      ],
      4: [
        'Что-то на душе?',
        'Что вас сегодня утомило, поговорим?',
        'Мы рядом, если захотите открыться.',
        'Хотите поделиться тем, что на уме?',
        'Как проходит ваш день?',
      ],
      8: [
        'Необязательно решать всё сразу.',
        'Будьте чуть добрее к себе.',
        'Сегодня достаточно и маленького шага.',
        'Если устали, отдых — это тоже движение вперёд.',
        'Плохие дни — это нормально.',
      ],
      24: [
        'Сделать перерыв — это нормально…',
        'Как вы обошлись с собой сегодня?',
        'Начните новый день спокойно.',
        'Может, продолжим с того места, где остановились?',
        'Мы здесь, чтобы просто узнать, как вы.',
      ],
    },
    'zh': {
      2: [
        '想停下来深呼吸一下吗？',
        '短暂的休息能让头脑焕然一新。',
        '你现在感觉怎么样？',
        '留一分钟给自己。',
        '放松肩膀，深深吸一口气。',
      ],
      4: [
        '有什么心事吗？',
        '今天什么让你疲惫？聊聊好吗？',
        '如果想倾诉，我们都在。',
        '愿意分享你的想法吗？',
        '今天过得怎么样？',
      ],
      8: [
        '你不必解决所有事情。',
        '对自己再温柔一点。',
        '今天迈出一小步就足够了。',
        '累了就休息，休息也是前进。',
        '偶尔状态不好也没关系。',
      ],
      24: [
        '休息一下也没关系……',
        '今天你善待自己了吗？',
        '以平和的心情开始新的一天。',
        '要不要从上次停下的地方继续？',
        '来简单问候一下你。',
      ],
    },
  };

  /// Dil kodunu normalize eder: "en-US" → "en", desteklenmiyorsa "tr".
  static String normalizeLanguage(String? code) {
    if (code == null || code.trim().isEmpty) return 'tr';
    final base = code.toLowerCase().split(RegExp('[-_]')).first;
    return _localizedBodies.containsKey(base) ? base : 'tr';
  }

  static List<String> _poolFor(String lang, int hours) {
    final byLang = _localizedBodies[lang] ?? _localizedBodies['en']!;
    return byLang[hours] ?? byLang[2]!;
  }

  static String? _payloadForInterval(int hours) => 'reminder_${hours}h';

  /// Verilen aralık ve dil için, [occurrence] sırasına göre havuzdan farklı
  /// bir mesaj seçerek içerik döndürür.
  static NotificationContent forInterval(
    int hours, {
    int occurrence = 0,
    String? languageCode,
  }) {
    final lang = normalizeLanguage(languageCode);
    final pool = _poolFor(lang, hours);
    final index = pool.isEmpty ? 0 : (occurrence % pool.length);
    return NotificationContent(
      title: _title,
      body: pool.isEmpty ? 'MindCoach' : pool[index],
      payload: _payloadForInterval(hours),
    );
  }

  /// Bir aralığın havuzundaki toplam mesaj sayısı (dil bağımsız — hepsi eşit).
  static int poolSize(int hours, {String? languageCode}) =>
      _poolFor(normalizeLanguage(languageCode), hours).length;
}
