import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart' as pcm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/core/locale/locale_provider.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
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
  final Queue<int> _pcmQueue = Queue<int>();
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

    _configureAudioSession()
        .then((_) => _initPcmPlayer())
        .then((_) => _connect())
        .then((_) => _configureAudioSession())
        .then((_) => _startRingTone());
  }

  // ── iOS audio session ──────────────────────────────────────────────────────
  Future<void> _configureAudioSession() async {
    if (!Platform.isIOS) return;
    try {
      final mode = await _audioSessionChannel.invokeMethod<String>(
        'configureForVoiceCall',
      );
      debugPrint('🔊 [AUDIO] iOS AVAudioSession ready — mode=$mode');
      // Re-applying the category resets any active output-port override,
      // so re-assert the user's speaker preference after every config.
      if (_isSpeakerOn) {
        try {
          await _audioSessionChannel.invokeMethod('setSpeakerOn', {'on': true});
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('⚠️ [AUDIO] session config failed: $e');
    }
  }

  Future<void> _resetAudioSession() async {
    if (!Platform.isIOS) return;
    try {
      await _audioSessionChannel.invokeMethod('resetAudioSession');
    } catch (_) {}
  }

  // ── PCM player setup ───────────────────────────────────────────────────────
  Future<void> _initPcmPlayer() async {
    try {
      await pcm.FlutterPcmSound.setup(
        sampleRate: _sampleRate,
        channelCount: _channels,
        iosAudioCategory: pcm.IosAudioCategory.playAndRecord,
      );
      await pcm.FlutterPcmSound.setFeedThreshold((_sampleRate * 0.25).round());
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

    if (_pcmQueue.isEmpty) return;

    final int maxSamples = (_sampleRate * 0.5).round();
    final int toSend = _pcmQueue.length < maxSamples
        ? _pcmQueue.length
        : maxSamples;

    final Int16List samples = Int16List(toSend);
    double sumSq = 0;
    for (int i = 0; i < toSend; i++) {
      samples[i] = _pcmQueue.removeFirst();
      final v = samples[i].toDouble();
      sumSq += v * v;
    }
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
    _pcmQueue.clear();
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
    for (int i = 0; i < totalSamples; i++) {
      _pcmQueue.add(samples[i]);
    }
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
      final token = await LocalDbService().getString(key: LocalDbKeys.token);
      if (token == null || token.isEmpty) {
        throw Exception('Token bulunamadı — lütfen tekrar giriş yapın');
      }

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
  // Tuned for iPhone built-in speaker + iOS voiceChat AEC:
  //  - RMS threshold chosen well above typical post-AEC echo residue
  //    (usually ~300-800) but below a normal voice (~2500-8000).
  //  - 160ms sustained → fast enough to feel responsive on barge-in, long
  //    enough to reject short bursts like a cough or speaker pop.
  static const int _bargeInSustainedMs = 160;
  static const int _preRollMaxMs = 500;

  // After the AI stops speaking, keep the mic gated closed for this long
  // so any acoustic tail from the iPhone speaker doesn't get transcribed
  // as a user utterance (we were seeing "going." show up as the tail of
  // "how's it going?"). 400ms is generous enough for typical room decay
  // without making the user wait.
  static const int _postSpeechCooldownMs = 400;

  int _highRmsStreakMs = 0;
  bool _bargeInSent = false;
  final Queue<_AudioChunk> _preRoll = Queue<_AudioChunk>();
  DateTime? _micGateOpenAt;
  DateTime? _aiSpeakingSince;
  int _lastPlaybackRms = 0;

  static const int _bargeInMinAiSpeakingMs = 450;
  static const int _bargeInRmsThresholdEarpiece = 2200;
  static const int _bargeInRmsThresholdSpeaker = 3200;

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
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _setError();
      return;
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
      if (_isRinging) return;
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
          (_lastPlaybackRms * 1.6).round(),
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

        if (
            !_bargeInSent &&
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

  void _handleJson(Map<String, dynamic> msg) {
    final type = msg['type'] as String? ?? '';

    switch (type) {
      case 'connection_success':
        _stopRingTone();
        _configureAudioSession();
        _playPickupChime();
        if (mounted) setState(() => _callState = _CallState.listening);
        _aiSpeakingSince = null;
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _secondsElapsed++);
        });
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
        break;

      case 'ai_response_complete':
        _waitForPcmDrainAndListen();
        break;

      case 'barge_in':
        _flushPcm();
        _resetBargeInState();
        _aiSpeakingSince = null;
        if (mounted) setState(() => _callState = _CallState.listening);
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
    final int sampleCount = bytes.length ~/ 2;
    final ByteData bd = ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      sampleCount * 2,
    );
    for (int i = 0; i < sampleCount; i++) {
      _pcmQueue.add(bd.getInt16(i * 2, Endian.little));
    }
    _ensurePcmStarted();
    _onPcmFeedRequest(0);
  }

  void _flushPcm() {
    _pcmQueue.clear();
  }

  Future<void> _waitForPcmDrainAndListen() async {
    while (_pcmQueue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
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
  }

  void _requestBargeIn() {
    if (_isMuted) return;
    if (_callState != _CallState.speaking) return;
    if (_ws?.readyState != WebSocket.open) return;
    _flushPcm();
    _ws!.add(jsonEncode({'type': 'barge_in_request'}));
    if (mounted) setState(() => _callState = _CallState.listening);
  }

  // ── End call / cleanup ─────────────────────────────────────────────────────
  Future<void> _endCall() async {
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
    await _resetAudioSession();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleMute() async {
    final next = !_isMuted;
    setState(() => _isMuted = next);
    if (next) {
      await _stopMicStream();
      if (mounted && _callState != _CallState.speaking) {
        setState(() => _callState = _CallState.listening);
      }
      return;
    }
    if (_ws?.readyState == WebSocket.open) {
      await _startMicStream();
    }
  }

  // ── Speaker / earpiece toggle ──────────────────────────────────────────────
  // Matches the iPhone Phone app UX: the call starts on the earpiece, the
  // user taps the speaker button to switch to loudspeaker and taps again
  // to switch back.
  Future<void> _toggleSpeaker() async {
    if (!Platform.isIOS) return;
    final next = !_isSpeakerOn;
    try {
      await _audioSessionChannel.invokeMethod('setSpeakerOn', {'on': next});
      if (mounted) setState(() => _isSpeakerOn = next);
    } catch (e) {
      debugPrint('⚠️ [AUDIO] speaker toggle failed: $e');
    }
  }

  void _setError() {
    _stopRingTone();
    if (mounted) setState(() => _callState = _CallState.error);
  }

  @override
  void dispose() {
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

            // Profil Resmi ve Animasyon (Yeşil Arka Planlı Yuvarlak)
            GestureDetector(
              onTap: _isMuted ? null : _requestBargeIn,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF5ED085), // Tasarımdaki yeşil arka plan
                  shape: BoxShape.circle,
                  image: photoURL.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoURL),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photoURL.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 100,
                        color: Colors.white54,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 48),

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
