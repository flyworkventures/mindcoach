import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Riverpod/providers/all_providers.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:just_audio/just_audio.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:path_provider/path_provider.dart';

/// Realtime Phone Call Service
/// WebSocket üzerinden gerçek zamanlı sesli görüşme yönetimi
class RealtimePhoneCallService {
  WebSocketChannel? _channel;
  AudioRecorder? _audioRecorder;
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  final AudioPlayer _justAudioPlayer = AudioPlayer(); // just_audio için
  final LocalDbService _storage = LocalDbService();
  
  bool _isRecording = false;
  bool _isConnected = false;
  bool _isPlaying = false;
  String? _connectionId;
  int? _consultantId;
  WidgetRef? _ref;
  Timer? _audioStreamTimer;
  String? _recordingPath;
  int _lastFilePosition = 0;
  
  // Audio playback için buffer
  final List<Uint8List> _audioBuffer = [];
  bool _isBuffering = false;
  Timer? _playbackTimer;
  
  // Callbacks
  Function(Map<String, dynamic>)? onConnected;
  Function()? onBargeIn;
  Function()? onAIInterrupted;
  Function()? onAIResponseComplete;
  Function(String)? onError;
  Function()? onDisconnected;
  Function()? onAgentSpeaking; // Agent konuşmaya başladığında
  
  RealtimePhoneCallService({WidgetRef? ref}) : _ref = ref;

  /// WebSocket bağlantısı kur
  Future<void> connect(int consultantId) async {
    try {
      // Token'ı al
      String? token;
      if (_ref != null) {
        token = _ref!.read(AllProviders.userProvider)?.token;
      }
      
      if (token == null) {
        token = await _storage.getString(key: LocalDbKeys.token);
      }
      
      if (token == null) {
        throw Exception('JWT token bulunamadı. Lütfen tekrar giriş yapın.');
      }

      _consultantId = consultantId;

      // WebSocket URL'i oluştur (3001 portunda)
      // NOT: Kullanıcı localhost:3001 kullanıyor, production'da baseUrl kullanılmalı
      final wsProtocol = AppConstants.baseURL.startsWith('https') ? 'wss' : 'ws';
      final wsUrl = '$wsProtocol://localhost:3001?token=$token&consultantId=$consultantId';
      
      log("🔌 WebSocket bağlantısı kuruluyor: $wsUrl");

      // WebSocket bağlantısı kur
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Mesajları dinle
      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          log('❌ WebSocket error: $error');
          _onError('WebSocket bağlantı hatası: $error');
        },
        onDone: () {
          log('🔌 WebSocket bağlantısı kapandı');
          _isConnected = false;
          _onDisconnected();
        },
      );

