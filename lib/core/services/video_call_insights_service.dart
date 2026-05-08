import 'dart:convert';
import 'dart:math';

import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/http/http_service.dart';

class VideoCallInsightItem {
  final String title;
  final String description;

  const VideoCallInsightItem({required this.title, required this.description});
}

class VideoCallInsightsResult {
  final String greeting;
  final int mindfulnessScore;
  final List<VideoCallInsightItem> highlights;

  const VideoCallInsightsResult({
    required this.greeting,
    required this.mindfulnessScore,
    required this.highlights,
  });
}

class VideoCallInsightsService {
  final HttpService _httpService;

  VideoCallInsightsService({HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  Future<VideoCallInsightsResult> buildInsights({
    required int consultantId,
    required int durationSeconds,
    required List<Map<String, String>> transcriptTurns,
    required String coachName,
    required String localeCode,
  }) async {
    try {
      final response = await _httpService.post(
        path: AppConstants.videoCallInsightsURL,
        body: {
          'consultantId': consultantId,
          'durationSeconds': durationSeconds,
          'transcriptTurns': transcriptTurns,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final parsed = _parseBackendResponse(
            decoded,
            coachName,
            localeCode,
            transcriptTurns,
            durationSeconds,
          );
          if (parsed != null) return parsed;
        }
      }
    } catch (_) {}

    return _buildFallback(
      coachName: coachName,
      transcriptTurns: transcriptTurns,
      durationSeconds: durationSeconds,
      localeCode: localeCode,
    );
  }

  VideoCallInsightsResult? _parseBackendResponse(
    Map<String, dynamic> json,
    String coachName,
    String localeCode,
    List<Map<String, String>> transcriptTurns,
    int durationSeconds,
  ) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final greeting =
        data['greeting']?.toString() ??
        data['welcomeText']?.toString() ??
        'Gorusme $coachName ile guzel gecti.';

    final scoreRaw =
        data['mindfulnessScore'] ??
        data['awarenessScore'] ??
        data['score'] ??
        data['overallScore'];
    final score = (scoreRaw is num ? scoreRaw.round() : 87).clamp(1, 100);

    final listRaw = data['highlights'] ?? data['insights'] ?? data['topics'];
    final highlights = <VideoCallInsightItem>[];
    if (listRaw is List) {
      for (final item in listRaw) {
        if (item is! Map) continue;
        final title =
            item['title']?.toString() ?? item['name']?.toString() ?? '';
        final description =
            item['description']?.toString() ??
            item['text']?.toString() ??
            item['detail']?.toString() ??
            '';
        if (title.isEmpty || description.isEmpty) continue;
        highlights.add(
          VideoCallInsightItem(title: title, description: description),
        );
      }
    }
    final minCount = 6;
    if (highlights.length < minCount) {
      final fallback = _buildFallback(
        coachName: coachName,
        transcriptTurns: transcriptTurns,
        durationSeconds: durationSeconds,
        localeCode: localeCode,
      );
      final existingTitles = highlights
          .map((e) => e.title.toLowerCase())
          .toSet();
      for (final item in fallback.highlights) {
        if (highlights.length >= minCount) break;
        if (!existingTitles.contains(item.title.toLowerCase())) {
          highlights.add(item);
        }
      }
    }
    if (highlights.isEmpty) return null;

    return VideoCallInsightsResult(
      greeting: greeting,
      mindfulnessScore: score,
      highlights: highlights.take(minCount).toList(),
    );
  }

  VideoCallInsightsResult _buildFallback({
    required String coachName,
    required List<Map<String, String>> transcriptTurns,
    required int durationSeconds,
    required String localeCode,
  }) {
    final userText = transcriptTurns
        .where((e) => (e['role'] ?? '') == 'user')
        .map((e) => e['text'] ?? '')
        .join(' ')
        .toLowerCase();

    int score = 70;
    if (userText.contains('tesekkur') || userText.contains('teşekkür'))
      score += 6;
    if (userText.contains('iyi') || userText.contains('better')) score += 5;
    if (userText.contains('zor') || userText.contains('stres')) score += 4;
    if (durationSeconds >= 45) score += 7;
    if (transcriptTurns.length >= 6) score += 6;
    score = min(99, max(60, score));

    final inferredItems = <VideoCallInsightItem>[];
    final dict = _dictionary(localeCode);
    void addIf(bool ok, String title, String desc) {
      if (ok && inferredItems.length < 6) {
        inferredItems.add(
          VideoCallInsightItem(title: title, description: desc),
        );
      }
    }

    addIf(
      userText.contains('kariyer') ||
          userText.contains('is') ||
          userText.contains('iş'),
      dict.kCareerTitle,
      dict.kCareerDesc,
    );
    addIf(
      userText.contains('stres') ||
          userText.contains('baski') ||
          userText.contains('anksiyete'),
      dict.kStressTitle,
      dict.kStressDesc,
    );
    addIf(
      userText.contains('ozguven') || userText.contains('özgüven'),
      dict.kConfidenceTitle,
      dict.kConfidenceDesc,
    );
    addIf(
      userText.contains('iliski') || userText.contains('aile'),
      dict.kRelationTitle,
      dict.kRelationDesc,
    );
    addIf(
      userText.contains('odak') || userText.contains('motivasyon'),
      dict.kFocusTitle,
      dict.kFocusDesc,
    );

    final fallbackPool = <VideoCallInsightItem>[
      VideoCallInsightItem(
        title: dict.kBoundaryTitle,
        description: dict.kBoundaryDesc,
      ),
      VideoCallInsightItem(
        title: dict.kEmotionalTitle,
        description: dict.kEmotionalDesc,
      ),
      VideoCallInsightItem(
        title: dict.kRoutineTitle,
        description: dict.kRoutineDesc,
      ),
      VideoCallInsightItem(
        title: dict.kCommunicationTitle,
        description: dict.kCommunicationDesc,
      ),
      VideoCallInsightItem(
        title: dict.kDecisionTitle,
        description: dict.kDecisionDesc,
      ),
      VideoCallInsightItem(
        title: dict.kResilienceTitle,
        description: dict.kResilienceDesc,
      ),
    ];

    final existingTitles = inferredItems
        .map((e) => e.title.toLowerCase())
        .toSet();
    for (final item in fallbackPool) {
      if (inferredItems.length >= 6) break;
      if (!existingTitles.contains(item.title.toLowerCase())) {
        inferredItems.add(item);
      }
    }

    while (inferredItems.length < 6) {
      inferredItems.add(
        VideoCallInsightItem(
          title: dict.kGrowthTitle,
          description: dict.kGrowthDesc,
        ),
      );
    }

    return VideoCallInsightsResult(
      greeting: dict.greeting(coachName),
      mindfulnessScore: score,
      highlights: inferredItems.take(6).toList(),
    );
  }

  _InsightDictionary _dictionary(String localeCode) {
    final code = localeCode.toLowerCase();
    if (code.startsWith('tr')) return const _InsightDictionary.tr();
    if (code.startsWith('de')) return const _InsightDictionary.de();
    if (code.startsWith('es')) return const _InsightDictionary.es();
    if (code.startsWith('fr')) return const _InsightDictionary.fr();
    if (code.startsWith('hi')) return const _InsightDictionary.hi();
    if (code.startsWith('it')) return const _InsightDictionary.it();
    if (code.startsWith('ja')) return const _InsightDictionary.ja();
    if (code.startsWith('ko')) return const _InsightDictionary.ko();
    if (code.startsWith('pt')) return const _InsightDictionary.pt();
    if (code.startsWith('ru')) return const _InsightDictionary.ru();
    if (code.startsWith('zh')) return const _InsightDictionary.zh();
    return const _InsightDictionary.en();
  }
}

class _InsightDictionary {
  final String Function(String coachName) greeting;
  final String kCareerTitle;
  final String kCareerDesc;
  final String kStressTitle;
  final String kStressDesc;
  final String kConfidenceTitle;
  final String kConfidenceDesc;
  final String kRelationTitle;
  final String kRelationDesc;
  final String kFocusTitle;
  final String kFocusDesc;
  final String kBoundaryTitle;
  final String kBoundaryDesc;
  final String kEmotionalTitle;
  final String kEmotionalDesc;
  final String kRoutineTitle;
  final String kRoutineDesc;
  final String kCommunicationTitle;
  final String kCommunicationDesc;
  final String kDecisionTitle;
  final String kDecisionDesc;
  final String kResilienceTitle;
  final String kResilienceDesc;
  final String kGrowthTitle;
  final String kGrowthDesc;

