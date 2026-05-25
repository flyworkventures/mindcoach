import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart' as pcm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/Analytics/analytics_service.dart';
import 'package:mindcoach/Services/TrialQuotaService/trial_quota_service.dart';
import 'package:mindcoach/core/analytics/analytics_events.dart';
import 'package:mindcoach/core/locale/locale_provider.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/call_permissions.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/core/utils/realtime_auth_token.dart';
import 'package:mindcoach/core/utils/revenuecat_paywalls.dart';
import 'package:mindcoach/l10n/app_localizations.dart';
import 'package:mindcoach/models/consultant_model.dart';
import 'package:record/record.dart';

// ─── State enum ───────────────────────────────────────────────────────────────
enum _CallState { connecting, listening, thinking, speaking, error }

// ─── Screen ───────────────────────────────────────────────────────────────────
class VoiceCallScreen extends ConsumerStatefulWidget {
  final ConsultantModel specialist;
  const VoiceCallScreen({super.key, required this.specialist});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen>
    with TickerProviderStateMixin {
  // ── WebSocket ──────────────────────────────────────────────────────────────
  WebSocket? _ws;
  StreamSubscription? _wsSub;

  // ── Microphone (PCM16 16kHz streaming) ─────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSub;
  bool _micStreamActive = false;

  // ── PCM playback (flutter_pcm_sound) ───────────────────────────────────────
  static const int _sampleRate = 24000;
  static const int _channels = 1;
  // Eski Queue<int> her sample için boxed int allocation yapıyordu;
  // 24k sample/sn × ~25 chunk/sn = 600k allocation/sn = ana CPU bottleneck.
  // Yeni: gelen her PCM mesajı tek Int16List olarak enqueue, feed sırasında
  // ön taraftan offset ile okunur (zero-allocation).
  final Queue<Int16List> _pcmChunks = Queue<Int16List>();
  int _pcmChunkOffset = 0;
  int _pcmTotalSamples = 0;
  bool _pcmSetup = false;
  bool _pcmStarted = false;

  // ── Dial / ring tone while connecting ──────────────────────────────────────
  bool _isRinging = false;
  int _ringSamplePos = 0;
  static const int _ringOnSamples = _sampleRate * 2;
  static const int _ringOffSamples = _sampleRate * 4;
  static const int _ringPeriodSamples = _ringOnSamples + _ringOffSamples;

  // ── State ──────────────────────────────────────────────────────────────────
  _CallState _callState = _CallState.connecting;
  int _secondsElapsed = 0;
  Timer? _durationTimer;
  bool _voiceTrialHardStopShown = false;

  /// Sunucu ai_response_complete göndermezse speaking'de takılı kalınıyordu; mikrofon ikinci turda ölüyordu.
  Timer? _aiSpeakingWatchdog;

  /// Son AI PCM baytının geldiği an — akış kesilince [ai_response_complete] olmadan dinlemeye dönüş.
  DateTime? _lastAiPcmReceivedAt;
  Timer? _aiPlaybackIdleTimer;

  /// AI cümleleri arasında doğal 1s civarı boşluklar olabiliyor; çok kısa
  /// idle eşik konuşma ortasında speaking→listening geçişine sebep olur.
  static const int _aiPlaybackIdleMs = 1600;

  /// Son PCM’den bu kadar ms geçtiyse ve kuyruk hâlâ doluysa oynatıcı takılmıştır — zorla boşalt.
  static const int _aiPlaybackStuckQueueFlushMs = 3000;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  static const MethodChannel _audioSessionChannel = MethodChannel(
    'mindcoach/voice_audio_session',
  );

  // ───────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapVoiceCall());
  }

