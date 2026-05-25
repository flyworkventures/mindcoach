import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart' as pcm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mindcoach/Riverpod/Providers/premium_provider.dart'
    as AllProviders;
import 'package:mindcoach/Services/Analytics/analytics_service.dart';
import 'package:mindcoach/Services/TrialQuotaService/trial_quota_service.dart';
import 'package:mindcoach/core/analytics/analytics_events.dart';
import 'package:mindcoach/Services/rive_preload_service.dart';
import 'package:mindcoach/View/specialists_screen/specialists_notifier.dart';
import 'package:mindcoach/View/chat_screen/conversation/video_call/video_call_trial_insights_screen.dart';
import 'package:mindcoach/core/locale/locale_provider.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/call_permissions.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/core/utils/realtime_auth_token.dart';
import 'package:mindcoach/core/utils/revenuecat_paywalls.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/http/http_service.dart';
import 'package:mindcoach/models/consultant_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:rive/rive.dart' as rive;

enum _CallState { connecting, listening, thinking, speaking, error }

class _AudioChunk {
  final Uint8List bytes;
  final int durationMs;
  _AudioChunk(this.bytes, this.durationMs);
}

class VideoCallRealtimeScreen extends ConsumerStatefulWidget {
  final ConsultantModel specialist;

  /// Onboarding deneme akisi: 1 dk limiti baglanti kurulunca baslar.
  final bool isTrial;

  const VideoCallRealtimeScreen({
    super.key,
    required this.specialist,
    this.isTrial = false,
  });

  @override
  ConsumerState<VideoCallRealtimeScreen> createState() =>
      _VideoCallRealtimeScreenState();
}