  const _InsightDictionary({
    required this.greeting,
    required this.kCareerTitle,
    required this.kCareerDesc,
    required this.kStressTitle,
    required this.kStressDesc,
    required this.kConfidenceTitle,
    required this.kConfidenceDesc,
    required this.kRelationTitle,
    required this.kRelationDesc,
    required this.kFocusTitle,
    required this.kFocusDesc,
    required this.kBoundaryTitle,
    required this.kBoundaryDesc,
    required this.kEmotionalTitle,
    required this.kEmotionalDesc,
    required this.kRoutineTitle,
    required this.kRoutineDesc,
    required this.kCommunicationTitle,
    required this.kCommunicationDesc,
    required this.kDecisionTitle,
    required this.kDecisionDesc,
    required this.kResilienceTitle,
    required this.kResilienceDesc,
    required this.kGrowthTitle,
    required this.kGrowthDesc,
  });

  const _InsightDictionary.tr()
    : greeting = _trGreeting,
      kCareerTitle = 'Kariyer geçişi hazırlığı',
      kCareerDesc =
          'Yeni bir role geçiş sürecinde destek ihtiyacın güçlü biçimde öne çıktı.',
      kStressTitle = 'Stres yönetimi',
      kStressDesc =
          'İş yükü baskısı altında daha sağlıklı sınırlar koymak faydalı olacak.',
      kConfidenceTitle = 'Özgüven geliştirme',
      kConfidenceDesc =
          'Karar verme süreçlerinde daha özgüvenli bir tutum sergileme potansiyelin yüksek.',
      kRelationTitle = 'İlişki iletişimi',
      kRelationDesc =
          'Yakın çevrende duygu ve beklenti ifade etme becerini güçlendirmek iyi gelebilir.',
      kFocusTitle = 'Odak ve motivasyon',
      kFocusDesc =
          'Kısa vadeli hedefler belirlemek günlük ritimde ilerleme hissini artırabilir.',
      kBoundaryTitle = 'Sınır koyma becerisi',
      kBoundaryDesc =
          'Kendi alanını korurken iletişimi sürdürme dengen giderek güçleniyor.',
      kEmotionalTitle = 'Duygusal denge',
      kEmotionalDesc =
          'Konuşma boyunca duyguları adlandırma ve düzenleme becerin olumlu görünüyor.',
      kRoutineTitle = 'Rutin istikrarı',
      kRoutineDesc =
          'Günlük plan ve uyku düzenini netleştirmek zihinsel yükünü azaltabilir.',
      kCommunicationTitle = 'Açık iletişim',
      kCommunicationDesc =
          'İhtiyaçlarını daha doğrudan ifade ettiğinde ilişkilerde rahatlama artabilir.',
      kDecisionTitle = 'Karar netliği',
      kDecisionDesc =
          'Artı-eksi listesi gibi basit araçlarla karar süreçlerini hızlandırabilirsin.',
      kResilienceTitle = 'Psikolojik dayanıklılık',
      kResilienceDesc =
          'Zorlayıcı durumlarda toparlanma hızın güçlü bir kaynak olarak öne çıkıyor.',
      kGrowthTitle = 'Kişisel gelişim alanı',
      kGrowthDesc =
          'Bu görüşmedeki içgörülerle küçük ama istikrarlı adımlar belirgin fark yaratabilir.';

