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
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/Services/rive_preload_service.dart';
import 'package:mindcoach/core/locale/locale_provider.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
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
  const VideoCallRealtimeScreen({super.key, required this.specialist});

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
  final Queue<int> _pcmQueue = Queue<int>();
  bool _pcmSetup = false;
  bool _pcmStarted = false;
  bool _isRinging = false;
  int _ringSamplePos = 0;
  static const int _ringOnSamples = _sampleRate * 2;
  static const int _ringOffSamples = _sampleRate * 4;
  static const int _ringPeriodSamples = _ringOnSamples + _ringOffSamples;

  _CallState _callState = _CallState.connecting;
  bool _isMuted = false;
  final bool _isSpeakerOn = false;
  Timer? _timer;
  int _secondsElapsed = 0;

  static const int _bargeInSustainedMs = 160;
  static const int _preRollMaxMs = 500;
  static const int _postSpeechCooldownMs = 400;

  /// PCM oynatıcıda kalan tampon (~bir frame süresi); ağız ses bitene kadar kapalı kalsın.
  static const int _pcmPlaybackTailMs = 110;

  /// Rive blend (ms) — düşük = daha hızlı viseme geçişleri.
  static const double _riveTalkOpenBlendMs = 82;
  static const double _riveVisemeBlendMs = 55;
  static const int _realtimeVisemeDebounceMs = 48;
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
  double _rmsSmoothed = 0.0;
  int _visemeApplied = 0;
  Timer? _realtimeVisemeApplyTimer;
  int _pendingRealtimeVisemeId = 0;
  // Phoneme-based timeline timers (from server Rhubarb map).
  // When active, RMS-based updates are suppressed.
  final List<Timer> _visemeTimers = [];
  bool _visemeTimelineActive = false;
  Map<String, dynamic>? _pendingVisemeTimelineMsg;

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

  @override
  void initState() {
    super.initState();
    _riveFileLoader = _buildRiveFileLoader();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocalCamera();
      _init(); // post-frame: sayfanın önce render olmasına izin ver
      _scheduleRemoteRiveUpgrade();
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
    _cameraController = CameraController(
      cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
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
      await _attachCamera(_cameraIndex);
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

  Future<void> _init() async {
    // PCM + ses oturumu kurulumu ile WebSocket bağlantısını paralel başlat.
    // _initPcmPlayer zaten _configureAudioSession'ı içinde çağırıyor.
    await Future.wait([_initPcmPlayer(), _connect()]);
    await _startRingTone();
  }

  Future<void> _configureAudioSession() async {
    if (!Platform.isIOS) return;
    try {
      await _audioSessionChannel.invokeMethod<String>('configureForVoiceCall');
      if (_isSpeakerOn) {
        try {
          await _audioSessionChannel.invokeMethod('setSpeakerOn', {'on': true});
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _resetAudioSession() async {
    if (!Platform.isIOS) return;
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
    await pcm.FlutterPcmSound.setFeedThreshold((_sampleRate * 0.25).round());
    pcm.FlutterPcmSound.setFeedCallback(_onPcmFeedRequest);
    _pcmSetup = true;
    await _configureAudioSession();
  }

  Future<void> _ensurePcmStarted() async {
    if (!_pcmSetup || _pcmStarted) return;
    pcm.FlutterPcmSound.start();
    _pcmStarted = true;
  }

  void _onPcmFeedRequest(int _) {
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
      _driveRealtimeVisemeFromRms(_lastPlaybackRms);
    }
    pcm.FlutterPcmSound.feed(
      pcm.PcmArrayInt16(bytes: samples.buffer.asByteData()),
    );
  }

  Future<void> _startRingTone() async {
    if (_isRinging) return;
    _isRinging = true;
    _ringSamplePos = 0;
    await _ensurePcmStarted();
    _feedRingToneChunk();
  }

  void _stopRingTone() {
    _isRinging = false;
    _pcmQueue.clear();
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
      }
      samples[i] = (sample * 32767).round().clamp(-32767, 32767);
    }
    _ringSamplePos += chunkSamples;
    pcm.FlutterPcmSound.feed(
      pcm.PcmArrayInt16(bytes: samples.buffer.asByteData()),
    );
  }

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

  Future<void> _connect() async {
    try {
      final token = await LocalDbService().getString(key: LocalDbKeys.token);
      if (token == null || token.isEmpty) throw Exception('Token yok');
      final deviceLang = ref.read(localeProvider.notifier).getLanguageCode();
      final url =
          '${AppConstants.wsBaseURL}?token=${Uri.encodeQueryComponent(token)}'
          '&consultantId=${widget.specialist.id}'
          '&sampleRate=$_sampleRate'
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
      await _startMicStream();
    } catch (_) {
      _setError();
    }
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
      if (chunk.isEmpty || chunk.length % 2 != 0) return;
      if (_isMuted || _isRinging || _ws?.readyState != WebSocket.open) return;
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
    _rmsSmoothed = 0.0;
    _pendingVisemeTimelineMsg = null;
    for (final t in _visemeTimers) {
      t.cancel();
    }
    _visemeTimers.clear();
    _visemeTimelineActive = false;
  }

  void _maybeFlushPendingVisemeTimeline() {
    final pending = _pendingVisemeTimelineMsg;
    if (pending == null || !_riveAudioActive) return;
    _pendingVisemeTimelineMsg = null;
    _scheduleVisemeTimers(pending);
  }

  void _scheduleVisemeTimers(Map<String, dynamic> msg) {
    final List<dynamic> timeline = (msg['timeline'] as List<dynamic>?) ?? [];
    final int startOffsetMs = (msg['startOffsetMs'] as num?)?.toInt() ?? 0;

    for (final entry in timeline) {
      final int timeMs = (entry['t'] as num).toInt();
      final int id = (entry['id'] as num).toInt();

      final int delayMs = timeMs - startOffsetMs;
      if (delayMs < 0) {
        _visemeApplied = id;
        continue;
      }

      _visemeTimers.add(
        Timer(Duration(milliseconds: delayMs), () {
          if (!mounted) return;
          if (_callState != _CallState.speaking || _isMuted || _isRinging) {
            return;
          }
          if (!_riveAudioActive) return;
          _visemeApplied = id;
          _setRiveNumber('visemeNum', id.toDouble());
          _setRiveNumber('duration', _riveVisemeBlendMs);
        }),
      );
    }

    if (_visemeApplied != 0) {
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
      try {
        vm.number(key)?.value = value;
        return;
      } catch (_) {}
      try {
        for (final prop in vm.properties) {
          if (prop.name == key) {
            (prop as dynamic).value = value;
            return;
          }
        }
      } catch (_) {}
      return;
    }
    // StateMachine inputs path
    if (key == 'visemeNum') _smVisemeNum?.value = value;
    if (key == 'duration') _smDuration?.value = value;
  }

  void _driveRealtimeVisemeFromRms(int rms) {
    if (_callState != _CallState.speaking || _isMuted || _isRinging) return;

    // When a phoneme timeline is active, it controls the mouth — skip RMS.
    // RMS only acts as fallback before the timeline arrives (early streaming).
    if (_visemeTimelineActive) {
      // Ses çıkmadan önce timeline gelmiş olabilir — ilk PCM ile birlikte işle.
      if (!_riveAudioActive && rms > 400) {
        _riveAudioActive = true;
        _setRiveBool('talk', true);
        _setRiveNumber('duration', _riveTalkOpenBlendMs);
        _maybeFlushPendingVisemeTimeline();
      }
      return;
    }

    // ── Exponential moving average (fallback, no timeline yet) ───────────────
    const double alpha = 0.20;
    _rmsSmoothed = _rmsSmoothed * (1 - alpha) + rms * alpha;
    final int smoothRms = _rmsSmoothed.round();

    // Open mouth the first time real audio arrives (PCM gerçekten yürüdüğünde).
    if (!_riveAudioActive && smoothRms > 300) {
      _riveAudioActive = true;
      _setRiveBool('talk', true);
      _setRiveNumber('duration', _riveTalkOpenBlendMs);
      _maybeFlushPendingVisemeTimeline();
    }
    if (!_riveAudioActive) return;

    // ── 4-level viseme mapping (fewer levels = fewer jumps) ──────────────────
    // Levels: closed → slight → medium → wide.
    // Thresholds are based on ElevenLabs PCM16 typical TTS amplitude range.
    int targetId;
    if (smoothRms < 600) {
      targetId = 0; // closed / rest
    } else if (smoothRms < 1800) {
      targetId = 2; // slight open (consonants, quiet syllables)
    } else if (smoothRms < 3500) {
      targetId = 7; // medium open (normal vowels)
    } else {
      targetId = 15; // wide open (stressed vowels)
    }

    // Only schedule a Rive update when the target actually changed
    _pendingRealtimeVisemeId = targetId;
    if (targetId == _visemeApplied) return; // already showing this level
    if (_realtimeVisemeApplyTimer != null) return; // update queued

    _realtimeVisemeApplyTimer = Timer(
      Duration(milliseconds: _realtimeVisemeDebounceMs),
      () {
        _realtimeVisemeApplyTimer = null;
        if (!mounted) return;
        if (_callState != _CallState.speaking || _isMuted || _isRinging) return;
        final int id = _pendingRealtimeVisemeId;
        if (id == _visemeApplied) return;
        _visemeApplied = id;
        _setRiveNumber('visemeNum', id.toDouble());
        _setRiveNumber('duration', _riveVisemeBlendMs);
      },
    );
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
        _syncRiveTalk();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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
        _syncRiveTalk();
        break;
      case 'ai_speaking_start':
        _stopRingTone();
        _configureAudioSession();
        _ensurePcmStarted();
        _resetBargeInState();
        _aiSpeakingSince = DateTime.now();
        if (mounted) setState(() => _callState = _CallState.speaking);
        _syncRiveTalk();
        break;
      case 'ai_response_complete':
        _waitForPcmDrainAndListen();
        break;
      case 'barge_in':
        _flushPcm();
        _resetBargeInState();
        _aiSpeakingSince = null;
        _clearVisemeTimers();
        _setRiveNumber('visemeNum', 0);
        if (mounted) setState(() => _callState = _CallState.listening);
        _syncRiveTalk();
        break;
      case 'error':
        _setError();
        break;
    }
  }

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

  void _flushPcm() => _pcmQueue.clear();

  Future<void> _waitForPcmDrainAndListen() async {
    while (_pcmQueue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }
    // Donanım tamponu boşalsın — ağız gerçek ses sonuna yakın kapansın.
    await Future.delayed(const Duration(milliseconds: _pcmPlaybackTailMs));
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
  }

  Future<void> _toggleMute() async {
    final next = !_isMuted;
    setState(() => _isMuted = next);
    if (next) {
      await _stopMicStream();
      if (mounted && _callState != _CallState.speaking) {
        setState(() => _callState = _CallState.listening);
      }
    } else if (_ws?.readyState == WebSocket.open) {
      await _startMicStream();
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
    await _endCall();
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
    try {
      await _httpService.post(
        path: AppConstants.videoCallRateURL,
        body: {'consultantId': widget.specialist.id, 'rating': rating},
      );
    } catch (_) {
      // rating gönderimi başarısız olsa da çıkış akışını bloklamayalım
    }
  }

  Future<void> _endCall() async {
    _clearVisemeTimers();
    _timer?.cancel();
    _stopRingTone();

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
    if (mounted) Navigator.of(context).pop();
  }

  void _setError() {
    _stopRingTone();
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
  }

  void _syncRiveTalk() {
    final bool shouldTalk =
        _callState == _CallState.speaking && !_isMuted && !_isRinging;

    // When state leaves speaking: close mouth and reset audio-active flag.
    // When entering speaking: do NOT open the mouth yet — wait for the first
    // real audio chunk in _driveRealtimeVisemeFromRms (prevents the avatar
    // mouth opening before any sound arrives).
    if (!shouldTalk) {
      _riveAudioActive = false;
      _rmsSmoothed = 0.0;
      _visemeApplied = 0;
      _setRiveBool('talk', false);
      _setRiveNumber('visemeNum', 0.0);
    }
  }

  void _setRiveBool(String key, bool value) {
    final vm = _riveViewModel;
    if (vm != null) {
      try {
        vm.boolean(key)?.value = value;
        return;
      } catch (_) {}
      try {
        for (final prop in vm.properties) {
          if (prop.name == key) {
            (prop as dynamic).value = value;
            return;
          }
        }
      } catch (_) {}
      return;
    }
    // StateMachine inputs path
    if (key == 'talk') _smTalk?.value = value;
  }

  @override
  void dispose() {
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
    return Scaffold(
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
                        label: _formatElapsed(_secondsElapsed),
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
      inner = SizedBox(
        width: 24.w,
        height: 24.w,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white54,
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
      inner = ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: c.value.previewSize!.height,
              height: c.value.previewSize!.width,
              child: CameraPreview(c),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.w),
      child: Container(
        width: 88.w,
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: RepaintBoundary(child: Center(child: inner)),
      ),
    );
  }

  Widget _buildVideoCard() {
    return Container(
      color: const Color(0xFF22C987),
      child: RepaintBoundary(
        child: KeyedSubtree(
          key: ValueKey<int>(_riveLoaderKey),
          child: rive.RiveWidgetBuilder(
            fileLoader: _riveFileLoader,
            onLoaded: _onRiveLoaded,
            builder: (context, state) => switch (state) {
              rive.RiveLoading() => _buildRiveLoadingPlaceholder(),
              rive.RiveFailed() => _buildRiveLoadingPlaceholder(
                showSpinner: false,
              ),
              rive.RiveLoaded() => rive.RiveWidget(
                controller: state.controller,
                fit: rive.Fit.cover,
                alignment: Alignment.topCenter,
              ),
            },
          ),
        ),
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
            Positioned(
              top: -30,
              bottom: -30,
              left: -30,
              right: -30,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: 20.h,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF000000).withValues(alpha: 0.30),
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
}