  Future<void> _bootstrapVoiceCall() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      final ok = await ensureMicrophonePermission();
      if (!mounted) return;
      if (!ok) {
        _setError();
        return;
      }
    }
    // 🎤 PREMIUM KONTROLÜ: Sesli görüşme sadece premium kullanıcılara açık
    if (!ref.read(AllProviders.premiumProvider).isPremium) {
      await presentProOffersPaywall();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await _configureAudioSession();
    await _initPcmPlayer();
    await _connect();
    await _configureAudioSession();
    await _startRingTone();
    // Proximity sensor — only on the earpiece route, mirroring the iPhone
    // Phone app: holding the device to your ear blanks the screen, switching
    // to speaker turns the proximity logic off.
    await _setProximityMonitoring(!_isSpeakerOn);
  }

  // ── iOS / Android ses oturumu (MainActivity + AppDelegate MethodChannel) ──
  /// Native AVAudioSession.setCategory + setActive ÇOK pahalı işlemler;
  /// her çağrıda PCM playback "underrun" yaşıyordu çünkü session geçici
  /// olarak interrupted state'e geçiyordu. Birden fazla yerden ardışık
  /// çağrılar 250ms içindeyse tek seferde toplu yapılıyor.
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
      final mode = await _audioSessionChannel.invokeMethod<String>(
        'configureForVoiceCall',
      );
      debugPrint('🔊 [AUDIO] session ready — mode=$mode');
      if (_isSpeakerOn) {
        try {
          await _audioSessionChannel.invokeMethod('setSpeakerOn', {'on': true});
        } catch (_) {}
      }
      _lastAudioSessionConfigAt = DateTime.now();
    } catch (e) {
      debugPrint('⚠️ [AUDIO] session config failed: $e');
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

  // ── Proximity sensor (real-phone "hold to ear → screen off") ──────────────
  // iOS: UIDevice.proximityMonitoringEnabled — OS handles the dim itself.
  // Android: PROXIMITY_SCREEN_OFF_WAKE_LOCK — same wake lock the stock
  // Phone app uses to blank the display + lock touch input.
  Future<void> _setProximityMonitoring(bool on) async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      await _audioSessionChannel.invokeMethod('setProximityMonitoring', {
        'on': on,
      });
    } catch (e) {
      debugPrint('⚠️ [AUDIO] proximity toggle failed: $e');
    }
  }

  // ── PCM player setup ───────────────────────────────────────────────────────
  Future<void> _initPcmPlayer() async {
    try {
      await pcm.FlutterPcmSound.setup(
        sampleRate: _sampleRate,
        channelCount: _channels,
        iosAudioCategory: pcm.IosAudioCategory.playAndRecord,
      );
      // 250ms → 400ms: hafif network jitter'da bile tampon boşalıp ses
      // kesintisi yapıyordu. 400ms tolerans yaklaşık bir kelime aksamayı
      // maskeler. Latency artışı yok; PCM playback yine gelir gelmez başlar.
      await pcm.FlutterPcmSound.setFeedThreshold((_sampleRate * 0.40).round());
      pcm.FlutterPcmSound.setFeedCallback(_onPcmFeedRequest);
      _pcmSetup = true;
      await _configureAudioSession();
    } catch (e) {
      debugPrint('❌ [PCM] setup error: $e');
    }
  }

  Future<void> _ensurePcmStarted() async {
    if (!_pcmSetup || _pcmStarted) return;
    try {
      pcm.FlutterPcmSound.start();
      _pcmStarted = true;
    } catch (e) {
      debugPrint('❌ [PCM] start error: $e');
    }
  }

  void _onPcmFeedRequest(int remainingFrames) {
    if (_isRinging) {
      _feedRingToneChunk();
      return;
    }

    if (_pcmTotalSamples == 0) return;

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
      // setRange = native memcpy fastpath
      samples.setRange(dst, dst + copy, chunk, _pcmChunkOffset);
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
    _pcmTotalSamples -= toSend;
    if (toSend > 0) {
      _lastPlaybackRms = sqrt(sumSq / toSend).round();
    }
    pcm.FlutterPcmSound.feed(
      pcm.PcmArrayInt16(bytes: samples.buffer.asByteData()),
    );
  }

  // ── Ring tone generator ────────────────────────────────────────────────────
  Future<void> _startRingTone() async {
    if (_isRinging) return;
    _isRinging = true;
    _ringSamplePos = 0;
    await _ensurePcmStarted();
    _feedRingToneChunk();
  }

  void _stopRingTone() {
    if (!_isRinging) return;
    _isRinging = false;
    _flushPcm();
  }

  // ── "Phone picked up" chime ────────────────────────────────────────────────
  void _playPickupChime() {
    if (!_pcmStarted) return;
    const int totalSamples = _sampleRate ~/ 4;
    final Int16List samples = Int16List(totalSamples);
    final int half = totalSamples ~/ 2;
    for (int i = 0; i < totalSamples; i++) {
      final double t = i / _sampleRate.toDouble();
      final double freq = i < half ? 660.0 : 880.0;
      double s = sin(2 * pi * freq * t) * 0.28;
      const int fade = 360;
      final int localI = i < half ? i : i - half;
      final int localLen = half;
      if (localI < fade) {
        s *= localI / fade;
      } else if (localI > localLen - fade) {
        s *= (localLen - localI) / fade;
      }
      samples[i] = (s * 32767).round().clamp(-32767, 32767);
    }
    _pcmChunks.add(samples);
    _pcmTotalSamples += totalSamples;
    _onPcmFeedRequest(0);
  }

  void _feedRingToneChunk() {
    if (!_isRinging || !_pcmStarted) return;
    const int chunkSamples = 6000;
    final Int16List samples = Int16List(chunkSamples);
    const double f1 = 440.0;
    const double f2 = 480.0;
    const double amp = 0.22;
    for (int i = 0; i < chunkSamples; i++) {
      final int pos = _ringSamplePos + i;
      final int phase = pos % _ringPeriodSamples;
      double sample = 0;
      if (phase < _ringOnSamples) {
        final double t = pos / _sampleRate.toDouble();
        sample = (sin(2 * pi * f1 * t) + sin(2 * pi * f2 * t)) * 0.5 * amp;
        const int fade = 1200;
        if (phase < fade) {
          sample *= phase / fade;
        } else if (phase > _ringOnSamples - fade) {
          sample *= (_ringOnSamples - phase) / fade;
        }
      }
      samples[i] = (sample * 32767).round().clamp(-32767, 32767);
    }
    _ringSamplePos += chunkSamples;
    try {
      pcm.FlutterPcmSound.feed(
        pcm.PcmArrayInt16(bytes: samples.buffer.asByteData()),
      );
    } catch (_) {}
  }

  // ── WebSocket connection ───────────────────────────────────────────────────
  Future<void> _connect() async {
    try {
      final token = await ensureRealtimeAuthToken(ref);

      final deviceLang = ref.read(localeProvider.notifier).getLanguageCode();

      final url =
          '${AppConstants.wsBaseURL}'
          '?token=${Uri.encodeQueryComponent(token)}'
          '&consultantId=${widget.specialist.id}'
          '&lang=${Uri.encodeQueryComponent(deviceLang)}';

      _ws = await WebSocket.connect(url);

      _wsSub = _ws!.listen(
        _onWsData,
        onError: (e) {
          _setError();
        },
        onDone: () {
          if (mounted && _callState != _CallState.error) {
            Navigator.of(context).pop();
          }
        },
        cancelOnError: false,
      );

      await _startMicStream();
    } catch (e) {
      _setError();
    }
  }

  // ── Barge-in detection (client-side) ───────────────────────────────────────
  //
  // While the AI is speaking we completely STOP forwarding mic audio to the
  // server. iOS AEC is imperfect — enough residual echo was leaking through
  // to trigger the server's VAD, which was causing the AI to cut itself
  // off on every other sentence.
  //
  // Instead, we do barge-in detection locally: compute RMS on each mic
  // chunk, and if it stays above a high threshold for ~200ms it's almost
  // certainly the user actually speaking (post-AEC echo is far below that
  // loudness). At that point we fire an explicit `barge_in_request` — the
  // server cancels the current response, tells us to flush our PCM queue,
  // and the mic starts forwarding again as soon as we drop out of the
  // `speaking` state.
  //
  // A small "pre-roll" buffer saves the last ~500ms of mic audio so that
  // after barge-in fires we can replay those chunks to the server, i.e.
  // the first half-second of the user's interrupting speech isn't lost.
  // ChatGPT-vari hız: kullanıcı konuşur konuşmaz AI sussun.
  //  - Taban eşik düşük tutulup playback RMS oranı sıkılaştırıldı, yani
  //    sessiz AI anlarında bile yumuşak ses yakalanır, gürültülü anlarda
  //    echo daha iyi reddedilir.
  //  - 100ms sustained → toplam barge-in gecikmesi 250 + 100 + ~250ms
  //    flush = ~600ms, ChatGPT hissine yakın.
  //  - Ratio 2.0x: typical AEC residue ~playback*0.4, dolayısıyla 2.0
  //    çarpanı ile echo eşiği konuşma seviyesinin altında kalır.
  static const int _bargeInSustainedMs = 100;
  static const int _preRollMaxMs = 500;

  // AI sustuktan sonra hoparlör akustik kuyruğunun mikrofona dönüp
  // sahte bir "kullanıcı konuştu" tetiklemesine yol açmaması için
  // mikrofon kapısı bu kadar kapalı tutulur. AEC + 250ms tipik oda
  // sönümü için yeterli; daha uzun süre kullanıcı yanıt veremiyor hissi.
  static const int _postSpeechCooldownMs = 250;

  int _highRmsStreakMs = 0;
  bool _bargeInSent = false;
  final Queue<_AudioChunk> _preRoll = Queue<_AudioChunk>();
  DateTime? _micGateOpenAt;
  DateTime? _aiSpeakingSince;
  int _lastPlaybackRms = 0;

  // Asgari AI konuşma süresi: ilk 250ms'i koruyoruz ki "merhaba" gibi
  // başlangıç hece sırasında yapay tetikleme olmasın; sonrasında her an
  // kesilebilir.
  static const int _bargeInMinAiSpeakingMs = 250;
  static const int _bargeInRmsThresholdEarpiece = 1700;
  static const int _bargeInRmsThresholdSpeaker = 2400;
  static const double _bargeInPlaybackRatio = 2.0;

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

  // ── Microphone → PCM16 → WebSocket ─────────────────────────────────────────
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
      if (chunk.isEmpty) return;
      // PCM16 → must be even byte length. record_ios occasionally emits an
      // odd-size buffer at stream start; that would make OpenAI reject the
      // whole realtime session with "Invalid 'audio'". Drop it here.
      if (chunk.length % 2 != 0) return;
      if (_isMuted) return;
      // Zil çalarken eskiden tamamen kesiyorduk; connection_success gecikince
      // kullanıcı hiç konuşamıyordu. Echo riski AEC ile tolere edilir.
      if (_ws?.readyState != WebSocket.open) return;

      // Post-speech cooldown: the AI just stopped speaking, but the
      // acoustic tail from the phone's speaker is still in the room.
      // Drop any mic audio for a short window so echo-tail phonemes
      // don't reach Whisper and get transcribed as user speech.
      final gateUntil = _micGateOpenAt;
      if (gateUntil != null) {
        if (DateTime.now().isBefore(gateUntil)) {
          return;
        }
        _micGateOpenAt = null;
      }

      if (_callState == _CallState.speaking) {
        // Echo-proof path: don't forward ANY mic audio while AI speaks.
        // Instead watch local RMS to detect a genuine barge-in attempt.
        final int durMs = _chunkDurationMs(chunk);
        final int rms = _computePcm16Rms(chunk);
        final int dynamicThreshold = _isSpeakerOn
            ? _bargeInRmsThresholdSpeaker
            : _bargeInRmsThresholdEarpiece;
        final int echoAwareThreshold = max(
          dynamicThreshold,
          (_lastPlaybackRms * _bargeInPlaybackRatio).round(),
        );
        final int speakingForMs = _aiSpeakingSince == null
            ? 0
            : DateTime.now().difference(_aiSpeakingSince!).inMilliseconds;

        // Keep a small pre-roll so we don't lose the user's first words.
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
            debugPrint(
              '🎤 [VOICE] barge-in detected (rms=$rms '
              'threshold=$echoAwareThreshold '
              'playbackRms=$_lastPlaybackRms '
              'streak=${_highRmsStreakMs}ms)',
            );
            _bargeInSent = true;
            _cancelAiSpeakingWatchdog();
            _cancelAiPlaybackIdleMonitor();
            _flushPcm();
            if (_ws?.readyState == WebSocket.open) {
              _ws!.add(jsonEncode({'type': 'barge_in_request'}));
              // Flush the pre-roll so the server hears the start of the
              // user's interruption, not just whatever comes after. Skip
              // empty / odd-sized chunks — OpenAI rejects those outright.
              for (final c in _preRoll) {
                if (c.bytes.isEmpty) continue;
                if (c.bytes.length % 2 != 0) continue;
                _ws!.add(c.bytes);
              }
              _preRoll.clear();
            }
            if (mounted) setState(() => _callState = _CallState.listening);
          }
        } else {
          _highRmsStreakMs = 0;
        }
        return; // NEVER forward during AI speech
      }

      // AI not speaking — normal path, forward everything.
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

  // ── WebSocket → Flutter ────────────────────────────────────────────────────
  void _onWsData(dynamic data) {
    if (data is String) {
      try {
        _handleJson(jsonDecode(data) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('⚠️ [VOICE] JSON parse error: $e');
      }
    } else if (data is List<int>) {
      _enqueuePcmBytes(Uint8List.fromList(data));
    }
  }

  Future<void> _onRealtimeConnectionReady() async {
    if (!mounted) return;
    AnalyticsService.instance.capture(
      AnalyticsEvents.voiceCallStarted,
      properties: {'consultant_id': widget.specialist.id},
    );
    _cancelAiSpeakingWatchdog();
    _cancelAiPlaybackIdleMonitor();
    _stopRingTone();
    await _configureAudioSession();
    _playPickupChime();
    if (mounted) setState(() => _callState = _CallState.listening);
    _aiSpeakingSince = null;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsElapsed++);
      final premiumState = ref.read(AllProviders.premiumProvider);
      if (premiumState.isPremium) return;
      unawaited(() async {
        await TrialQuotaService.instance.addVoiceSeconds(1);
        final remaining = await TrialQuotaService.instance
            .voiceSecondsRemaining();
        if (!mounted || _voiceTrialHardStopShown) return;
        if (remaining <= 0) {
          _voiceTrialHardStopShown = true;
          _durationTimer?.cancel();
          await presentProOffersPaywall();
          if (mounted) await _endCall();
        }
      }());
    });

    if (!_isMuted) {
      await _rebindMicAfterRealtimeReady();
    }
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
    final base = _lastAiPcmReceivedAt ?? _aiSpeakingSince;
    if (base == null) return;

    final stallMs = DateTime.now().difference(base).inMilliseconds;

    final bool queueHasData = _pcmTotalSamples > 0;
    if (queueHasData && stallMs < _aiPlaybackStuckQueueFlushMs) {
      return;
    }
    if (queueHasData && stallMs >= _aiPlaybackStuckQueueFlushMs) {
      debugPrint(
        '🔊 [VOICE] playback queue stuck — flush ($stallMs ms since last PCM)',
      );
      _flushPcm();
    }

    if (stallMs < _aiPlaybackIdleMs) return;

    debugPrint(
      '🔊 [VOICE] playback idle fallback → drain/listen '
      '(sunucu ai_response_complete eksik olabilir)',
    );
    _cancelAiPlaybackIdleMonitor();
    _cancelAiSpeakingWatchdog();
    unawaited(_waitForPcmDrainAndListen());
  }

  void _armAiPlaybackIdleMonitor() {
    _cancelAiPlaybackIdleMonitor();
    _lastAiPcmReceivedAt = null;
    _aiPlaybackIdleTimer = Timer.periodic(const Duration(milliseconds: 200), (
      _,
    ) {
      _evaluateAiPlaybackIdleFallback();
    });
  }

  /// [ai_response_complete] gelmezse [speaking]'de kalınır; normal konuşma PCM'i iletilmez (yalnızca barge-in).
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
    debugPrint('⚠️ [VOICE] speaking watchdog → drain/listen + playback_done');
    unawaited(_waitForPcmDrainAndListen());
  }

  Future<void> _rebindMicAfterRealtimeReady() async {
    await _stopMicStream();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _ws?.readyState != WebSocket.open || _isMuted) return;
    await _configureAudioSession();
    await _startMicStream();
  }

  void _handleJson(Map<String, dynamic> msg) {
    final type = msg['type'] as String? ?? '';

    switch (type) {
      case 'connection_success':
        unawaited(_onRealtimeConnectionReady());
        break;

      case 'user_speech_started':
        if (_isMuted) break;
        if (mounted && _callState != _CallState.speaking) {
          setState(() => _callState = _CallState.listening);
        }
        break;

      case 'user_speech_stopped':
        if (_isMuted) break;
        if (mounted) setState(() => _callState = _CallState.thinking);
        break;

      case 'ai_speaking_start':
        _stopRingTone();
        _configureAudioSession();
        _ensurePcmStarted();
        _resetBargeInState();
        _aiSpeakingSince = DateTime.now();
        if (mounted) setState(() => _callState = _CallState.speaking);
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
        if (mounted) setState(() => _callState = _CallState.listening);
        if (!_isMuted && _ws?.readyState == WebSocket.open) {
          unawaited(_rebindMicAfterRealtimeReady());
        }
        break;

      case 'error':
        _setError();
        break;

      default:
        break;
    }
  }

  // ── PCM queue helpers ──────────────────────────────────────────────────────
  void _enqueuePcmBytes(Uint8List bytes) {
    _lastAiPcmReceivedAt = DateTime.now();
    final int sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) return;
    // Tek allocation; sample-by-sample boxing yok.
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
    _ensurePcmStarted();
    _onPcmFeedRequest(0);
  }

  void _flushPcm() {
    _pcmChunks.clear();
    _pcmChunkOffset = 0;
    _pcmTotalSamples = 0;
  }

  Future<void> _waitForPcmDrainAndListen() async {
    if (!mounted) return;
    if (_callState != _CallState.speaking) return;

    final drainDeadline = DateTime.now().add(const Duration(seconds: 20));
    while (_pcmTotalSamples > 0 && DateTime.now().isBefore(drainDeadline)) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }
    if (_pcmTotalSamples > 0) {
      debugPrint('⚠️ [VOICE] PCM drain timeout — kuyruk zorla temizleniyor');
      _flushPcm();
    }
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    // Open the mic gate AFTER a short echo-tail cooldown so the server
    // doesn't see phantom transcripts from the speaker's acoustic decay.
    _micGateOpenAt = DateTime.now().add(
      const Duration(milliseconds: _postSpeechCooldownMs),
    );
    if (_ws?.readyState == WebSocket.open) {
      _ws!.add(jsonEncode({'type': 'playback_done'}));
    }
    if (mounted && _callState == _CallState.speaking) {
      setState(() => _callState = _CallState.listening);
    }
    _aiSpeakingSince = null;
    _resetBargeInState();
    if (!_isMuted && _ws?.readyState == WebSocket.open) {
      unawaited(_rebindMicAfterRealtimeReady());
    }
  }

  void _requestBargeIn() {
    if (_isMuted) return;
    if (_callState != _CallState.speaking) return;
    if (_ws?.readyState != WebSocket.open) return;
    _cancelAiSpeakingWatchdog();
    _cancelAiPlaybackIdleMonitor();
    _flushPcm();
    _ws!.add(jsonEncode({'type': 'barge_in_request'}));
    if (mounted) setState(() => _callState = _CallState.listening);
    unawaited(_rebindMicAfterRealtimeReady());
  }

  // ── End call / cleanup ─────────────────────────────────────────────────────
  Future<void> _endCall() async {
    AnalyticsService.instance.capture(
      AnalyticsEvents.voiceCallEnded,
      properties: {
        'consultant_id': widget.specialist.id,
        'duration_seconds': _secondsElapsed,
      },
    );
    _cancelAiSpeakingWatchdog();
    _cancelAiPlaybackIdleMonitor();
    _stopRingTone();
    _durationTimer?.cancel();
    await _stopMicStream();
    await _wsSub?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {}
    try {
      _ws?.close();
    } catch (_) {}
    try {
      pcm.FlutterPcmSound.release();
    } catch (_) {}
    await _setProximityMonitoring(false);
    await _resetAudioSession();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleMute() async {
    final next = !_isMuted;
    setState(() => _isMuted = next);
    // Recorder'ı stop/start ETME — bu iOS'ta audio session'ı sıfırlayıp
    // AI'ın o anda konuştuğu sesi yarım saniye kesintiye uğratıyordu.
    // _micSub listener'ında zaten `if (_isMuted) return` var; ses zaten
    // sunucuya gitmiyor. Mute artık anlık ve sessiz kesinti yapmıyor.
    if (next && mounted && _callState != _CallState.speaking) {
      setState(() => _callState = _CallState.listening);
    }
    if (!next) {
      _micGateOpenAt = null;
    }
  }

  // ── Speaker / earpiece toggle ──────────────────────────────────────────────
  // Matches the iPhone Phone app UX: the call starts on the earpiece, the
  // user taps the speaker button to switch to loudspeaker and taps again
  // to switch back.
  Future<void> _toggleSpeaker() async {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    final next = !_isSpeakerOn;
    try {
      await _audioSessionChannel.invokeMethod('setSpeakerOn', {'on': next});
      if (mounted) setState(() => _isSpeakerOn = next);
      // Earpiece mode → proximity ON (hold to ear blanks screen).
      // Speaker mode  → proximity OFF (device away from face anyway).
      await _setProximityMonitoring(!next);
    } catch (e) {
      debugPrint('⚠️ [AUDIO] speaker toggle failed: $e');
    }
  }

  void _setError() {
    _cancelAiSpeakingWatchdog();
    _cancelAiPlaybackIdleMonitor();
    _stopRingTone();
    if (mounted) setState(() => _callState = _CallState.error);
  }

  @override
  void dispose() {
    _cancelAiSpeakingWatchdog();
    _cancelAiPlaybackIdleMonitor();
    _durationTimer?.cancel();
    _wsSub?.cancel();
    _stopMicStream();
    _recorder.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    try {
      _ws?.close();
    } catch (_) {}
    try {
      pcm.FlutterPcmSound.release();
    } catch (_) {}
    // Make sure proximity sensor is released even if user closes the screen
    // via system back / swipe-down without going through _endCall.
    _setProximityMonitoring(false);
    _resetAudioSession();
    super.dispose();
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────
  String _coachName() {
    final lang = ref.read(localeProvider.notifier).getLanguageCode();
    final names = widget.specialist.names;
    return names[lang] as String? ??
        names['en'] as String? ??
        (names.values.isNotEmpty ? names.values.first.toString() : 'Aria Flux');
  }

  String _coachTitle(BuildContext context) {
    final String job = widget.specialist.job.trim();
    if (job.isNotEmpty) {
      return JobConvert(job, context).call();
    }

    // Fallback: bazı kayıtlarda `job` boş ama `roles` dolu olabiliyor.
    final roles = widget.specialist.roles;
    if (roles != null && roles.isNotEmpty) {
      final dynamic firstRole = roles.first;
      final String roleKey = firstRole is String
          ? firstRole
          : (firstRole is Map && firstRole['key'] is String
                ? firstRole['key'] as String
                : '');
      if (roleKey.isNotEmpty) {
        return JobConvert(roleKey, context).call();
      }
    }

    // Localized generic fallback (hardcoded "Individual Coach" yerine).
    return AppLocalizations.of(context)!.coachesTitle;
  }

  String _statusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    // `calling` key'i l10n'da zaten var, onu direkt kullanıyoruz.
    if (_callState == _CallState.connecting) return l10n.calling;

    // Bu state metinleri için ortak key yok; dil bazlı map ile lokalize ediyoruz.
    const values = <String, Map<_CallState, String>>{
      'tr': {
        _CallState.listening: 'Seni dinliyorum',
        _CallState.thinking: 'Düşünüyorum...',
        _CallState.speaking: 'Konuşuyorum',
        _CallState.error: 'Bağlantı hatası',
      },
      'en': {
        _CallState.listening: 'Listening',
        _CallState.thinking: 'Thinking...',
        _CallState.speaking: 'Speaking',
        _CallState.error: 'Connection error',
      },
      'de': {
        _CallState.listening: 'Ich höre zu',
        _CallState.thinking: 'Ich denke nach...',
        _CallState.speaking: 'Ich spreche',
        _CallState.error: 'Verbindungsfehler',
      },
      'es': {
        _CallState.listening: 'Te escucho',
        _CallState.thinking: 'Estoy pensando...',
        _CallState.speaking: 'Estoy hablando',
        _CallState.error: 'Error de conexión',
      },
      'fr': {
        _CallState.listening: 'Je t’écoute',
        _CallState.thinking: 'Je réfléchis...',
        _CallState.speaking: 'Je parle',
        _CallState.error: 'Erreur de connexion',
      },
      'it': {
        _CallState.listening: 'Ti ascolto',
        _CallState.thinking: 'Sto pensando...',
        _CallState.speaking: 'Sto parlando',
        _CallState.error: 'Errore di connessione',
      },
      'pt': {
        _CallState.listening: 'Estou ouvindo',
        _CallState.thinking: 'Pensando...',
        _CallState.speaking: 'Falando',
        _CallState.error: 'Erro de conexão',
      },
      'ru': {
        _CallState.listening: 'Слушаю тебя',
        _CallState.thinking: 'Думаю...',
        _CallState.speaking: 'Говорю',
        _CallState.error: 'Ошибка соединения',
      },
      'ja': {
        _CallState.listening: '聞いています',
        _CallState.thinking: '考えています...',
        _CallState.speaking: '話しています',
        _CallState.error: '接続エラー',
      },
      'ko': {
        _CallState.listening: '듣고 있어요',
        _CallState.thinking: '생각 중이에요...',
        _CallState.speaking: '말하고 있어요',
        _CallState.error: '연결 오류',
      },
      'zh': {
        _CallState.listening: '我在听',
        _CallState.thinking: '我在思考...',
        _CallState.speaking: '我在说话',
        _CallState.error: '连接错误',
      },
      'hi': {
        _CallState.listening: 'मैं सुन रहा/रही हूँ',
        _CallState.thinking: 'मैं सोच रहा/रही हूँ...',
        _CallState.speaking: 'मैं बोल रहा/रही हूँ',
        _CallState.error: 'कनेक्शन त्रुटि',
      },
    };

    final localized = values[lang]?[_callState];
    if (localized != null) return localized;
    return values['en']?[_callState] ?? l10n.calling;
  }

  // Durum başına foto halkası rengi.
  //  - listening : yeşil (kullanıcı konuşabilir)
  //  - thinking  : amber (AI işleyişte)
  //  - speaking  : mavi  (AI konuşuyor — dokunarak da kesilebilir)
  //  - connecting: gri   (henüz hat kurulmadı)
  //  - error     : kırmızı
  Color _stateColor() {
    switch (_callState) {
      case _CallState.listening:
        return const Color(0xFF5ED085);
      case _CallState.thinking:
        return const Color(0xFFF5A623);
      case _CallState.speaking:
        return const Color(0xFF4A7BFF);
      case _CallState.connecting:
        return const Color(0xFF9AA0A6);
      case _CallState.error:
        return const Color(0xFFE53935);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final photoURL = widget.specialist.photoURL;
    final name = _coachName();
    final coachTitle = _coachTitle(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Yeni açık tema arka planı
      body: SafeArea(
        child: Column(
          children: [
            Spacer(flex: 1),
            // Kişi Adı - Font: Geist, Bold, 24px, #000000
            Text(
              name,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 24,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Alt Başlık - Font: Geist, Regular, 14px, #96989C
            Text(
              coachTitle,
              style: const TextStyle(
                color: Color(0xFF96989C),
                fontSize: 14,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Profil Resmi + duruma göre renk değişen nabızlı halkalar.
            // Halka rengi listening/thinking/speaking/connecting/error
            // durumlarına göre farklılaşır; pulse efekti _pulseCtrl ile.
            GestureDetector(
              onTap: _isMuted ? null : _requestBargeIn,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 300,
                height: 300,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    final double t = Curves.easeInOut.transform(
                      _pulseCtrl.value,
                    );
                    final Color color = _stateColor();
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.08 + 0.10 * t),
                          ),
                        ),
                        Container(
                          width: 270,
                          height: 270,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.16 + 0.12 * t),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5ED085),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.35),
                                blurRadius: 24 + 8 * t,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: photoURL.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 100,
                                  color: Colors.white54,
                                )
                              : ClipOval(
                                  child: Transform.translate(
                                    offset: const Offset(0, 12),
                                    child: SizedBox.expand(
                                      child: Image.network(
                                        photoURL,
                                        fit: BoxFit.contain,
                                        alignment: Alignment.center,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.person_rounded,
                                          size: 100,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Durum Metni - Font: Geist, Medium, 16px, #303030
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusText(context),
                key: ValueKey(_callState),
                style: TextStyle(
                  color: _callState == _CallState.error
                      ? Colors.redAccent
                      : const Color(0xFF303030),
                  fontSize: 16,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Spacer(flex: 3),

            // Alt Kontrol Butonları (Hap tasarımı, Bulanıklaştırma Efekti)
            Padding(
              padding: const EdgeInsets.only(bottom: 52),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionPillButton(
                    iconAssetPath: _isMuted
                        ? 'assets/icons/ic_mic_off.svg'
                        : 'assets/icons/ic_mic.svg',
                    color: const Color(0x80000000), // #000000 50%
                    onTap: () => _toggleMute(),
                  ),
                  const SizedBox(width: 20),
                  _ActionPillButton(
                    iconAssetPath: 'assets/icons/ic_phone_off.svg',
                    color: const Color(0xFFF44336), // #F44336 Kırmızı
                    onTap: _endCall,
                  ),
                  const SizedBox(width: 20),
                  _ActionPillButton(
                    iconAssetPath: _isSpeakerOn
                        ? 'assets/icons/ic_volume_high.svg'
                        : 'assets/icons/ic_volum_off.svg',
                    color: const Color(0x80000000), // #000000 50%
                    onTap: _toggleSpeaker,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Yardımcı Araçlar ve Yeni Tasarım Widget'ları ────────────────────────────

// Eski _ControlButton yerine geçen yeni hap (pill) şeklindeki buton
class _ActionPillButton extends StatelessWidget {
  final IconData? icon;
  final String? iconAssetPath;
  final Color color;
  final VoidCallback onTap;

  const _ActionPillButton({
    this.icon,
    this.iconAssetPath,
    required this.color,
    required this.onTap,
  }) : assert(icon != null || iconAssetPath != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50), // 50px radius
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ), // Background blur 10
          child: Container(
            width: 82, // Width 82px
            height: 55, // Height 55px
            color: color,
            alignment: Alignment.center,
            child: iconAssetPath != null
                ? SvgPicture.asset(
                    iconAssetPath!,
                    width: 34,
                    height: 34,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// Lightweight PCM chunk with its playback duration — used by the pre-roll
// buffer so we can replay the first moments of a user's barge-in to the
// server after we decide to interrupt.
class _AudioChunk {
  final Uint8List bytes;
  final int durationMs;
  const _AudioChunk(this.bytes, this.durationMs);
}