  const _InsightDictionary.en()
    : greeting = _enGreeting,
      kCareerTitle = 'Career transition readiness',
      kCareerDesc =
          'Your need for support during role transitions stood out clearly.',
      kStressTitle = 'Stress management',
      kStressDesc =
          'Building healthier boundaries under workload pressure can be valuable.',
      kConfidenceTitle = 'Confidence building',
      kConfidenceDesc =
          'You show strong potential for a more confident style in decision making.',
      kRelationTitle = 'Relationship communication',
      kRelationDesc =
          'Expressing needs and expectations more openly may improve close relationships.',
      kFocusTitle = 'Focus and motivation',
      kFocusDesc =
          'Short, concrete goals can strengthen your sense of daily progress.',
      kBoundaryTitle = 'Boundary setting',
      kBoundaryDesc =
          'You are improving your balance between protecting your space and staying connected.',
      kEmotionalTitle = 'Emotional balance',
      kEmotionalDesc =
          'Your ability to label and regulate emotions looked noticeably strong.',
      kRoutineTitle = 'Routine stability',
      kRoutineDesc =
          'Clarifying your daily plan and sleep rhythm can reduce mental load.',
      kCommunicationTitle = 'Clear expression',
      kCommunicationDesc =
          'Direct communication of your needs can create relief in conversations.',
      kDecisionTitle = 'Decision clarity',
      kDecisionDesc =
          'Simple tools like pros-cons lists may speed up your decisions.',
      kResilienceTitle = 'Resilience',
      kResilienceDesc =
          'Your recovery speed in challenging moments appears to be a key strength.',
      kGrowthTitle = 'Growth opportunity',
      kGrowthDesc =
          'Small but consistent actions based on these insights can create visible change.';