class _VideoCallRealtimeScreenState
    extends ConsumerState<VideoCallRealtimeScreen> {
  WebSocket? _ws;
  StreamSubscription? _wsSub;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSub;
  bool _micStreamActive = false;

  static const int _sampleRate = 24000;
  static const int _channels = 1;
  // PCM playback ring — chunked Int16List queue.
  // Eski Queue<int> her sample için boxed int allocation yapıyordu;
  // 24k sample/sn × ~25 chunk/sn = 600k allocation/sn = ana CPU bottleneck.
  // Yeni yapı: gelen her PCM mesajı tek Int16List olarak enqueue edilir,
  // feed sırasında ön taraftan offset ile okunur (zero-allocation).
  final Queue<Int16List> _pcmChunks = Queue<Int16List>();
  int _pcmChunkOffset = 0;
  int _pcmTotalSamples = 0;
  bool _pcmSetup = false;
  bool _pcmStarted = false;

  _CallState _callState = _CallState.connecting;
  bool _isMuted = false;
  // Çağrı açılışı için iki ön-koşul:
  //   • Rive avatar dosyası yüklendi (_onRiveLoaded fired)
  //   • Sunucu connection_success gönderdi (WebSocket hazır)
  // İkisi de tamamlanmadan listening state'e geçilmiyor, kamera açılmıyor.
  bool _riveReady = false;
  bool _serverConnectionReady = false;
  bool _callOpenFinalized = false;

  /// Görüntülü görüşmede çıkış her zaman hoparlör (iOS/Android route + barge-in eşiği).
  static const bool _isSpeakerOn = true;
  Timer? _timer;
  int _secondsElapsed = 0;

  Timer? _trialTimer;
  bool _trialDialogShown = false;
  bool _trialExpired = false;

  /// Bağlantı kurulduğunda kalan ücretsiz görüntülü saniye (TrialQuotaService).
  int _videoTrialBudgetSeconds = 60;
  bool _videoTrialUsagePersisted = false;

  /// ai_response_complete gelmezse speaking'de kalınır; ikinci kullanıcı turunda mic kesilir.
  Timer? _aiSpeakingWatchdog;

  /// Son AI PCM baytının geldiği an — akış kesilince [ai_response_complete] olmadan dinlemeye dönüş.
  DateTime? _lastAiPcmReceivedAt;
  Timer? _aiPlaybackIdleTimer;
  Timer? _connectionReadyFallbackTimer;

  /// Sunucu chunk'ları arasında 1-2 sn boşluk olabiliyor (TTS buffering).
  /// 900 ms ile erken drain → ses ortada kesiliyordu.
  static const int _aiPlaybackIdleMs = 2800;

  /// Aynı anda yalnızca bir drain/listen akışı (idle watchdog + ai_response_complete yarışı).
  bool _pcmDrainInFlight = false;

  /// Bu AI turunda en az bir PCM byte geldiyse true ([ai_speaking_start] sıfırlar).
  bool _receivedAiPcmThisTurn = false;

  /// [flutter_pcm_sound] OnFeedSamples: kuyruk boşalınca `remaining_frames == 0`
  /// olana kadar beklenir — aksi halde son ~0.5 sn ses hoparlörde kesiliyordu.
  Completer<void>? _nativePcmDrainedCompleter;

  static const int _bargeInSustainedMs = 160;
  static const int _preRollMaxMs = 500;
  static const int _postSpeechCooldownMs = 180;

  /// Native drain tamamlandıktan sonra DAC / route için kısa tampon (ms).
  static const int _pcmPostNativeDrainPadMs = 40;

  /// Server hazır olsa bile [connection_success] henüz client'a gelmediyse
  /// arada gelmiş [ai_speaking_start] event'i kuyrukta tutulur, finalize
  /// anında uygulanır.
  bool _aiSpeakingStartPending = false;

  /// Ağız açılış blend'i (konuşma başlangıcı).
  static const double _riveTalkOpenBlendMs = 40;

  /// Konuşma bittiğinde talk=false öncesi kısa blend — uzun süre bırakılınca
  /// Rive ~1 sn "takılı" kalıyordu.
  static const double _riveTalkCloseBlendMs = 26;

  /// Viseme şekil geçişi (ms).
  static const double _riveVisemeBlendMs = 24;

  /// Server timeline'dan ardışık viseme'ler arasında zorunlu minimum aralık.
  /// 63ms = saniyede ~16 değişim.
  static const int _visemeTimelineMinGapMs = 63;
  /// Server timeline gecikme ölçeği.
  /// Eski videocall_view.dart'ta frame.time direkt kullanılıyordu (1.0).
  /// Agresif sıkıştırma frame'leri Rive blend süresinden hızlı tetikliyor
  /// ve ağız donmuş gibi görünüyordu — server zamanlamasını koruyoruz.
  static const double _visemeTimelineDelayScale = 1.0;

  /// RMS'ten viseme uygulama throttle'ı. 63ms = saniyede ~16 update.
  static const int _realtimeVisemeDebounceMs = 63;

  /// PCM chunk içi RMS penceresi (ms). 40ms'de saniyede ~25 örnek →
  /// throttle ile birlikte ağız hareketi sakin ve kontrollü.
  static const int _visemeRmsWindowMs = 40;
  static const int _bargeInMinAiSpeakingMs = 450;
  static const int _bargeInRmsThresholdEarpiece = 2200;
  static const int _bargeInRmsThresholdSpeaker = 3200;
  int _highRmsStreakMs = 0;
  bool _bargeInSent = false;
  final Queue<_AudioChunk> _preRoll = Queue<_AudioChunk>();
  DateTime? _micGateOpenAt;
  DateTime? _aiSpeakingSince;
  int _lastPlaybackRms = 0;

  late rive.FileLoader _riveFileLoader;
  int _riveLoaderKey = 0;
  dynamic _riveController;
  dynamic _riveViewModel;
  // StateMachine input fallback (used when the .riv file has no ViewModel)
  rive.BooleanInput? _smTalk;
  rive.NumberInput? _smVisemeNum;
  rive.NumberInput? _smDuration;
  // True only when actual audio is playing (first PCM feed with rms>threshold).
  // Prevents mouth opening before audio arrives.
  bool _riveAudioActive = false;
  // Exponentially smoothed RMS — fallback when no phoneme timeline is active.
  // Klasik audio envelope follower: attack hızlı, release yavaş — sesin
  // amplitüdü ani düştüğünde ağız hemen kapanmasın, doğal sönsün.
  double _rmsSmoothed = 0.0;
  int _visemeApplied = 0;
  DateTime? _visemeAppliedAt;
  /// Force-close sonrası kısa lockout: backend silent-tail PCM chunk'ları
  /// yolluyorsa ağız hemen tekrar açılmasın diye 400ms boyunca düşük RMS
  /// re-open'larını yoksay.
  DateTime? _forceCloseLockedUntil;
  static const int _forceCloseLockoutMs = 400;
  static const int _forceCloseLockoutRmsOverride = 600;

  /// Son anlamlı konuşma RMS'inin alındığı zaman. Backend silent-tail PCM
  /// yollamaya devam etse bile (queue boşalmadan), bu zaman üzerinden
  /// 180ms geçtiyse ağzı zorla kapat. Native kuyruk drain'ini beklemek
  /// "ağız bittikten sonra oynuyor" sorununu doğuruyordu.
  DateTime? _lastSpeechRmsAt;
  static const int _speechRmsThreshold = 250;
  static const int _silenceCloseAfterMs = 180;
  Timer? _realtimeVisemeApplyTimer;
  int _pendingRealtimeVisemeId = 0;
  // Phoneme-based timeline timers (from server Rhubarb map).
  // When active, RMS-based updates are suppressed.
  final List<Timer> _visemeTimers = [];
  bool _visemeTimelineActive = false;
  Map<String, dynamic>? _pendingVisemeTimelineMsg;

  /// Son viseme timeline timer'ından gelen güncelleme (RMS ile çakışmayı önler).
  DateTime? _lastVisemeFromTimelineAt;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _cameraIndex = 0;
  bool _cameraSwitching = false;
  bool _cameraSetupCompleted = false;
  bool _cameraAccessGranted = false;
  static const MethodChannel _audioSessionChannel = MethodChannel(
    'mindcoach/voice_audio_session',
  );
  final HttpService _httpService = HttpService();
  final List<Map<String, String>> _transcriptTurns = [];

  @override
  void initState() {
    super.initState();
    _riveFileLoader = _buildRiveFileLoader();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapVideoCall();
      // Placeholder arkaplan fotoğrafını ilk frame'den hemen sonra prefetch et:
      // CachedNetworkImage daha sonra decode etmeden raster cache'inden çeker,
      // ilk gerçek paint'te jank'ı önler.
      final url = widget.specialist.photoURL;
      if (url.isNotEmpty && mounted) {
        precacheImage(
          CachedNetworkImageProvider(url),
          context,
        ).catchError((_) {});
      }
    });
  }

  Future<void> _bootstrapVideoCall() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      final ok = await ensureVideoCallPermissions();
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _cameraSetupCompleted = true;
          _cameraAccessGranted = false;
        });
        _setError();
        return;
      }
    }
    if (!mounted) return;

    // 🎬 PREMIUM KONTROLÜ:
    // FindCoachStep trial akışında (isTrial=true) 1 dk deneme izni verilir.
    if (!widget.isTrial && !ref.read(AllProviders.premiumProvider).isPremium) {
      await presentProOffersPaywall();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // YENİ AKIŞ:
    //   1. PCM oynatıcı + audio session konfigürasyonu (sessizce, ses yok)
    //   2. WebSocket bağlantısı kur
    //   3. Rive avatar yüklendi + connection_success geldi → finalize
    //   4. Finalize'de placeholder fade out + kamera başlat
    //
    // Ring tone YOK — bağlantı süresince placeholder + spinner gösterilir.
    // Kamera ringing/connect fazlarında AÇILMIYOR; CameraController.initialize
    // iOS'ta ~600-900ms platform-thread blocking → açılış kasması bunun yüzünden.
    await _initPcmPlayer();
    await _connect();
    _scheduleRemoteRiveUpgrade();
  }

  /// Hem Rive yüklendiyse hem de server hazırsa çağrıyı finalize eder.
  /// Bir tarafı henüz hazır değilse no-op; geç gelen tarafın handler'ı
  /// tekrar tetikler.
  void _maybeFinalizeCallOpen() {
    if (_callOpenFinalized) return;
    if (!_riveReady || !_serverConnectionReady) return;
    if (!mounted) return;
    _callOpenFinalized = true;

    AnalyticsService.instance.capture(
      AnalyticsEvents.videoCallStarted,
      properties: {
        'consultant_id': widget.specialist.id,
        'is_trial': widget.isTrial,
      },
    );

    _cancelAiSpeakingWatchdog();
    _cancelAiPlaybackIdleMonitor();
    unawaited(_configureAudioSession());

    setState(() => _callState = _CallState.listening);
    _aiSpeakingSince = null;
    _syncRiveTalk();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
    unawaited(_maybeStartTrialTimer());

    // Server hazır olduktan sonra ai_speaking_start kuyrukta birikmiş
    // olabilir — şimdi uygula.
    if (_aiSpeakingStartPending) {
      _aiSpeakingStartPending = false;
      _receivedAiPcmThisTurn = false;
      unawaited(_configureAudioSession());
      unawaited(_ensurePcmStarted());
      _resetBargeInState();
      _aiSpeakingSince = DateTime.now();
      setState(() => _callState = _CallState.speaking);
      _syncRiveTalk();
      _armAiSpeakingWatchdog();
      _armAiPlaybackIdleMonitor();
    }

    // Mic'i kısa bir gecikmeyle aç ki audio session tam oturmuş olsun.
    if (!_isMuted) {
      unawaited(_rebindMicAfterRealtimeReady());
    }

    // Kamerayı en SON başlat: Rive ekranda zaten gözüküyor, placeholder
    // fade-out yapıyor, mic rebind sürüyor. Camera initialize'ın UI
    // thread'i bloklamadan tek başına çalışması için ekstra 350 ms.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(_initLocalCamera());
    });
  }

  Future<void> _initLocalCamera() async {
    if (!mounted) return;
    if (kIsWeb) {
      setState(() {
        _cameraSetupCompleted = true;
        _cameraAccessGranted = false;
      });
      return;
    }

    try {
      PermissionStatus status = await Permission.camera.status;
      if (status.isDenied || status.isRestricted) {
        status = await Permission.camera.request();
      }

      if (!mounted) return;

      if (!status.isGranted) {
        setState(() {
          _cameraSetupCompleted = true;
          _cameraAccessGranted = false;
        });
        return;
      }

      _cameraAccessGranted = true;

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _cameraSetupCompleted = true;
          _cameraAccessGranted = false;
        });
        return;
      }
      final frontIdx = _cameras!.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = frontIdx >= 0 ? frontIdx : 0;
      await _attachCamera(_cameraIndex);
      if (mounted) {
        setState(() {
          _cameraSetupCompleted = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraSetupCompleted = true;
          _cameraAccessGranted = false;
        });
      }
    }
  }

  Future<void> _retryCameraPermission() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    setState(() {
      _cameraSetupCompleted = false;
      _cameraAccessGranted = false;
    });
    await _initLocalCamera();
  }

  Future<void> _attachCamera(int index) async {
    final cameras = _cameras;
    if (cameras == null || index < 0 || index >= cameras.length) return;
    await _cameraController?.dispose();
    // PIP preview kutusu sadece 88×120dp. ResolutionPreset.low (320×240)
    // bu boyutta görsel olarak medium'dan ayırt edilemiyor ama iOS'ta
    // initialize ~%50 daha hızlı (~400ms → ~200ms) ve toplam GPU yükü
    // belirgin şekilde azalıyor.
    _cameraController = CameraController(
      cameras[index],
      ResolutionPreset.low,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      // Kamera initialize ses oturumunu sessizce sıfırlayabiliyor — voiceChat
      // moduna geri al ve PCM oynatıcısının çalıştığından emin ol ki AI sesi
      // kesintiye uğramasın.
      await _configureAudioSession();
      await _ensurePcmStarted();
    } catch (_) {
      await _cameraController?.dispose();
      _cameraController = null;
    }
    if (mounted) setState(() {});
  }

  Future<void> _flipCamera() async {
    if (_cameraSwitching) return;
    if (!_cameraAccessGranted || _cameras == null || _cameras!.isEmpty) {
      await _initLocalCamera();
      return;
    }
    if (_cameras!.length < 2) return;
    _cameraSwitching = true;
    try {
      final cameras = _cameras!;
      final current = cameras[_cameraIndex];
      final targetLens = current.lensDirection == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;
      final idx = cameras.indexWhere((c) => c.lensDirection == targetLens);
      if (idx < 0) {
        _cameraIndex = (_cameraIndex + 1) % cameras.length;
      } else {
        _cameraIndex = idx;
      }
      // Kamera değişimi sırasında ses oturumu kısa süre voiceChat dışına
      // düşebiliyor; pre-warm: dispose'dan ÖNCE PCM kuyruğunu garantiye al
      // ki AI o sırada konuşuyorsa hiç durmasın.
      await _ensurePcmStarted();
      await _attachCamera(_cameraIndex);
      // Ek emniyet kemeri: bazı iOS sürümlerinde initialize hemen sonrası
      // bile audio interrupted state'te kalabiliyor. 60ms sonra son bir
      // kez voiceChat moduna sabitle.
      Future.delayed(const Duration(milliseconds: 60), () {
        if (!mounted) return;
        unawaited(_configureAudioSession());
      });
    } finally {
      _cameraSwitching = false;
    }
  }

  /// Loader'ın bu ekrana mı ait olduğunu, yoksa global cache'den mi alındığını
  /// takip eder. Cache'den alınan loader'lar dispose edilmemeli.
  bool _ownsRiveFileLoader = false;

  rive.FileLoader _buildRiveFileLoader() {
    final cached = RivePreloadService.instance.getLoader(
      widget.specialist.url3d,
    );
    // Dosya tamamen indirilip decode edildiyse anında kullan.
    // Hâlâ indirme devam ediyorsa yerel asset'e geç; [_scheduleRemoteRiveUpgrade]
    // tamamlanınca uzak dosyaya geçilir.
    if (cached != null && cached.isFileAvailable) {
      _ownsRiveFileLoader = false;
      return cached;
    }
    _ownsRiveFileLoader = true;
    return rive.FileLoader.fromAsset(
      'assets/chars/f_avatar1.riv',
      riveFactory: rive.Factory.rive,
    );
  }

  /// Sohbetten gelmeden doğrudan görüntülü arama da açılabilir — cache boş olsa da
  /// [obtainOrCreateLoader] ile indirme başlar; bitince uzak .riv'e geçilir.
  Future<void> _scheduleRemoteRiveUpgrade() async {
    final loader = RivePreloadService.instance.obtainOrCreateLoader(
      widget.specialist.url3d,
    );
    if (loader == null) return;

    try {
      await loader.file();
      if (!mounted) return;
      if (identical(_riveFileLoader, loader)) return;

      setState(() {
        if (_ownsRiveFileLoader) {
          _riveFileLoader.dispose();
          _ownsRiveFileLoader = false;
        }
        _riveFileLoader = loader;
        _riveLoaderKey++;
      });
    } catch (_) {
      // Uzak dosya gelmezse yerel avatar kullanılmaya devam eder.
    }
  }

  /// Native AVAudioSession.setCategory + setActive yapıyor — pahalı işlem.
  /// Önceki kod: bootstrap, _init, _initPcmPlayer, _onRealtimeConnectionReady,
  /// _attachCamera, _flipCamera, _startMicStream… 5-7 yerden ardışık çağrı
  /// yapılıyordu, native taraf her seferinde session'ı resetliyor ve PCM
  /// playback "underrun" hatası veriyordu. Rate-limit ile son 250ms içinde
  /// yapılmış bir konfigürasyonu tekrar etmiyoruz.
  DateTime? _lastAudioSessionConfigAt;
  bool _audioSessionConfiguring = false;
  Future<void> _configureAudioSession() async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    final now = DateTime.now();
    final last = _lastAudioSessionConfigAt;
    if (last != null && now.difference(last).inMilliseconds < 250) return;
    if (_audioSessionConfiguring) return;
    _audioSessionConfiguring = true;
    try {
      await _audioSessionChannel.invokeMethod<String>('configureForVoiceCall');
      if (_isSpeakerOn) {
        try {
          await _audioSessionChannel.invokeMethod('setSpeakerOn', {'on': true});
        } catch (_) {}
      }
      _lastAudioSessionConfigAt = DateTime.now();
    } catch (_) {
    } finally {
      _audioSessionConfiguring = false;
    }
  }

  Future<void> _resetAudioSession() async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      await _audioSessionChannel.invokeMethod('resetAudioSession');
    } catch (_) {}
  }

  Future<void> _initPcmPlayer() async {
    await pcm.FlutterPcmSound.setup(
      sampleRate: _sampleRate,
      channelCount: _channels,
      iosAudioCategory: pcm.IosAudioCategory.playAndRecord,
    );
    // 400ms → 480ms: TTS chunk'ları arası ağ jitter'da native tampon ara
    // ara boşalıp "tık" / sessizlik yapıyordu.
    await pcm.FlutterPcmSound.setFeedThreshold((_sampleRate * 0.48).round());
    pcm.FlutterPcmSound.setFeedCallback(_onPcmFeedRequest);
    _pcmSetup = true;
    await _configureAudioSession();
  }

  Future<void> _ensurePcmStarted() async {
    if (!_pcmSetup || _pcmStarted) return;
    pcm.FlutterPcmSound.start();
    _pcmStarted = true;
  }

  void _onPcmFeedRequest(int remainingFrames) {
    if (_pcmTotalSamples == 0) {
      _signalNativePcmDrainedIfIdle(remainingFrames);
      return;
    }
    final int maxSamples = (_sampleRate * 0.5).round();
    final int toSend = _pcmTotalSamples < maxSamples
        ? _pcmTotalSamples
        : maxSamples;
    final Int16List samples = Int16List(toSend);
    int dst = 0;
    double sumSq = 0;
    while (dst < toSend && _pcmChunks.isNotEmpty) {
      final Int16List chunk = _pcmChunks.first;
      final int available = chunk.length - _pcmChunkOffset;
      final int needed = toSend - dst;
      final int copy = available < needed ? available : needed;
      // setRange = memcpy-equivalent native fastpath
      samples.setRange(dst, dst + copy, chunk, _pcmChunkOffset);
      // RMS only over the slice we just pulled — no second pass.
      for (int i = 0; i < copy; i++) {
        final double v = chunk[_pcmChunkOffset + i].toDouble();
        sumSq += v * v;
      }
      dst += copy;
      if (copy == available) {
        _pcmChunks.removeFirst();
        _pcmChunkOffset = 0;
      } else {
        _pcmChunkOffset += copy;
      }
    }
    if (dst == 0) return;

    _pcmTotalSamples -= dst;
    _lastPlaybackRms = sqrt(sumSq / dst).round();
    pcm.FlutterPcmSound.feed(
      pcm.PcmArrayInt16(
        bytes: samples.buffer.asByteData(samples.offsetInBytes, dst * 2),
      ),
    );
  }

  void _signalNativePcmDrainedIfIdle(int remainingFrames) {
    if (remainingFrames != 0) return;

    // Ağız senkronu için: oyun-anı drain. PCM kuyruğu hem Dart hem native
    // tarafta gerçekten boşaldığında ağzı derhal kapat — backend'in
    // `ai_response_complete` mesajını beklemeden. Aksi halde son chunk
    // bittikten sonra timeline timer'ları (wall-clock) "ağız havada" oynamaya
    // devam ediyordu.
    if (_pcmTotalSamples == 0 &&
        _riveAudioActive &&
        _callState == _CallState.speaking) {
      _forceCloseMouthForSilence();
    }

    // Aksi halde konuşmalar arası native "0" event'i yanlışlıkla bekleyeni
    // erken serbest bırakır.
    if (!_pcmDrainInFlight) return;
    final c = _nativePcmDrainedCompleter;
    if (c == null || c.isCompleted) return;
    c.complete();
    _nativePcmDrainedCompleter = null;
  }

  /// Ses bitmesine rağmen ağız oynuyorsa anında durdur:
  /// - Tüm timeline timer'larını iptal et.
  /// - Smoothed RMS'i sıfırla.
  /// - Rive `visemeNum=0` VE `talk=false` set et. Rive state machine
  ///   "konuşuyor" durumunda baked-in idle ağız animasyonu çalıştırıyor
  ///   olabilir; sadece visemeNum=0 yetmiyor, talk'u da kapatmamız gerek.
  ///   Yeni PCM chunk geldiğinde `_driveRealtimeVisemeFromRms` zaten
  ///   talk=true'yu geri set edecek.
  void _forceCloseMouthForSilence() {
    for (final t in _visemeTimers) {
      t.cancel();
    }
    _visemeTimers.clear();
    _visemeTimelineActive = false;
    _lastVisemeFromTimelineAt = null;
    _realtimeVisemeApplyTimer?.cancel();
    _realtimeVisemeApplyTimer = null;
    _pendingRealtimeVisemeId = 0;
    _rmsSmoothed = 0.0;
    _visemeApplied = 0;
    _visemeAppliedAt = DateTime.now();
    _setRiveNumber('duration', _riveTalkCloseBlendMs);
    _setRiveNumber('visemeNum', 0);
    _setRiveBool('talk', false);
    _riveAudioActive = false;
    _lastSpeechRmsAt = null;
    _forceCloseLockedUntil = DateTime.now().add(
      const Duration(milliseconds: _forceCloseLockoutMs),
    );
  }

  /// Dart kuyruğu boşaldıktan sonra hoparlördeki gerçek PCM bitişini bekle.
  Future<void> _awaitNativePcmFullyDrained() async {
    final c = Completer<void>();
    _nativePcmDrainedCompleter = c;
    try {
      await c.future.timeout(
        const Duration(milliseconds: 1400),
        onTimeout: () {},
      );
    } finally {
      if (identical(_nativePcmDrainedCompleter, c)) {
        _nativePcmDrainedCompleter = null;
      }
    }
  }

  Future<void> _connect() async {
    try {
      final token = await ensureRealtimeAuthToken(ref);
      final deviceLang = ref.read(localeProvider.notifier).getLanguageCode();
      // Sesli arama ile aynı sorgu — ek parametre sunucu oturumunu bozabiliyordu.
      final url =
          '${AppConstants.wsBaseURL}'
          '?token=${Uri.encodeQueryComponent(token)}'
          '&consultantId=${widget.specialist.id}'
          '&lang=${Uri.encodeQueryComponent(deviceLang)}';
      _ws = await WebSocket.connect(url);
      _wsSub = _ws!.listen(
        _onWsData,
        onError: (_) => _setError(),
        onDone: () {
          if (mounted && _callState != _CallState.error) {
            Navigator.of(context).pop();
          }
        },
        cancelOnError: false,
      );
      _armConnectionReadyFallback();
      await _startMicStream();
    } catch (_) {
      _setError();
    }
  }

  void _cancelConnectionReadyFallback() {
    _connectionReadyFallbackTimer?.cancel();
    _connectionReadyFallbackTimer = null;
  }

  void _armConnectionReadyFallback() {
    _cancelConnectionReadyFallback();
    // Bazı demo/backend akışları `connection_success` göndermiyor.
    // WS açıksa kısa süre sonra çağrıyı açarak UI'ın connecting'de donmasını
    // ve trial timer/kamera başlatılmamasını engelle.
    _connectionReadyFallbackTimer = Timer(
      const Duration(milliseconds: 1200),
      () {
        if (!mounted || _callOpenFinalized || _serverConnectionReady) return;
        if (_ws?.readyState != WebSocket.open) return;
        _onRealtimeConnectionReady();
      },
    );
  }

  int _computePcm16Rms(Uint8List chunk) {
    final int n = chunk.length ~/ 2;
    if (n == 0) return 0;
    final ByteData bd = ByteData.view(chunk.buffer, chunk.offsetInBytes, n * 2);
    double sumSq = 0;
    for (int i = 0; i < n; i++) {
      final int s = bd.getInt16(i * 2, Endian.little);
      sumSq += s * s.toDouble();
    }
    return sqrt(sumSq / n).round();
  }

  int _chunkDurationMs(Uint8List chunk) {
    final int samples = chunk.length ~/ 2;
    return ((samples / _sampleRate) * 1000).round();
  }

  void _resetBargeInState() {
    _highRmsStreakMs = 0;
    _bargeInSent = false;
    _preRoll.clear();
  }

  Future<void> _startMicStream() async {
    if (_micStreamActive) return;
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      final ok = await ensureMicrophonePermission();
      if (!ok) {
        _setError();
        return;
      }
    }
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _setError();
      return;
    }
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      await _configureAudioSession();
    }
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: _channels,
      ),
    );
    _micSub = stream.listen((chunk) {
      if (chunk.isEmpty || chunk.length % 2 != 0) return;
      if (_isMuted || _ws?.readyState != WebSocket.open) return;
      final gateUntil = _micGateOpenAt;
      if (gateUntil != null && DateTime.now().isBefore(gateUntil)) return;
      _micGateOpenAt = null;

      if (_callState == _CallState.speaking) {
        final int durMs = _chunkDurationMs(chunk);
        final int rms = _computePcm16Rms(chunk);
        final int dynamicThreshold = _isSpeakerOn
            ? _bargeInRmsThresholdSpeaker
            : _bargeInRmsThresholdEarpiece;
        final int echoAwareThreshold = max(
          dynamicThreshold,
          (_lastPlaybackRms * 1.6).round(),
        );
        final int speakingForMs = _aiSpeakingSince == null
            ? 0
            : DateTime.now().difference(_aiSpeakingSince!).inMilliseconds;
        _preRoll.add(_AudioChunk(chunk, durMs));
        int bufferedMs = 0;
        for (final c in _preRoll) {
          bufferedMs += c.durationMs;
        }
        while (bufferedMs > _preRollMaxMs && _preRoll.length > 1) {
          bufferedMs -= _preRoll.removeFirst().durationMs;
        }
        if (!_bargeInSent &&
            speakingForMs >= _bargeInMinAiSpeakingMs &&
            rms >= echoAwareThreshold) {
          _highRmsStreakMs += durMs;
          if (_highRmsStreakMs >= _bargeInSustainedMs) {
            _bargeInSent = true;
            _cancelAiSpeakingWatchdog();
            _cancelAiPlaybackIdleMonitor();
            _flushPcm();
            _ws!.add(jsonEncode({'type': 'barge_in_request'}));
            for (final c in _preRoll) {
              if (c.bytes.isEmpty || c.bytes.length % 2 != 0) continue;
              _ws!.add(c.bytes);
            }
            _preRoll.clear();
            if (mounted) setState(() => _callState = _CallState.listening);
          }
        } else {
          _highRmsStreakMs = 0;
        }
        return;
      }
      _resetBargeInState();
      _ws!.add(chunk);
    });
    _micStreamActive = true;
  }

  Future<void> _stopMicStream() async {
    if (!_micStreamActive) return;
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    _micStreamActive = false;
    _resetBargeInState();
  }

  void _onWsData(dynamic data) {
    if (_trialExpired) return;
    if (data is String) {
      final msg = jsonDecode(data) as Map<String, dynamic>;
      if (msg['type'] == 'viseme_timeline') {
        _applyVisemeTimeline(msg);
        return;
      }
      _handleJson(msg);
    } else if (data is List<int>) {
      _enqueuePcmBytes(Uint8List.fromList(data));
    }
  }

  void _clearVisemeTimers() {
    _realtimeVisemeApplyTimer?.cancel();
    _realtimeVisemeApplyTimer = null;
    _pendingRealtimeVisemeId = 0;
    _visemeApplied = 0;
    _visemeAppliedAt = null;
    _rmsSmoothed = 0.0;
    _pendingVisemeTimelineMsg = null;
    for (final t in _visemeTimers) {
      t.cancel();
    }
    _visemeTimers.clear();
    _visemeTimelineActive = false;
    _lastVisemeFromTimelineAt = null;
  }

  void _maybeFlushPendingVisemeTimeline() {
    final pending = _pendingVisemeTimelineMsg;
    if (pending == null || !_riveAudioActive) return;
    _pendingVisemeTimelineMsg = null;
    _scheduleVisemeTimers(pending);
  }

  void _scheduleVisemeTimers(Map<String, dynamic> msg) {
    final List<dynamic> timeline =
        (msg['timeline'] as List<dynamic>?) ??
        (msg['visemes'] as List<dynamic>?) ??
        [];
    final int startOffsetMs = (msg['startOffsetMs'] as num?)?.toInt() ?? 0;

    int futureCount = 0;
    int lastFutureDelayMs = 0;

    // ── Quantization ──
    // Timeline'da birbirine çok yakın phoneme'ler ağız titremesi yaratıyordu.
    // Önceki tetik zamanından _visemeTimelineMinGapMs geçmediyse ve id de aynı
    // bandda kalıyorsa atla. Son uygulanan id'yi de takip et ki ardışık
    // aynı id'ler boşa timer yaratmasın.
    int lastScheduledDelayMs = -1 << 30;
    int lastScheduledId = -1;

    for (final entry in timeline) {
      if (entry is! Map) continue;
      final dynamic idRaw = entry['id'];
      if (idRaw is! num) continue;
      // 3-band quantize: backend hangi phoneme id'sini yollarsa yollasın,
      // sadece kapalı (0) / orta (6) / açık (14) görünecek. Ağız "her phoneme
      // için farklı şekil" yapmaz, sakin akar.
      final int rawId = idRaw.toInt();
      final int id = rawId == 0 ? 0 : (rawId <= 7 ? 6 : 14);
      final dynamic tRaw = entry['t'];
      final dynamic timeRaw = entry['time'];
      final int timeMs = tRaw is num
          ? tRaw.toInt()
          : (timeRaw is num ? (timeRaw * 1000).round() : 0);

      final int rawDelayMs = timeMs - startOffsetMs;
      final int delayMs = (rawDelayMs * _visemeTimelineDelayScale).round();
      if (delayMs < 0) {
        _visemeApplied = id;
        continue;
      }

      // Önceki schedule'a çok yakın aynı id → boşa harcanır. Atla.
      if (id == lastScheduledId &&
          delayMs - lastScheduledDelayMs < _visemeTimelineMinGapMs) {
        continue;
      }
      // Farklı id ama çok yakın geliyorsa: ağız flicker'ı önlemek için
      // bu entry'yi de atla (timeline'ı seyreltiyoruz).
      if (delayMs - lastScheduledDelayMs < _visemeTimelineMinGapMs) {
        continue;
      }
      lastScheduledDelayMs = delayMs;
      lastScheduledId = id;

      futureCount++;
      if (delayMs > lastFutureDelayMs) lastFutureDelayMs = delayMs;

      _visemeTimers.add(
        Timer(Duration(milliseconds: delayMs), () {
          if (!mounted) return;
          if (_callState != _CallState.speaking) {
            return;
          }
          // Wall-clock timer'lar gerçek audio playback bitse de fire ediyor.
          // Native PCM kuyruğu boşaldıysa (`_riveAudioActive == false`,
          // `_forceCloseMouthForSilence` tarafından düşürüldü), bu tetiği
          // tamamen yoksay — yoksa ses bittikten sonra "ağız havada" oynuyor.
          if (!_riveAudioActive) return;
          // ── Runtime gap-check ──
          // Schedule sırasında quantize ettik ama timer'ların gerçek fire
          // zamanı kayabilir (Dart event-loop, system load). Burada da
          // koruma: son apply'dan _visemeTimelineMinGapMs geçmediyse atla.
          // Aynı id zaten uygulanmışsa hiç dokunma.
          final now = DateTime.now();
          if (id == _visemeApplied) return;
          final lastApplied = _visemeAppliedAt;
          if (lastApplied != null &&
              now.difference(lastApplied).inMilliseconds <
                  _visemeTimelineMinGapMs) {
            return;
          }
          _visemeApplied = id;
          _visemeAppliedAt = now;
          _lastVisemeFromTimelineAt = now;
          _setRiveNumber('visemeNum', id.toDouble());
          _setRiveNumber('duration', _riveVisemeBlendMs);
        }),
      );
    }

    // Timeline'ın TÜMÜ geçmişte kaldıysa (text_done audio'dan geç gelmiş)
    // ya da çok az gelecek entry varsa, RMS sürücüsünü tekrar devreye al.
    // Aksi halde ağız son uygulanan id'ye yapışıp donar — kullanıcı ağzı
    // hareketsiz görür.
    if (futureCount < 3) {
      _visemeTimelineActive = false;
      return;
    }

    // NOT: Eskiden burada lastFutureDelayMs + 80 ms sonra _visemeTimelineActive
    // false yapılıyordu — timeline biter bitmez RMS ile çakışıp ağız
    // hareketleri "iptal" gibi görünüyordu. Artık timeline aktif kalır;
    // RMS yalnızca [_lastVisemeFromTimelineAt] üzerinden throttling ile
    // timeline'a müdahale eder (aşağıda).

    if (_visemeApplied != 0) {
      _visemeAppliedAt = DateTime.now();
      _setRiveNumber('visemeNum', _visemeApplied.toDouble());
      _setRiveNumber('duration', _riveVisemeBlendMs);
    }
  }

  /// Apply a server-generated Rhubarb phoneme timeline.
  ///
  /// [msg] contains:
  ///   timeline      – List of {id, t} where t is ms from ai_speaking_start
  ///   startOffsetMs – how many ms ago the server sent ai_speaking_start
  ///                   (= how many ms of audio have already been playing)
  void _applyVisemeTimeline(Map<String, dynamic> msg) {
    _clearVisemeTimers();
    _visemeTimelineActive = true;

    // Ağız ve timeline, gerçek PCM çıkışı başladıktan sonra — sesle birlikte.
    if (!_riveAudioActive) {
      _pendingVisemeTimelineMsg = Map<String, dynamic>.from(msg);
      return;
    }
    _scheduleVisemeTimers(msg);
  }

  void _setRiveNumber(String key, double value) {
    final vm = _riveViewModel;
    if (vm != null) {
      // ViewModel (DataBind) path
      bool applied = false;
      try {
        final n = vm.number(key);
        if (n != null) {
          n.value = value;
          applied = true;
        }
      } catch (_) {}
      try {
        for (final prop in vm.properties) {
          if (prop.name == key) {
            (prop as dynamic).value = value;
            applied = true;
            break;
          }
        }
      } catch (_) {}
      if (applied) return;
    }
    // StateMachine inputs path
    if (key == 'visemeNum') _smVisemeNum?.value = value;
    if (key == 'duration') _smDuration?.value = value;
  }

  void _driveRealtimeVisemeFromRms(int rms) {
    if (_callState != _CallState.speaking) return;

    // ── Force-close lockout ──
    // Az önce ağzı zorla kapattıysak (ses bitti), backend hâlâ silent-tail
    // PCM yolluyorsa o chunk'lar ağzı tekrar açmasın. Yalnızca gerçek bir
    // yeni cümle (yüksek RMS) lockout'u override edebilir.
    final lockUntil = _forceCloseLockedUntil;
    if (lockUntil != null) {
      if (DateTime.now().isBefore(lockUntil)) {
        if (rms < _forceCloseLockoutRmsOverride) {
          // Tail silinciye kadar agresif şekilde bastır. Smoothed'a da
          // yansıtma ki envelope follower düşük tutsun.
          _rmsSmoothed = 0.0;
          return;
        }
        // Yeterince yüksek RMS — gerçek yeni utterance, lockout'u kaldır.
        _forceCloseLockedUntil = null;
      } else {
        _forceCloseLockedUntil = null;
      }
    }

    // Timeline açıkken: yalnızca timeline hamlesi yapıldıktan sonra kısa
    // bir süre RMS'i bastır — üst üste yazma "dudak iptal" ediyormuş gibi
    // görünür. Süre dolunca veya timeline sessiz kaldığında RMS tail'i devralır.
    if (_visemeTimelineActive) {
      if (!_riveAudioActive && rms > 180) {
        _riveAudioActive = true;
        _setRiveBool('talk', true);
        _setRiveNumber('duration', _riveTalkOpenBlendMs);
        _maybeFlushPendingVisemeTimeline();
      }
      final lastTl = _lastVisemeFromTimelineAt;
      if (lastTl != null &&
          DateTime.now().difference(lastTl).inMilliseconds < 8) {
        return;
      }
    }

    // ── Asymmetric envelope follower (attack/release) ───────────────────────
    // Attack orta, release ılımlı. Çok hızlı release (0.55) heceler arası
    // micro-pause'larda ağzı kapatıp tekrar açıyordu (flicker). PCM kuyruğu
    // gerçekten bittiğinde zaten `_forceCloseMouthForSilence` anında kapatıyor;
    // burası sadece konuşma içi yumuşak takip yapmalı.
    const double attackAlpha = 0.35; // yükselişte yumuşak takip
    const double releaseAlpha = 0.30; // sönümde sakin takip
    final double rmsD = rms.toDouble();
    if (rmsD > _rmsSmoothed) {
      _rmsSmoothed = _rmsSmoothed * (1 - attackAlpha) + rmsD * attackAlpha;
    } else {
      _rmsSmoothed = _rmsSmoothed * (1 - releaseAlpha) + rmsD * releaseAlpha;
    }
    final int smoothRms = _rmsSmoothed.round();

    // Son "anlamlı konuşma" zamanını izle — silence watchdog buna bakıyor.
    if (smoothRms >= _speechRmsThreshold) {
      _lastSpeechRmsAt = DateTime.now();
    }

    // Open mouth the first time real audio arrives (PCM gerçekten yürüdüğünde).
    // Daha düşük eşik → ağız sesin başlangıcına anında reaksiyon verir.
    if (!_riveAudioActive && smoothRms > 90) {
      _riveAudioActive = true;
      _setRiveBool('talk', true);
      _setRiveNumber('duration', _riveTalkOpenBlendMs);
      _maybeFlushPendingVisemeTimeline();
    }
    if (!_riveAudioActive) return;

    // ── 5-level viseme mapping (geniş bantlar) ──
    // Daha az level = aynı ses bandında ağız id'si daha sık aynı kalır,
    // viseme update'leri ile birlikte sakin ağız tempo.
    // ── Hysteresis: sessizlik bandı ──
    // Ağız KAPALI iken: açmak için smoothRms > 220 olmalı.
    // Ağız AÇIK iken: kapatmak için smoothRms < 140'a düşmesi gerekir.
    // Ortadaki 140..220 gri bölgede mevcut durum korunur → heceler arası
    // micro-pause'larda flicker olmaz.
    final bool mouthOpen = _visemeApplied != 0;
    final int silenceThreshold = mouthOpen ? 140 : 220;

    // ── 3 seviye ──
    // 5 seviye (0/2/6/10/15) görsel olarak çok fazla varyasyon yaratıyordu.
    // 3 seviye: kapalı / orta / açık. Ağız daha az "şekil değiştirir".
    int targetId;
    if (smoothRms < silenceThreshold) {
      targetId = 0; // kapalı
    } else if (smoothRms < 900) {
      targetId = 6; // orta
    } else {
      targetId = 14; // açık
    }

    // THROTTLE: Timer kuyruktaysa skip — yeniden kurma. Bu şekilde saniyede
    // maksimum (1000 / _realtimeVisemeDebounceMs) viseme update fire eder.
    // Timer fire ettiğinde son _pendingRealtimeVisemeId uygulanır.
    _pendingRealtimeVisemeId = targetId;
    if (targetId == _visemeApplied) return;
    if (_realtimeVisemeApplyTimer != null) return;
    _realtimeVisemeApplyTimer = Timer(
      Duration(milliseconds: _realtimeVisemeDebounceMs),
      () {
        _realtimeVisemeApplyTimer = null;
        if (!mounted) return;
        if (_callState != _CallState.speaking) return;
        final int id = _pendingRealtimeVisemeId;
        if (id == _visemeApplied) return;

        // Kapanış için artificial hold kaldırıldı: ağız ses bitince anında
        // 0'a düşsün. Önceki 60ms gecikme, sesin son hecesi bittikten sonra
        // ağzın "bir kare daha açık" görünmesine yol açıyordu.

        _visemeApplied = id;
        _visemeAppliedAt = DateTime.now();
        _setRiveNumber('visemeNum', id.toDouble());
        _setRiveNumber('duration', _riveVisemeBlendMs);
      },
    );
  }

  Future<void> _maybeStartTrialTimer() async {
    if (!widget.isTrial) return;
    if (_trialTimer != null && _trialTimer!.isActive) return;
    try {
      final remaining = await TrialQuotaService.instance
          .videoTrialSecondsRemaining();
      if (!mounted) return;
      if (remaining <= 0) {
        await _onTrialExpired();
        return;
      }
      _videoTrialBudgetSeconds = remaining.clamp(
        1,
        TrialQuotaService.videoTrialSecondLimit,
      );
      _trialTimer?.cancel();
      _trialTimer = Timer(Duration(seconds: _videoTrialBudgetSeconds), () {
        if (mounted) {
          unawaited(_onTrialExpired());
        }
      });
    } catch (e) {
      // Trial servisi error'u ise, güvenli için 60 sn timer başlat
      if (!mounted) return;
      _videoTrialBudgetSeconds = TrialQuotaService.videoTrialSecondLimit;
      _trialTimer?.cancel();
      _trialTimer = Timer(Duration(seconds: _videoTrialBudgetSeconds), () {
        if (mounted) {
          unawaited(_onTrialExpired());
        }
      });
    }
  }

  Future<void> _persistVideoTrialUsageOnce() async {
    if (!widget.isTrial || _videoTrialUsagePersisted) return;
    _videoTrialUsagePersisted = true;
    final cap = _videoTrialBudgetSeconds > 0
        ? _videoTrialBudgetSeconds
        : TrialQuotaService.videoTrialSecondLimit;
    final used = min(_secondsElapsed, cap);
    if (used <= 0) return;
    await TrialQuotaService.instance.addVideoTrialSeconds(used);
  }

  Future<void> _onTrialExpired() async {
    if (!mounted || _trialDialogShown) return;
    _trialDialogShown = true;
    _trialExpired = true;
    await _terminateRealtimeForTrialExpiry();
    await _persistVideoTrialUsageOnce();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VideoCallTrialInsightsScreen(
          specialist: widget.specialist,
          durationSeconds: _secondsElapsed,
          transcriptTurns: List<Map<String, String>>.from(_transcriptTurns),
        ),
      ),
    );
  }

  Future<void> _terminateRealtimeForTrialExpiry() async {
    _cancelAiSpeakingWatchdog();
    _cancelAiPlaybackIdleMonitor();
    _cancelConnectionReadyFallback();
    _clearVisemeTimers();
    _flushPcm();
    _setRiveNumber('visemeNum', 0);
    _setRiveBool('talk', false);
    _syncRiveTalk();
    if (mounted) {
      setState(() => _callState = _CallState.error);
    }
    try {
      await _stopMicStream();
    } catch (_) {}
    try {
      await _ws?.close();
    } catch (_) {}
  }

  /// Sunucu connection_success gönderdiğinde işaretle ve finalize'i dene.
  /// Rive henüz yüklü değilse finalize ertelenir; _onRiveLoaded içinde
  /// tekrar tetiklenecek.
  void _onRealtimeConnectionReady() {
    if (!mounted) return;
    _cancelConnectionReadyFallback();
    _serverConnectionReady = true;
    _maybeFinalizeCallOpen();
  }

  /// [afterAiPlayback]: AI PCM bittikten sonra mic'e dönüş — kısa gecikme
  /// yeter; 400ms kullanıcıya "Rive 1 sn dondu" hissi veriyordu.
  Future<void> _rebindMicAfterRealtimeReady({
    bool afterAiPlayback = false,
  }) async {
    await _stopMicStream();
    await Future<void>.delayed(
      Duration(milliseconds: afterAiPlayback ? 90 : 400),
    );
    if (!mounted || _ws?.readyState != WebSocket.open || _isMuted) return;
    await _configureAudioSession();
    await _startMicStream();
  }

  void _cancelAiSpeakingWatchdog() {
    _aiSpeakingWatchdog?.cancel();
    _aiSpeakingWatchdog = null;
  }

  void _cancelAiPlaybackIdleMonitor() {
    _aiPlaybackIdleTimer?.cancel();
    _aiPlaybackIdleTimer = null;
    _lastAiPcmReceivedAt = null;
  }

  void _evaluateAiPlaybackIdleFallback() {
    if (!mounted) return;
    if (_callState != _CallState.speaking) {
      _cancelAiPlaybackIdleMonitor();
      return;
    }
    // İlk PCM gelmeden idle sayma — [ai_speaking_start] ile [_aiSpeakingSince]
    // arasındaki boşluk yanlışlıkla drain tetikliyordu.
    if (!_receivedAiPcmThisTurn) return;
    final base = _lastAiPcmReceivedAt;
    if (base == null) return;

    final stallMs = DateTime.now().difference(base).inMilliseconds;

    // ── Kısa eşik: ağzı erken kapat ──
    // İki bağımsız tetikleyici:
    //   1) PCM kuyruğu boş ve son chunk >=80ms önce → klasik drain bitti.
    //   2) RMS-bazlı: son "anlamlı konuşma" üzerinden 180ms geçti.
    //      Backend silent-tail PCM yollamaya devam ediyor olsa bile
    //      (queue boşalmıyor ama gerçek ses bitti) bu yakalar.
    if (_riveAudioActive) {
      final lastSpeech = _lastSpeechRmsAt;
      final speechStallMs = lastSpeech == null
          ? 1 << 30
          : DateTime.now().difference(lastSpeech).inMilliseconds;
      final bool queueEmptyAndStale = _pcmTotalSamples == 0 && stallMs >= 80;
      final bool speechSilentTooLong =
          speechStallMs >= _silenceCloseAfterMs;
      if (queueEmptyAndStale || speechSilentTooLong) {
        _forceCloseMouthForSilence();
      }
    }

    // Yazılım kuyruğunda çalınmayı bekleyen örnek varken ASLA drain / flush
    // yapma. Chunk'lar geç gelince "playback stuck" sanılıp kuyruk atılıyor
    // ve ses ortadan kesiliyordu.
    if (_pcmTotalSamples > 0) {
      return;
    }

    if (stallMs < _aiPlaybackIdleMs) return;

    debugPrint(
      '🔊 [VIDEO] playback idle fallback → drain/listen '
      '(ai_response_complete eksik olabilir, stall=${stallMs}ms)',
    );
    _cancelAiPlaybackIdleMonitor();
    _cancelAiSpeakingWatchdog();
    unawaited(_waitForPcmDrainAndListen());
  }

  void _armAiPlaybackIdleMonitor() {
    _cancelAiPlaybackIdleMonitor();
    _lastAiPcmReceivedAt = null;
    _aiPlaybackIdleTimer = Timer.periodic(const Duration(milliseconds: 80), (
      _,
    ) {
      _evaluateAiPlaybackIdleFallback();
    });
  }

  void _armAiSpeakingWatchdog() {
    _cancelAiSpeakingWatchdog();
    _aiSpeakingWatchdog = Timer(
      const Duration(seconds: 75),
      _onAiSpeakingWatchdogFired,
    );
  }

  void _onAiSpeakingWatchdogFired() {
    _aiSpeakingWatchdog = null;
    if (!mounted) return;
    if (_callState != _CallState.speaking) return;
    _cancelAiPlaybackIdleMonitor();
    debugPrint('⚠️ [VIDEO] speaking watchdog → drain/listen + playback_done');
    unawaited(_waitForPcmDrainAndListen());
  }

  void _handleJson(Map<String, dynamic> msg) {
    final type = msg['type'] as String? ?? '';
    _captureTranscriptTurn(type, msg);
    switch (type) {
      case 'connection_success':
        _onRealtimeConnectionReady();
        break;
      case 'user_speech_started':
        if (_isMuted) break;
        if (mounted && _callState != _CallState.speaking) {
          setState(() => _callState = _CallState.listening);
        }
        break;
      case 'user_speech_stopped':
        if (_isMuted) break;
        // AI hâlâ konuşurken sunucu bazen [user_speech_stopped] yollar (VAD).
        // Thinking'e geçmek ağzı kapatıyor + kullanıcı "dudak iptal" görüyor.
        if (_callState == _CallState.speaking) break;
        if (mounted) setState(() => _callState = _CallState.thinking);
        _syncRiveTalk();
        break;
      case 'ai_speaking_start':
        // Çağrı henüz finalize olmadıysa (Rive yüklenmedi veya
        // connection_success'i biz kaydetmeden başka event geldi) ai_speaking
        // event'ini kuyrukta tut; finalize sırasında uygulanır.
        if (!_callOpenFinalized) {
          _aiSpeakingStartPending = true;
          break;
        }
        _receivedAiPcmThisTurn = false;
        unawaited(_configureAudioSession());
        unawaited(_ensurePcmStarted());
        _resetBargeInState();
        _aiSpeakingSince = DateTime.now();
        if (mounted) setState(() => _callState = _CallState.speaking);
        _syncRiveTalk();
        _armAiSpeakingWatchdog();
        _armAiPlaybackIdleMonitor();
        break;
      case 'ai_response_complete':
        _cancelAiSpeakingWatchdog();
        _cancelAiPlaybackIdleMonitor();
        _waitForPcmDrainAndListen();
        break;
      case 'barge_in':
        _cancelAiSpeakingWatchdog();
        _cancelAiPlaybackIdleMonitor();
        _flushPcm();
        _resetBargeInState();
        _aiSpeakingSince = null;
        _clearVisemeTimers();
        _setRiveNumber('visemeNum', 0);
        if (mounted) setState(() => _callState = _CallState.listening);
        _syncRiveTalk();
        if (!_isMuted && _ws?.readyState == WebSocket.open) {
          unawaited(_rebindMicAfterRealtimeReady());
        }
        break;
      case 'error':
        _setError();
        break;
    }
  }

  void _captureTranscriptTurn(String type, Map<String, dynamic> msg) {
    String role = '';
    if (type.contains('user')) {
      role = 'user';
    } else if (type.contains('ai') || type.contains('assistant')) {
      role = 'assistant';
    } else {
      final rawRole = msg['role']?.toString().toLowerCase() ?? '';
      if (rawRole.contains('user')) {
        role = 'user';
      } else if (rawRole.contains('assistant') || rawRole.contains('ai')) {
        role = 'assistant';
      }
    }

    if (role.isEmpty) return;

    final possibleText = <dynamic>[
      msg['text'],
      msg['transcript'],
      msg['content'],
      msg['message'],
      msg['response'],
      msg['assistantText'],
      msg['userText'],
    ];
    String? text;
    for (final value in possibleText) {
      final current = value?.toString().trim();
      if (current != null && current.isNotEmpty) {
        text = current;
        break;
      }
    }

    if (text == null || text.isEmpty) return;
    _transcriptTurns.add({'role': role, 'text': text});
  }

  void _enqueuePcmBytes(Uint8List bytes) {
    if (!_callOpenFinalized &&
        !_serverConnectionReady &&
        _ws?.readyState == WebSocket.open) {
      // `connection_success` hiç gelmeyen ortamlarda ilk PCM'i hazır sinyali
      // kabul et; aksi halde avatar/kamera hiç açılmıyordu.
      _onRealtimeConnectionReady();
    }
    if (_callOpenFinalized &&
        _callState != _CallState.speaking &&
        !_isMuted &&
        mounted) {
      _receivedAiPcmThisTurn = false;
      _resetBargeInState();
      _aiSpeakingSince = DateTime.now();
      setState(() => _callState = _CallState.speaking);
      _syncRiveTalk();
      _armAiSpeakingWatchdog();
      _armAiPlaybackIdleMonitor();
    }
    _lastAiPcmReceivedAt = DateTime.now();
    if (_callState == _CallState.speaking) {
      _receivedAiPcmThisTurn = true;
    }
    final int sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) return;

    // PCM16 LE → Int16List. Tek allocation; sample-by-sample boxing yok.
    // Sunucu little-endian gönderdiği ve mobil host da little-endian olduğu
    // için ByteData.getInt16(LE) ile manuel decode etmek host endianness'a
    // bağımsız doğru çalışır.
    final Int16List samples = Int16List(sampleCount);
    final ByteData bd = ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      sampleCount * 2,
    );
    for (int i = 0; i < sampleCount; i++) {
      samples[i] = bd.getInt16(i * 2, Endian.little);
    }
    _pcmChunks.add(samples);
    _pcmTotalSamples += sampleCount;

    // ── Pencere bazlı RMS örneklemesi (viseme driver için) ──
    // PCM feed callback'i tampon doldurma için ~250ms aralıkla çalışıyor; bu
    // ağzı saniyede sadece 4 kez güncellerdi. Sunucudan gelen ses paketi ~30
    // ila ~120ms arası olabildiği için chunk içini _visemeRmsWindowMs'lik
    // alt-pencerelere bölüp her birinde ayrı RMS hesaplıyoruz — viseme
    // sürücüsü bu sayede syllable hızında çalışıyor. Int16List üzerinde
    // doğrudan iterasyon ByteData.getInt16'dan ~3× daha hızlı.
    final int windowSamples = ((_visemeRmsWindowMs / 1000.0) * _sampleRate)
        .round()
        .clamp(64, sampleCount);
    if (sampleCount >= windowSamples) {
      final int windowCount = sampleCount ~/ windowSamples;
      for (int w = 0; w < windowCount; w++) {
        final int start = w * windowSamples;
        double sumSq = 0;
        for (int i = 0; i < windowSamples; i++) {
          final double v = samples[start + i].toDouble();
          sumSq += v * v;
        }
        final int rms = sqrt(sumSq / windowSamples).round();
        _driveRealtimeVisemeFromRms(rms);
      }
    } else {
      // Küçük son chunk'larda da en az bir RMS — aksi halde dudak son hecede
      // donuyordu.
      double sumSq = 0;
      for (int i = 0; i < sampleCount; i++) {
        final double v = samples[i].toDouble();
        sumSq += v * v;
      }
      final int rms = sqrt(sumSq / sampleCount).round();
      _driveRealtimeVisemeFromRms(rms);
    }

    _ensurePcmStarted();
    _onPcmFeedRequest(0);
  }

  void _flushPcm() {
    _pcmChunks.clear();
    _pcmChunkOffset = 0;
    _pcmTotalSamples = 0;
    final c = _nativePcmDrainedCompleter;
    _nativePcmDrainedCompleter = null;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  Future<void> _waitForPcmDrainAndListen() async {
    if (!mounted) return;
    if (_callState != _CallState.speaking) return;
    if (_pcmDrainInFlight) return;
    _pcmDrainInFlight = true;
    try {
      final drainDeadline = DateTime.now().add(const Duration(seconds: 20));
      while (_pcmTotalSamples > 0 && DateTime.now().isBefore(drainDeadline)) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
      }
      if (_pcmTotalSamples > 0) {
        _flushPcm();
      }
      // setFeedThreshold ~480ms + son feed; yazılım kuyruğu 0 iken native
      // hâlâ çalınıyordu — kısa delay ile "ister misin" sonu kesiliyordu.
      await _awaitNativePcmFullyDrained();
      await Future<void>.delayed(
        const Duration(milliseconds: _pcmPostNativeDrainPadMs),
      );
      if (!mounted) return;
      _micGateOpenAt = DateTime.now().add(
        const Duration(milliseconds: _postSpeechCooldownMs),
      );
      if (_ws?.readyState == WebSocket.open) {
        _ws!.add(jsonEncode({'type': 'playback_done'}));
      }
      _aiSpeakingSince = null;
      if (mounted) setState(() => _callState = _CallState.listening);
      _clearVisemeTimers();
      _setRiveNumber('visemeNum', 0);
      _syncRiveTalk();
      _resetBargeInState();
      if (!_isMuted && _ws?.readyState == WebSocket.open) {
        unawaited(_rebindMicAfterRealtimeReady(afterAiPlayback: true));
      }
    } finally {
      _pcmDrainInFlight = false;
    }
  }

  Future<void> _toggleMute() async {
    final next = !_isMuted;
    setState(() => _isMuted = next);
    // Recorder'ı stop/start ETME — bu iOS'ta audio session'ı sıfırlıyor,
    // AI'ın o sırada konuştuğu sesi yarım saniye kesintiye uğratıyordu.
    // _micSub listener'ında zaten `if (_isMuted) return` var; ses zaten
    // sunucuya gitmiyor. Bu şekilde mute anlık ve sessiz kesinti yapmıyor.
    if (next && mounted && _callState != _CallState.speaking) {
      setState(() => _callState = _CallState.listening);
    }
    // Mic gate'i temizle: muted iken kapı zaten kapalı, unmute olunca
    // post-speech cooldown'dan kalan eski deadline kullanıcıyı bloklamasın.
    if (!next) {
      _micGateOpenAt = null;
    }
    _syncRiveTalk();
  }

  Future<void> _onEndPressed() async {
    final l10n = context.l10n;
    final shouldEnd = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset("assets/icons/cam_off.svg"),
                const SizedBox(height: 12),
                Text(
                  l10n.videoCallEndDialogTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 34 / 2,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21BC87),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(
                      l10n.videoCallEndDialogCancel,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 34 / 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF96989C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      l10n.videoCallEndDialogEnd,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 34 / 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldEnd != true || !mounted) return;
    await _showRateConversationSheet();
    if (!mounted) return;
    await _endCall(navigateToLogin: widget.isTrial);
  }

  Future<void> _showRateConversationSheet() async {
    final l10n = context.l10n;
    int selectedStars = 0;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.videoCallRateTitle,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 32 / 2,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: SvgPicture.asset("assets/icons/ic_close.svg"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.videoCallRateSubtitle,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 24 / 2,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: List.generate(5, (index) {
                      final isActive = index < selectedStars;
                      return GestureDetector(
                        onTap: () {
                          final stars = index + 1;
                          // setModalState kaldırıldı: rebuild → pop sırası
                          // gereksiz bir kare gecikme yaratıyordu.
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                          unawaited(_submitVideoCallRating(stars));
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: index == 4 ? 0 : 10),
                          child: SvgPicture.asset(
                            "assets/icons/star.svg",
                            color: isActive
                                ? const Color(0xFFFF9D2D)
                                : const Color(0xFFB8B8B8),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitVideoCallRating(int rating) async {
    // Notifier referansını await öncesinde al — ekran pop edildikten
    // sonra mounted=false olur ama notifier hâlâ geçerlidir.
    final notifier = ref.read(specialistsProvider.notifier);
    try {
      await _httpService.post(
        path: AppConstants.videoCallRateURL,
        body: {'consultantId': widget.specialist.id, 'rating': rating},
      );
      // Backend'deki güncel rating'i provider'a yansıt
      notifier.init();
    } catch (_) {
      // rating gönderimi başarısız olsa da çıkış akışını bloklamayalım
    }
  }

  Future<void> _endCall({bool navigateToLogin = false}) async {
    AnalyticsService.instance.capture(
      AnalyticsEvents.videoCallEnded,
      properties: {
        'consultant_id': widget.specialist.id,
        'is_trial': widget.isTrial,
        'duration_seconds': _secondsElapsed,
      },
    );

    _cancelAiSpeakingWatchdog();
    _cancelAiPlaybackIdleMonitor();
    _cancelConnectionReadyFallback();
    _clearVisemeTimers();
    _timer?.cancel();

    // Bağımsız temizlik işlemlerini paralel çalıştır.
    await Future.wait([
      _stopMicStream(),
      _wsSub?.cancel() ?? Future.value(),
      Future(() async {
        try {
          await _recorder.stop();
        } catch (_) {}
      }),
      Future(() async {
        try {
          await _ws?.close();
        } catch (_) {}
      }),
    ]);

    try {
      pcm.FlutterPcmSound.release();
    } catch (_) {}
    await _resetAudioSession();
    if (!mounted) return;
    if (navigateToLogin) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(PageRoutes.login, (route) => false);
      return;
    }
    Navigator.of(context).pop();
  }

  void _setError() {
    _cancelAiSpeakingWatchdog();
    _cancelAiPlaybackIdleMonitor();
    _clearVisemeTimers();
    if (mounted) setState(() => _callState = _CallState.error);
    _syncRiveTalk();
  }

  void _onRiveLoaded(rive.RiveLoaded loaded) {
    _riveController = loaded.controller;
    // Primary: DataBind ViewModel (works when the .riv file has a ViewModel
    // set up with data binding in the Rive editor).
    try {
      _riveViewModel = _riveController?.dataBind(rive.DataBind.auto());
    } catch (_) {
      _riveViewModel = null;
    }
    // Fallback: StateMachine inputs (for .riv files without a ViewModel,
    // where mouth properties are traditional SMI inputs on the state machine).
    // friendify_male_avatar_4.riv uses this path.
    if (_riveViewModel == null) {
      try {
        final wc = _riveController as rive.RiveWidgetController;
        _smTalk = wc.stateMachine.boolean('talk');
        _smVisemeNum = wc.stateMachine.number('visemeNum');
        _smDuration = wc.stateMachine.number('duration');
      } catch (_) {}
    }
    _syncRiveTalk();

    // Rive yüklendi → finalize'i dene. Sunucu hazırsa pickup'ı şimdi
    // tetikler; değilse server connection_success'i bekler.
    _riveReady = true;
    _maybeFinalizeCallOpen();
  }

  void _syncRiveTalk() {
    // Mute kullanıcı mic'ini kapatır; AI animasyonları etkilenmemeli.
    final bool shouldTalk = _callState == _CallState.speaking;

    // When state leaves speaking: close mouth and reset audio-active flag.
    // When entering speaking: do NOT open the mouth yet — wait for the first
    // real audio chunk in _driveRealtimeVisemeFromRms (prevents the avatar
    // mouth opening before any sound arrives).
    if (!shouldTalk) {
      _riveAudioActive = false;
      _rmsSmoothed = 0.0;
      _visemeApplied = 0;
      _visemeAppliedAt = null;
      // Önce kısa blend süresi, sonra talk kapat — Rive SM'de uzun süre
      // "konuşuyor" pozunda takılı kalma (kullanıcının ~1 sn lag şikayeti).
      _setRiveNumber('duration', _riveTalkCloseBlendMs);
      _setRiveBool('talk', false);
      _setRiveNumber('visemeNum', 0.0);
    }
  }

  void _setRiveBool(String key, bool value) {
    final vm = _riveViewModel;
    if (vm != null) {
      bool applied = false;
      try {
        final b = vm.boolean(key);
        if (b != null) {
          b.value = value;
          applied = true;
        }
      } catch (_) {}
      try {
        for (final prop in vm.properties) {
          if (prop.name == key) {
            (prop as dynamic).value = value;
            applied = true;
            break;
          }
        }
      } catch (_) {}
      if (applied) return;
    }
    // StateMachine inputs path
    if (key == 'talk') _smTalk?.value = value;
  }

  @override
  void dispose() {
    _cancelConnectionReadyFallback();
    _cancelAiSpeakingWatchdog();
    _cancelAiPlaybackIdleMonitor();
    _trialTimer?.cancel();
    _trialTimer = null;
    unawaited(_persistVideoTrialUsageOnce());
    _timer?.cancel();
    _clearVisemeTimers();
    // Cache'den alınan loader'lar global RivePreloadService'e aittir — dispose etme.
    if (_ownsRiveFileLoader) _riveFileLoader.dispose();
    _cameraController?.dispose();
    _cameraController = null;
    _stopMicStream();
    _wsSub?.cancel();
    _recorder.dispose();
    _ws?.close();
    try {
      pcm.FlutterPcmSound.release();
    } catch (_) {}
    _resetAudioSession();
    super.dispose();
  }

  // --- UI KISMI (Figma Tasarımı) ---

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      // Sadece trial akışında geri kapalı olsun.
      // Login/premium akışında kullanıcı geri dönebilsin.
      canPop: !widget.isTrial,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: _buildVideoCard()),
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTopChip(
                          leading: SvgPicture.asset("assets/icons/recor.svg"),
                          label: widget.isTrial
                              ? (_timer != null
                                    ? _formatTrialRemaining(
                                        (_videoTrialBudgetSeconds -
                                                _secondsElapsed)
                                            .clamp(0, _videoTrialBudgetSeconds),
                                      )
                                    : _formatTrialRemaining(
                                        _videoTrialBudgetSeconds,
                                      ))
                              : _formatElapsed(_secondsElapsed),
                          isTimer: true,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTopChip(
                              leading: SvgPicture.asset(
                                "assets/icons/ic_lcok3.svg",
                                width: 14.w,
                                height: 14.h,
                                fit: BoxFit.scaleDown,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                              label: l10n.videoCallEncrypted,
                            ),
                            SizedBox(height: 8.h),
                            _buildSelfPreview(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                _buildBottomPanel(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopChip({
    required Widget leading,
    required String label,
    bool isTimer = false,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF000000).withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          SizedBox(width: 6.w),
          Text(
            label,
            style: isTimer
                ? TextStyle(
                    fontFamily: 'Geist',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.w,
                    letterSpacing: -0.3,
                    height: 18 / 14,
                  )
                : TextStyle(
                    fontFamily: 'Geist',
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.w,
                    letterSpacing: 0,
                    height: 18 / 14,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfPreview() {
    final controller = _cameraController;
    final ready = controller != null && controller.value.isInitialized;

    Widget inner;
    if (!_cameraSetupCompleted) {
      // Önceden 24.w idi ve container'ın merkezine değil sol-üste yapışıyordu;
      // PIP kutusunda orantısız büyük gözüküyordu. 16dp + Center ile çözüldü.
      inner = const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.6,
            color: Colors.white54,
          ),
        ),
      );
    } else if (!_cameraAccessGranted) {
      inner = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _retryCameraPermission,
        child: Icon(
          Icons.videocam_off_rounded,
          color: Colors.white54,
          size: 32.w,
        ),
      );
    } else if (!ready) {
      inner = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _attachCamera(_cameraIndex),
        child: Icon(Icons.refresh_rounded, color: Colors.white54, size: 28.w),
      );
    } else {
      final CameraController c = controller;
      // Kameranın kendi preview boyutu — FittedBox cover ile PIP kutusuna sığar.
      // Kasmayı azaltmak için ekstra wrapping/border/overlay yok.
      inner = FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: c.value.previewSize!.height,
          height: c.value.previewSize!.width,
          child: CameraPreview(c),
        ),
      );
    }

    // RepaintBoundary en dışta: UI'nin geri kalanı (Rive avatar, blur, vs.)
    // yeniden çizildiğinde kamera tekrar render edilmiyor.
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: SizedBox(width: 88.w, height: 120.h, child: inner),
      ),
    );
  }

  Widget _buildVideoCard() {
    // YAPI: AnimatedSwitcher + KeyedSubtree(placeholder/rive) yerine
    // Stack + AnimatedOpacity. Sebep:
    //   • Eski yapıda Rive widget'ı SADECE _callState != connecting olunca
    //     mount oluyordu. "Telefon açıldı" anında ilk kez mount → ilk paint
    //     → iOS'ta ~150-300 ms blocking jank.
    //   • Yeni yapıda Rive widget'ı ringing sırasında zaten mount: arka
    //     planda paint ediliyor ama placeholder üstüne tam opaque oturuyor.
    //   • connection_success'te placeholder fade-out (140 ms) → arkadaki
    //     Rive ANINDA görünür hale geliyor, mount/first-paint maliyeti yok.
    final bool showAvatar =
        _callState != _CallState.connecting && _callState != _CallState.error;
    return Container(
      color: const Color(0xFF22C987),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: KeyedSubtree(
              key: ValueKey<int>(_riveLoaderKey),
              child: rive.RiveWidgetBuilder(
                fileLoader: _riveFileLoader,
                onLoaded: _onRiveLoaded,
                builder: (context, state) {
                  return switch (state) {
                    rive.RiveLoading() => const SizedBox.shrink(),
                    rive.RiveFailed() => const SizedBox.shrink(),
                    rive.RiveLoaded() => rive.RiveWidget(
                      controller: state.controller,
                      fit: rive.Fit.cover,
                      alignment: const Alignment(0, 0.35),
                    ),
                  };
                },
              ),
            ),
          ),
          IgnorePointer(
            ignoring: showAvatar,
            child: AnimatedOpacity(
              opacity: showAvatar ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: _buildRiveLoadingPlaceholder(
                showSpinner: _callState != _CallState.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiveLoadingPlaceholder({bool showSpinner = true}) {
    final photoUrl = widget.specialist.photoURL;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Danışman fotoğrafını bulanık arka plan olarak göster.
          // Blur kenarlarındaki şeffaflık artefaktını önlemek için görsel
          // container'dan taşırılır (negatif offset), ClipRect keser.
          if (photoUrl.isNotEmpty)
            // Bulanık zemin: sigma 24 → 14 düşürüldü. iOS GPU yükü ~%60
            // azalıyor; yine de kenardaki yüzü güzel yumuşatıyor. Karartma
            // alpha'sı hafifçe artırıldı ki düşük blur'la birlikte görsel
            // his aynı kalsın.
            Positioned(
              top: -24,
              bottom: -24,
              left: -24,
              right: -24,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          // Hafif karartma
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
              ),
            ),
          ),
          // Ortada yuvarlak fotoğraf + yükleniyor göstergesi
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96.w,
                  height: 96.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const Icon(
                              Icons.person_rounded,
                              color: Colors.white54,
                              size: 48,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: Colors.white54,
                            size: 48,
                          ),
                  ),
                ),
                SizedBox(height: 24.h),
                if (showSpinner)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    final l10n = context.l10n;
    // BackdropFilter iOS'ta GPU-yoğun: sigma 20 → 10 düşürüldü, görsel
    // farkı çıplak gözle hissedilmiyor ama ilk frame ve sonraki rebuild'ler
    // (1 sn'lik timer setState'i) belirgin şekilde ucuzlıyor.
    // RepaintBoundary, bottom panel'in üst ağaçtan bağımsız repaint
    // edilmesini sağlar — Rive avatar her frame yenilense de buradaki
    // blur tekrar render edilmek zorunda kalmaz.
    return RepaintBoundary(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: 20.h,
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF000000).withValues(alpha: 0.35),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _resolveCoachName(),
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 28.w,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _resolveCoachRole(),
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 16.w,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Center(
                        child: _controlButton(
                          icon: SvgPicture.asset("assets/icons/turn.svg"),
                          label: l10n.videoCallTurnCamera,
                          onTap: _flipCamera,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _controlButton(
                          icon: SvgPicture.asset("assets/icons/end.svg"),
                          label: l10n.videoCallEndButton,
                          isPrimary: true,
                          onTap: _onEndPressed,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _controlButton(
                          icon: _isMuted
                              ? Container(
                                  width: 52.0,
                                  height: 52.0,
                                  padding: const EdgeInsets.all(
                                    10.0,
                                  ), // Figma'daki 10px Padding
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(
                                      0.5,
                                    ), // #000000 %50 Opacity
                                    shape: BoxShape
                                        .circle, // Radius: 999px için en pratik yol
                                    border: Border.all(
                                      color: Colors.white.withOpacity(
                                        0.5,
                                      ), // #FFFFFF %50 Opacity
                                      width: 1.0, // 1px Border
                                    ),
                                  ),
                                  child: SvgPicture.asset(
                                    "assets/icons/microphone-slash.svg",
                                  ),
                                )
                              : SvgPicture.asset("assets/icons/mute.svg"),
                          label: l10n.videoCallMute,
                          onTap: () => _toggleMute(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(onTap: onTap, child: icon),
        SizedBox(height: 4.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Geist',
            color: Colors.white,
            fontSize: 12.w,
            fontWeight: FontWeight.w500,
            height: 18 / 12,
          ),
        ),
      ],
    );
  }

  String _resolveCoachName() {
    final names = widget.specialist.names;
    final langCode = context.langCode;
    return names[langCode]?.toString() ??
        names['en']?.toString() ??
        names.values.first.toString();
  }

  String _resolveCoachRole() {
    return JobConvert(widget.specialist.job, context).call();
  }

  String _formatElapsed(int sec) {
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Deneme modunda kalan süre (görüşme bağlandıktan sonra geri sayım).
  String _formatTrialRemaining(int remainingSec) {
    final m = (remainingSec ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