      _isConnected = true;
      log('✅ Realtime Phone Call API\'ye bağlandı');
    } catch (e) {
      log('❌ Bağlantı hatası: $e');
      throw Exception('Bağlantı kurulamadı: $e');
    }
  }

  /// Görüşmeyi başlat
  Future<void> startCall() async {
    if (!_isConnected || _channel == null) {
      throw Exception('Önce bağlantı kurulmalı. connect() çağırın.');
    }

    try {
      // AudioRecorder'ı lazy initialize et
      _audioRecorder ??= AudioRecorder();
      
      // Mikrofon izni kontrol et
      if (await _audioRecorder!.hasPermission()) {
        log("✅ Mikrofon izni var");
      } else {
        throw Exception('Mikrofon izni verilmedi');
      }

      // Mikrofon kaydını başlat
      // NOT: OpenAI Realtime API PCM16 format bekliyor
      // iOS'ta PCM16 denemesi yapıyoruz, sorun çıkarsa AAC'ye döneriz
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${tempDir.path}/realtime_call_$timestamp.pcm';
      
      try {
        await _audioRecorder!.start(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits, // PCM16 format OpenAI için gerekli
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 128000,
          ),
          path: _recordingPath!,
        );
        log('✅ PCM16 formatında kayıt başlatıldı');
      } catch (e) {
        // iOS'ta PCM16 sorun çıkarırsa AAC'ye dön
        log('⚠️ PCM16 hatası, AAC formatına geçiliyor: $e');
        _recordingPath = '${tempDir.path}/realtime_call_$timestamp.m4a';
        await _audioRecorder!.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 128000,
          ),
          path: _recordingPath!,
        );
        log('✅ AAC formatında kayıt başlatıldı');
      }

      _isRecording = true;
      _lastFilePosition = 0;
      log('🎤 [RECORDING] Mikrofon kaydı başlatıldı: $_recordingPath');
      log('🎤 [RECORDING] Recording state: _isRecording=$_isRecording, _channel=${_channel != null}, _isConnected=$_isConnected');

      // Audio chunk'ları periyodik olarak oku ve WebSocket'e gönder
      _startAudioStreaming();
      log('🎤 [RECORDING] Audio streaming timer başlatıldı');

      log('📞 [CALL] Görüşme başlatıldı');
    } catch (e) {
      log('❌ Görüşme başlatma hatası: $e');
      throw Exception('Görüşme başlatılamadı: $e');
    }
  }

  /// Audio streaming'i başlat (periyodik olarak chunk'ları oku ve gönder)
  void _startAudioStreaming() {
    _audioStreamTimer?.cancel();
    log('🎤 [STREAMING] Audio streaming timer başlatılıyor...');
    _audioStreamTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording || _channel == null || !_isConnected || _recordingPath == null) {
        if (timer.tick == 1) {
          log('⚠️ [STREAMING] Timer başladı ama koşullar sağlanmıyor: _isRecording=$_isRecording, _channel=${_channel != null}, _isConnected=$_isConnected, _recordingPath=${_recordingPath != null}');
        }
        return;
      }

      try {
        final file = File(_recordingPath!);
        if (!await file.exists()) {
          if (timer.tick == 1) {
            log('⚠️ [STREAMING] Kayıt dosyası bulunamadı: $_recordingPath');
          }
          return;
        }

        final fileLength = await file.length();
        if (fileLength <= _lastFilePosition) {
          // Yeni data yok
          if (timer.tick == 1) {
            log('ℹ️ [STREAMING] Henüz yeni data yok (Dosya boyutu: $fileLength, Son pozisyon: $_lastFilePosition)');
          }
          return;
        }

        // Yeni audio chunk'ı oku
        final randomAccessFile = await file.open();
        await randomAccessFile.setPosition(_lastFilePosition);
        final newData = await randomAccessFile.read(fileLength - _lastFilePosition);
        await randomAccessFile.close();

        if (newData.isNotEmpty && _channel != null && _isConnected) {
          // Audio chunk'ı WebSocket'e gönder (binary olarak)
          _channel!.sink.add(newData);
          _lastFilePosition = fileLength;
          
          // Her chunk'ta log (debug için)
          log('📤 [AUDIO STREAM] Audio chunk gönderildi: ${newData.length} bytes (Toplam gönderilen: $_lastFilePosition bytes)');
        } else {
          if (newData.isEmpty) {
            log('⚠️ [AUDIO STREAM] Yeni data yok');
          } else if (_channel == null) {
            log('⚠️ [AUDIO STREAM] WebSocket channel null');
          } else if (!_isConnected) {
            log('⚠️ [AUDIO STREAM] WebSocket bağlantısı yok');
          }
        }
      } catch (e) {
        log('❌ Audio streaming hatası: $e');
      }
    });
  }

  /// Görüşmeyi durdur
  Future<void> stopCall() async {
    try {
      _isRecording = false;
      _audioStreamTimer?.cancel();
      _audioStreamTimer = null;
      _playbackTimer?.cancel();
      _playbackTimer = null;
      
      await _audioRecorder?.stop();
      await _audioPlayer.stop();
      await _justAudioPlayer.stop();
      
      _isPlaying = false;
      _isBuffering = false;
      _lastFilePosition = 0;
      _audioBuffer.clear();
      
      // Kayıt dosyasını temizle
      if (_recordingPath != null) {
        try {
          final file = File(_recordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          log('⚠️ Kayıt dosyası silinemedi: $e');
        }
        _recordingPath = null;
      }
      
      log('📞 Görüşme durduruldu');
    } catch (e) {
      log('❌ Görüşme durdurma hatası: $e');
    }
  }

  /// Bağlantıyı kapat
  void disconnect() {
    _isRecording = false;
    _audioStreamTimer?.cancel();
    _audioStreamTimer = null;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _channel?.sink.close();
    _audioRecorder?.dispose();
    _audioRecorder = null;
    _audioPlayer.dispose();
    _justAudioPlayer.dispose();
    _isConnected = false;
    _connectionId = null;
    _consultantId = null;
    _lastFilePosition = 0;
    _audioBuffer.clear();
    _isPlaying = false;
    _isBuffering = false;
    
    // Kayıt dosyasını temizle
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        log('⚠️ Kayıt dosyası silinemedi: $e');
      }
      _recordingPath = null;
    }
    
    log('🔌 Bağlantı kapatıldı');
  }

  /// Gelen mesajları işle
  void _handleMessage(dynamic data) {
    if (data is Uint8List) {
      // Binary audio data (ElevenLabs'tan gelen PCM audio)
      log('🔊 [RECEIVED] Binary audio chunk alındı: ${data.length} bytes');
      _playAudioChunk(data);
    } else if (data is String) {
      // JSON message
      log('📨 [RECEIVED] JSON mesaj alındı: ${data.substring(0, data.length > 100 ? 100 : data.length)}...');
      try {
        final message = jsonDecode(data);
        _handleJsonMessage(message);
      } catch (e) {
        log('❌ [RECEIVED] JSON parse error: $e');
      }
    } else {
      log('⚠️ [RECEIVED] Bilinmeyen data tipi: ${data.runtimeType}');
    }
  }

  /// JSON mesajlarını işle
  void _handleJsonMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    switch (type) {
      case 'connection_success':
        _connectionId = message['connectionId'] as String?;
        log('✅ Bağlantı başarılı: ${message['message']}');
        onConnected?.call(message);
        break;

      case 'barge_in':
        log('⚠️ Barge-in tespit edildi (Kullanıcı AI\'yı kesti)');
        onBargeIn?.call();
        break;

      case 'ai_response_interrupted':
        log('⚠️ AI yanıtı kesildi');
        onAIInterrupted?.call();
        break;

      case 'ai_response_complete':
        log('✅ AI yanıtı tamamlandı');
        onAIResponseComplete?.call();
        break;

      case 'ai_speaking_start':
        log('🎙️ Agent konuşmaya başladı');
        onAgentSpeaking?.call();
        break;

      case 'error':
        final error = message['error'] as String?;
        log('❌ Hata: $error');
        _onError(error ?? 'Bilinmeyen hata');
        break;

      default:
        log('ℹ️ Bilinmeyen mesaj tipi: $type');
    }
  }

  /// Audio chunk'ı oynat (ElevenLabs'tan gelen PCM audio)
  void _playAudioChunk(Uint8List audioChunk) {
    try {
      // Audio chunk'ı buffer'a ekle
      _audioBuffer.add(audioChunk);
      log('🔊 Audio chunk buffera eklendi: ${audioChunk.length} bytes (Toplam: ${_audioBuffer.length} chunks)');
      
      // İlk chunk geldiğinde oynatmayı başlat
      if (!_isPlaying && !_isBuffering) {
        _isPlaying = true;
        _isBuffering = true;
        log('🔊 Audio oynatma başlatılıyor...');
        _startAudioPlayback();
      }
    } catch (e) {
      log('❌ Audio oynatma hatası: $e');
    }
  }

  /// Audio playback'i başlat (buffer'dan oynat)
  void _startAudioPlayback() async {
    try {
      // Buffer'da yeterli data var mı kontrol et (en az 3 chunk)
      if (_audioBuffer.length < 3) {
        // Timer ile tekrar dene
        _playbackTimer?.cancel();
        _playbackTimer = Timer(const Duration(milliseconds: 50), () {
          if (_audioBuffer.isNotEmpty) {
            _startAudioPlayback();
          }
        });
        return;
      }

      // Buffer'daki chunk'ları birleştir
      final totalLength = _audioBuffer.fold<int>(0, (sum, chunk) => sum + chunk.length);
      final combinedAudio = Uint8List(totalLength);
      int offset = 0;
      for (final chunk in _audioBuffer) {
        combinedAudio.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      // Geçici dosya oluştur ve oynat
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/playback_${DateTime.now().millisecondsSinceEpoch}.pcm');
      await tempFile.writeAsBytes(combinedAudio);

      log('🔊 ${_audioBuffer.length} chunk birleştirildi (${totalLength} bytes), oynatılıyor...');

      // Buffer'ı temizle
      _audioBuffer.clear();

      // just_audio ile oynat
      // PCM16 format için özel source oluştur
      await _justAudioPlayer.setAudioSource(
        AudioSource.file(tempFile.path),
      );

      await _justAudioPlayer.play();
      _isBuffering = false;
      log('✅ Audio oynatılıyor');

      // Dosyayı oynatma bitince sil
      _justAudioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          tempFile.deleteSync();
          _isPlaying = false;
          log('✅ Audio oynatma tamamlandı');
          
          // Buffer'da yeni data varsa tekrar başlat
          if (_audioBuffer.isNotEmpty) {
            _startAudioPlayback();
          }
        }
      });

    } catch (e) {
      log('❌ Audio playback başlatma hatası: $e');
      _isBuffering = false;
      _isPlaying = false;
    }
  }


  /// Callback'ler
  void _onError(String error) {
    onError?.call(error);
  }

  void _onDisconnected() {
    onDisconnected?.call();
  }

  // Getters
  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get connectionId => _connectionId;
  int? get consultantId => _consultantId;
}