  const _InsightDictionary.de()
    : greeting = _deGreeting,
      kCareerTitle = 'Vorbereitung auf den Karriereschritt',
      kCareerDesc =
          'Dein Bedarf an Unterstuetzung in der Rollenveraenderung wurde deutlich.',
      kStressTitle = 'Stressmanagement',
      kStressDesc =
          'Gesunde Grenzen unter Arbeitsdruck koennen dir spuerbar helfen.',
      kConfidenceTitle = 'Selbstvertrauen staerken',
      kConfidenceDesc =
          'Bei Entscheidungen hast du Potenzial fuer ein selbstsicheres Auftreten.',
      kRelationTitle = 'Beziehungskommunikation',
      kRelationDesc =
          'Klarere Kommunikation von Erwartungen kann Beziehungen entlasten.',
      kFocusTitle = 'Fokus und Motivation',
      kFocusDesc =
          'Kurze, konkrete Ziele koennen dein taegliches Fortschrittsgefuehl staerken.',
      kBoundaryTitle = 'Grenzen setzen',
      kBoundaryDesc =
          'Du baust eine bessere Balance zwischen Selbstschutz und Naehe auf.',
      kEmotionalTitle = 'Emotionale Balance',
      kEmotionalDesc =
          'Das Benennen und Regulieren deiner Gefuehle wirkte stabil und klar.',
      kRoutineTitle = 'Routinen stabilisieren',
      kRoutineDesc =
          'Mehr Struktur in Tages- und Schlafrhythmus kann mentale Last reduzieren.',
      kCommunicationTitle = 'Klare Ausdrucksweise',
      kCommunicationDesc =
          'Wenn du Beduerfnisse direkter ansprichst, entsteht oft mehr Entlastung.',
      kDecisionTitle = 'Entscheidungsklarheit',
      kDecisionDesc =
          'Einfache Methoden wie Pro-Contra Listen koennen Entscheidungen erleichtern.',
      kResilienceTitle = 'Psychische Resilienz',
      kResilienceDesc =
          'Deine Erholungsfaehigkeit in schwierigen Phasen ist eine starke Ressource.',
      kGrowthTitle = 'Entwicklungsfeld',
      kGrowthDesc =
          'Kleine, konsequente Schritte auf Basis dieser Einsichten koennen viel bewirken.';

  const _InsightDictionary.es()
    : greeting = _esGreeting,
      kCareerTitle = 'Preparacion para transicion profesional',
      kCareerDesc =
          'Se noto claramente tu necesidad de apoyo durante cambios de rol.',
      kStressTitle = 'Gestion del estres',
      kStressDesc =
          'Poner limites mas sanos bajo presion laboral puede ayudarte mucho.',
      kConfidenceTitle = 'Fortalecer la confianza',
      kConfidenceDesc =
          'Muestras buen potencial para decidir con mayor seguridad personal.',
      kRelationTitle = 'Comunicacion en relaciones',
      kRelationDesc =
          'Expresar mejor necesidades y expectativas puede aliviar tus vinculos.',
      kFocusTitle = 'Enfoque y motivacion',
      kFocusDesc =
          'Metas cortas y concretas pueden mejorar tu sensacion de avance diario.',
      kBoundaryTitle = 'Limites personales',
      kBoundaryDesc =
          'Estas mejorando el equilibrio entre cuidarte y mantener cercania.',
      kEmotionalTitle = 'Balance emocional',
      kEmotionalDesc =
          'Tu capacidad para nombrar y regular emociones se vio bastante solida.',
      kRoutineTitle = 'Estabilidad de rutina',
      kRoutineDesc =
          'Ordenar rutina diaria y sueno puede bajar tu carga mental.',
      kCommunicationTitle = 'Expresion clara',
      kCommunicationDesc =
          'Comunicar necesidades de forma directa suele generar mas calma.',
      kDecisionTitle = 'Claridad al decidir',
      kDecisionDesc =
          'Herramientas simples como pros y contras pueden agilizar decisiones.',
      kResilienceTitle = 'Resiliencia',
      kResilienceDesc =
          'Tu recuperacion en momentos exigentes aparece como una gran fortaleza.',
      kGrowthTitle = 'Oportunidad de crecimiento',
      kGrowthDesc =
          'Pasos pequenos pero constantes basados en estos hallazgos pueden crear cambio.';

  const _InsightDictionary.fr()
    : greeting = _frGreeting,
      kCareerTitle = 'Preparation a la transition de carriere',
      kCareerDesc =
          'Ton besoin de soutien pendant un changement de role est apparu clairement.',
      kStressTitle = 'Gestion du stress',
      kStressDesc =
          'Poser des limites plus saines sous pression peut vraiment aider.',
      kConfidenceTitle = 'Confiance en soi',
      kConfidenceDesc =
          'Tu as un bon potentiel pour adopter une posture plus assuree.',
      kRelationTitle = 'Communication relationnelle',
      kRelationDesc =
          'Exprimer besoins et attentes avec clarte peut apaiser tes relations.',
      kFocusTitle = 'Focus et motivation',
      kFocusDesc =
          'Des objectifs courts et concrets renforcent le sentiment de progression.',
      kBoundaryTitle = 'Poser ses limites',
      kBoundaryDesc =
          'Ton equilibre entre protection de soi et lien aux autres se renforce.',
      kEmotionalTitle = 'Equilibre emotionnel',
      kEmotionalDesc =
          'Ta capacite a nommer et reguler tes emotions a semble solide.',
      kRoutineTitle = 'Stabilite des routines',
      kRoutineDesc =
          'Clarifier ton rythme quotidien et le sommeil peut alleger la charge mentale.',
      kCommunicationTitle = 'Expression claire',
      kCommunicationDesc =
          'Parler plus directement de tes besoins peut apporter du soulagement.',
      kDecisionTitle = 'Clarification des decisions',
      kDecisionDesc =
          'Des outils simples comme la liste pour/contre peuvent accelerer tes choix.',
      kResilienceTitle = 'Resilience psychologique',
      kResilienceDesc =
          'Ta vitesse de rebond dans les moments difficiles est une vraie ressource.',
      kGrowthTitle = 'Axe de progression',
      kGrowthDesc =
          'De petites actions regulieres a partir de ces insights peuvent creer un vrai changement.';

  const _InsightDictionary.hi()
    : greeting = _hiGreeting,
      kCareerTitle = 'करियर बदलाव की तैयारी',
      kCareerDesc = 'रोल परिवर्तन के दौरान सहयोग की जरूरत स्पष्ट दिखी।',
      kStressTitle = 'तनाव प्रबंधन',
      kStressDesc =
          'काम के दबाव में स्वस्थ सीमाएं बनाना आपके लिए फायदेमंद होगा।',
      kConfidenceTitle = 'आत्मविश्वास विकास',
      kConfidenceDesc =
          'निर्णय लेने में अधिक आत्मविश्वास दिखाने की क्षमता मजबूत है।',
      kRelationTitle = 'रिश्तों में संवाद',
      kRelationDesc =
          'अपनी जरूरत और अपेक्षाएं स्पष्ट कहना संबंधों को सहज कर सकता है।',
      kFocusTitle = 'फोकस और प्रेरणा',
      kFocusDesc =
          'छोटे और स्पष्ट लक्ष्य रोजमर्रा की प्रगति को मजबूत कर सकते हैं।',
      kBoundaryTitle = 'सीमाएं तय करना',
      kBoundaryDesc =
          'अपने स्पेस की रक्षा और जुड़ाव के बीच संतुलन बेहतर हो रहा है।',
      kEmotionalTitle = 'भावनात्मक संतुलन',
      kEmotionalDesc = 'भावनाओं को पहचानना और संभालना आपकी मजबूत क्षमता दिखी।',
      kRoutineTitle = 'रूटीन स्थिरता',
      kRoutineDesc = 'दैनिक योजना और नींद का ढांचा मानसिक बोझ कम कर सकता है।',
      kCommunicationTitle = 'स्पष्ट अभिव्यक्ति',
      kCommunicationDesc = 'जरूरतें सीधे बताने से बातचीत में राहत बढ़ सकती है।',
      kDecisionTitle = 'निर्णय स्पष्टता',
      kDecisionDesc =
          'प्रो-कॉन जैसी सरल तकनीकें निर्णय प्रक्रिया को तेज कर सकती हैं।',
      kResilienceTitle = 'मनोवैज्ञानिक लचीलापन',
      kResilienceDesc = 'कठिन समय में आपकी वापसी की क्षमता एक बड़ी ताकत है।',
      kGrowthTitle = 'विकास का अवसर',
      kGrowthDesc =
          'इन insights पर छोटे लेकिन लगातार कदम स्पष्ट बदलाव ला सकते हैं।';

  const _InsightDictionary.it()
    : greeting = _itGreeting,
      kCareerTitle = 'Preparazione al cambio di ruolo',
      kCareerDesc =
          'Il bisogno di supporto durante la transizione professionale e emerso chiaramente.',
      kStressTitle = 'Gestione dello stress',
      kStressDesc =
          'Mettere confini piu sani sotto pressione lavorativa puo aiutarti molto.',
      kConfidenceTitle = 'Crescita della fiducia',
      kConfidenceDesc =
          'Hai un buon potenziale per decidere con maggiore sicurezza personale.',
      kRelationTitle = 'Comunicazione relazionale',
      kRelationDesc =
          'Esprimere meglio bisogni e aspettative puo alleggerire le relazioni.',
      kFocusTitle = 'Focus e motivazione',
      kFocusDesc =
          'Obiettivi brevi e concreti possono rafforzare il senso di progresso quotidiano.',
      kBoundaryTitle = 'Definizione dei confini',
      kBoundaryDesc =
          'Stai migliorando l equilibrio tra proteggerti e restare in connessione.',
      kEmotionalTitle = 'Equilibrio emotivo',
      kEmotionalDesc =
          'La tua capacita di riconoscere e regolare emozioni e apparsa solida.',
      kRoutineTitle = 'Stabilita della routine',
      kRoutineDesc =
          'Una routine giornaliera e del sonno piu chiara puo ridurre il carico mentale.',
      kCommunicationTitle = 'Espressione chiara',
      kCommunicationDesc =
          'Comunicare bisogni in modo diretto puo portare maggiore sollievo.',
      kDecisionTitle = 'Chiarezza decisionale',
      kDecisionDesc =
          'Strumenti semplici come pro e contro possono velocizzare le decisioni.',
      kResilienceTitle = 'Resilienza psicologica',
      kResilienceDesc =
          'La tua velocita di recupero nei momenti difficili e una risorsa importante.',
      kGrowthTitle = 'Area di crescita',
      kGrowthDesc =
          'Piccoli passi costanti basati su questi insight possono produrre cambiamenti concreti.';

  const _InsightDictionary.ja()
    : greeting = _jaGreeting,
      kCareerTitle = 'キャリア移行の準備',
      kCareerDesc = '役割の変化において、支援ニーズが明確に見られました。',
      kStressTitle = 'ストレス管理',
      kStressDesc = '業務負荷の中で健全な境界を作ることが有効です。',
      kConfidenceTitle = '自信の強化',
      kConfidenceDesc = '意思決定でより自信を持てる可能性が高く見えます。',
      kRelationTitle = '関係性コミュニケーション',
      kRelationDesc = '期待や要望を率直に伝えることで関係が整いやすくなります。',
      kFocusTitle = '集中とモチベーション',
      kFocusDesc = '短く具体的な目標が日々の前進感を高めます。',
      kBoundaryTitle = '境界設定',
      kBoundaryDesc = '自分を守りながら繋がるバランスが整ってきています。',
      kEmotionalTitle = '感情バランス',
      kEmotionalDesc = '感情を言語化し調整する力が安定していました。',
      kRoutineTitle = '生活リズムの安定',
      kRoutineDesc = '日課と睡眠リズムの整理が心的負荷を減らせます。',
      kCommunicationTitle = '明確な表現',
      kCommunicationDesc = '必要を直接伝えるほど会話の安心感が増します。',
      kDecisionTitle = '意思決定の明確さ',
      kDecisionDesc = 'メリット・デメリット整理が決断を速めます。',
      kResilienceTitle = '心理的レジリエンス',
      kResilienceDesc = '負荷の高い場面での立て直しの速さが強みです。',
      kGrowthTitle = '成長の機会',
      kGrowthDesc = 'この気づきを小さく継続する行動に変えると大きな変化に繋がります。';

  const _InsightDictionary.ko()
    : greeting = _koGreeting,
      kCareerTitle = '커리어 전환 준비',
      kCareerDesc = '역할 전환 과정에서 지원이 필요한 지점이 분명하게 보였습니다.',
      kStressTitle = '스트레스 관리',
      kStressDesc = '업무 압박 상황에서 건강한 경계를 세우는 연습이 도움이 됩니다.',
      kConfidenceTitle = '자기확신 강화',
      kConfidenceDesc = '의사결정에서 더 자신감 있는 태도를 보일 가능성이 높습니다.',
      kRelationTitle = '관계 소통',
      kRelationDesc = '필요와 기대를 더 명확히 표현하면 관계의 긴장이 줄어들 수 있습니다.',
      kFocusTitle = '집중과 동기',
      kFocusDesc = '짧고 구체적인 목표가 일상에서의 전진감을 높여줍니다.',
      kBoundaryTitle = '경계 설정',
      kBoundaryDesc = '자기보호와 관계유지 사이의 균형이 점점 좋아지고 있습니다.',
      kEmotionalTitle = '정서 균형',
      kEmotionalDesc = '감정을 인식하고 조절하는 능력이 안정적으로 드러났습니다.',
      kRoutineTitle = '루틴 안정화',
      kRoutineDesc = '하루 구조와 수면 리듬을 정리하면 정신적 부담이 줄어듭니다.',
      kCommunicationTitle = '명확한 표현',
      kCommunicationDesc = '필요를 직접적으로 말할수록 대화가 편안해질 수 있습니다.',
      kDecisionTitle = '의사결정 명확성',
      kDecisionDesc = '장단점 목록 같은 간단한 도구가 결정을 빠르게 도와줍니다.',
      kResilienceTitle = '심리적 회복탄력성',
      kResilienceDesc = '어려운 상황에서 다시 회복하는 속도가 강점으로 보입니다.',
      kGrowthTitle = '성장 기회',
      kGrowthDesc = '이번 인사이트를 작은 실천으로 이어가면 큰 변화가 가능합니다.';

  const _InsightDictionary.pt()
    : greeting = _ptGreeting,
      kCareerTitle = 'Preparacao para transicao de carreira',
      kCareerDesc =
          'Sua necessidade de apoio em mudancas de papel apareceu com clareza.',
      kStressTitle = 'Gestao do estresse',
      kStressDesc =
          'Definir limites mais saudaveis sob pressao de trabalho pode ajudar muito.',
      kConfidenceTitle = 'Fortalecer confianca',
      kConfidenceDesc =
          'Voce mostra bom potencial para decidir com mais seguranca.',
      kRelationTitle = 'Comunicacao nos relacionamentos',
      kRelationDesc =
          'Expressar necessidades e expectativas com clareza pode aliviar relacoes.',
      kFocusTitle = 'Foco e motivacao',
      kFocusDesc =
          'Metas curtas e concretas podem reforcar o senso de progresso diario.',
      kBoundaryTitle = 'Definicao de limites',
      kBoundaryDesc =
          'Seu equilibrio entre autocuidado e conexao com os outros esta evoluindo.',
      kEmotionalTitle = 'Equilibrio emocional',
      kEmotionalDesc =
          'Sua habilidade de nomear e regular emocoes apareceu bem consistente.',
      kRoutineTitle = 'Estabilidade da rotina',
      kRoutineDesc =
          'Organizar rotina diaria e sono pode reduzir carga mental.',
      kCommunicationTitle = 'Expressao clara',
      kCommunicationDesc =
          'Comunicar necessidades de forma direta tende a trazer mais alivio.',
      kDecisionTitle = 'Clareza nas decisoes',
      kDecisionDesc =
          'Ferramentas simples como lista de prós e contras ajudam a decidir melhor.',
      kResilienceTitle = 'Resiliencia psicologica',
      kResilienceDesc =
          'Sua recuperacao em momentos dificeis se destaca como recurso forte.',
      kGrowthTitle = 'Oportunidade de crescimento',
      kGrowthDesc =
          'Passos pequenos e consistentes com base nestes insights podem gerar grande mudanca.';

  const _InsightDictionary.ru()
    : greeting = _ruGreeting,
      kCareerTitle = 'Готовность к карьерному переходу',
      kCareerDesc =
          'Потребность в поддержке при смене роли проявилась очень ясно.',
      kStressTitle = 'Управление стрессом',
      kStressDesc =
          'Более здоровые границы при рабочем давлении могут заметно помочь.',
      kConfidenceTitle = 'Развитие уверенности',
      kConfidenceDesc =
          'Есть высокий потенциал для более уверенного стиля принятия решений.',
      kRelationTitle = 'Коммуникация в отношениях',
      kRelationDesc =
          'Более открытое выражение ожиданий и потребностей снижает напряжение.',
      kFocusTitle = 'Фокус и мотивация',
      kFocusDesc =
          'Короткие и конкретные цели усиливают ощущение ежедневного прогресса.',
      kBoundaryTitle = 'Личные границы',
      kBoundaryDesc =
          'Баланс между самозащитой и близостью становится более устойчивым.',
      kEmotionalTitle = 'Эмоциональный баланс',
      kEmotionalDesc =
          'Навык распознавать и регулировать эмоции выглядит сильной стороной.',
      kRoutineTitle = 'Стабильность рутины',
      kRoutineDesc =
          'Четкий режим дня и сна может снизить ментальную нагрузку.',
      kCommunicationTitle = 'Ясное выражение',
      kCommunicationDesc =
          'Прямое обозначение своих потребностей часто приносит облегчение.',
      kDecisionTitle = 'Ясность решений',
      kDecisionDesc =
          'Простые инструменты вроде списка плюсов и минусов ускоряют выбор.',
      kResilienceTitle = 'Психологическая устойчивость',
      kResilienceDesc =
          'Скорость восстановления в сложные периоды является вашим ресурсом.',
      kGrowthTitle = 'Зона роста',
      kGrowthDesc =
          'Небольшие, но регулярные шаги по этим инсайтам дадут заметный результат.';

  const _InsightDictionary.zh()
    : greeting = _zhGreeting,
      kCareerTitle = '职业转型准备',
      kCareerDesc = '在角色转换阶段，你对支持的需求表现得很明显。',
      kStressTitle = '压力管理',
      kStressDesc = '在工作压力下建立更健康的边界会很有帮助。',
      kConfidenceTitle = '自信提升',
      kConfidenceDesc = '你在决策中展现出更自信表达的潜力。',
      kRelationTitle = '关系沟通',
      kRelationDesc = '更清晰地表达需求和期待，有助于缓解关系压力。',
      kFocusTitle = '专注与动机',
      kFocusDesc = '短而具体的目标能增强你每天的前进感。',
      kBoundaryTitle = '边界建立',
      kBoundaryDesc = '你在自我保护与保持连接之间的平衡正在变好。',
      kEmotionalTitle = '情绪平衡',
      kEmotionalDesc = '你识别并调节情绪的能力呈现出稳定优势。',
      kRoutineTitle = '作息稳定',
      kRoutineDesc = '梳理日常节奏与睡眠结构可降低心理负担。',
      kCommunicationTitle = '清晰表达',
      kCommunicationDesc = '更直接表达需求，通常会让沟通更轻松。',
      kDecisionTitle = '决策清晰度',
      kDecisionDesc = '用利弊清单等简单工具可提升决策效率。',
      kResilienceTitle = '心理韧性',
      kResilienceDesc = '你在压力情境下的恢复速度是重要优势。',
      kGrowthTitle = '成长机会',
      kGrowthDesc = '把这些洞察转化为小而持续的行动，会带来明显改变。';

  static String _trGreeting(String coachName) =>
      '$coachName ile görüşmen çok iyi geçti!';
  static String _enGreeting(String coachName) =>
      'Your call with $coachName went great!';
  static String _deGreeting(String coachName) =>
      'Dein Gespraech mit $coachName lief richtig gut!';
  static String _esGreeting(String coachName) =>
      'Tu llamada con $coachName fue excelente!';
  static String _frGreeting(String coachName) =>
      'Ton appel avec $coachName s est tres bien passe !';
  static String _hiGreeting(String coachName) =>
      '$coachName के साथ आपकी कॉल बहुत अच्छी रही!';
  static String _itGreeting(String coachName) =>
      'La tua chiamata con $coachName e andata molto bene!';
  static String _jaGreeting(String coachName) => '$coachName との通話はとても良い流れでした！';
  static String _koGreeting(String coachName) => '$coachName 와의 통화가 정말 좋았어요!';
  static String _ptGreeting(String coachName) =>
      'Sua chamada com $coachName foi otima!';
  static String _ruGreeting(String coachName) =>
      'Разговор с $coachName прошел очень хорошо!';
  static String _zhGreeting(String coachName) => '你与 $coachName 的通话进行得很顺利！';
}
