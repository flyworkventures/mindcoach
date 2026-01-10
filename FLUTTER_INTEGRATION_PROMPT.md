# Flutter Realtime Phone Call API - Hızlı Entegrasyon Prompt

## 🚀 Hızlı Başlangıç

Flutter uygulamanıza gerçek zamanlı telefon görüşmesi gibi AI konuşması eklemek için aşağıdaki adımları izleyin.

## 📦 Gerekli Paketler

```yaml
dependencies:
  web_socket_channel: ^2.4.0
  record: ^5.0.4
  flutter_secure_storage: ^9.0.0
  just_audio: ^0.9.36  # veya audioplayers: ^5.2.1
  permission_handler: ^11.0.1
```

## 🔧 Kurulum Adımları

### 1. Permissions (Android & iOS)

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>NSMicrophoneUsageDescription</key>
<string>AI ile konuşmak için mikrofon erişimi gereklidir</string>
```

### 2. Realtime Phone Call Service

Aşağıdaki servisi projenize ekleyin:

```dart
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

class RealtimePhoneCallService {
  WebSocketChannel? _channel;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isRecording = false;
  bool _isConnected = false;
  bool _isPlaying = false;
  String? _connectionId;
  int? _consultantId;

  /// WebSocket bağlantısı kur
  Future<void> connect(int consultantId) async {
    try {
      // Token'ı secure storage'dan al
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception('JWT token bulunamadı. Lütfen tekrar giriş yapın.');
      }

      _consultantId = consultantId;

      // WebSocket URL'i oluştur
      // NOT: Production'da wss:// kullanın
      final uri = Uri.parse(
        'ws://YOUR_API_URL:3001?token=$token&consultantId=$consultantId'
      );

      // WebSocket bağlantısı kur
      _channel = WebSocketChannel.connect(uri);

      // Mesajları dinle
      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _onError('WebSocket bağlantı hatası: $error');
        },
        onDone: () {
          print('🔌 WebSocket bağlantısı kapandı');
          _isConnected = false;
          _onDisconnected();
        },
      );

      _isConnected = true;
      print('✅ Realtime Phone Call API\'ye bağlandı');
    } catch (e) {
      print('❌ Bağlantı hatası: $e');
      throw Exception('Bağlantı kurulamadı: $e');
    }
  }

  /// Görüşmeyi başlat
  Future<void> startCall() async {
    if (!_isConnected || _channel == null) {
      throw Exception('Önce bağlantı kurulmalı. connect() çağırın.');
    }

    try {
      // Mikrofon izni kontrol et
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Mikrofon izni verilmedi');
      }

      // Audio player'ı hazırla (streaming için)
      await _audioPlayer.setAudioSource(
        StreamAudioSource((_) async* {
          // Streaming audio için boş source
          // Audio chunk'ları doğrudan playAudioChunk ile oynatılacak
        }),
      );

      // Mikrofon kaydını başlat
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: 'realtime_call_${DateTime.now().millisecondsSinceEpoch}',
      );

      _isRecording = true;
      print('🎤 Mikrofon kaydı başlatıldı');

      // Audio stream'i dinle ve WebSocket'e gönder
      _audioRecorder.onStream.listen(
        (data) {
          if (_isRecording && _channel != null && _isConnected) {
            // PCM audio chunk'ını binary olarak gönder
            _channel!.sink.add(data);
          }
        },
        onError: (error) {
          print('❌ Audio stream error: $error');
        },
      );

      print('📞 Görüşme başlatıldı');
    } catch (e) {
      print('❌ Görüşme başlatma hatası: $e');
      throw Exception('Görüşme başlatılamadı: $e');
    }
  }

  /// Görüşmeyi durdur
  Future<void> stopCall() async {
    try {
      _isRecording = false;
      await _audioRecorder.stop();
      await _audioPlayer.stop();
      _isPlaying = false;
      print('📞 Görüşme durduruldu');
    } catch (e) {
      print('❌ Görüşme durdurma hatası: $e');
    }
  }

  /// Bağlantıyı kapat
  void disconnect() {
    _isRecording = false;
    _channel?.sink.close();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _isConnected = false;
    _connectionId = null;
    _consultantId = null;
    print('🔌 Bağlantı kapatıldı');
  }

  /// Gelen mesajları işle
  void _handleMessage(dynamic data) {
    if (data is Uint8List) {
      // Binary audio data (ElevenLabs'tan gelen PCM audio)
      _playAudioChunk(data);
    } else if (data is String) {
      // JSON message
      try {
        final message = jsonDecode(data);
        _handleJsonMessage(message);
      } catch (e) {
        print('❌ JSON parse error: $e');
      }
    }
  }

  /// JSON mesajlarını işle
  void _handleJsonMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    switch (type) {
      case 'connection_success':
        _connectionId = message['connectionId'] as String?;
        print('✅ Bağlantı başarılı: ${message['message']}');
        _onConnected(message);
        break;

      case 'barge_in':
        print('⚠️ Barge-in tespit edildi (Kullanıcı AI\'yı kesti)');
        _onBargeIn();
        break;

      case 'ai_response_interrupted':
        print('⚠️ AI yanıtı kesildi');
        _onAIInterrupted();
        break;

      case 'ai_response_complete':
        print('✅ AI yanıtı tamamlandı');
        _onAIResponseComplete();
        break;

      case 'error':
        final error = message['error'] as String?;
        print('❌ Hata: $error');
        _onError(error ?? 'Bilinmeyen hata');
        break;

      default:
        print('ℹ️ Bilinmeyen mesaj tipi: $type');
    }
  }

  /// Audio chunk'ı oynat (ElevenLabs'tan gelen PCM audio)
  void _playAudioChunk(Uint8List audioChunk) {
    // NOT: just_audio streaming için özel yapılandırma gerekebilir
    // Alternatif: audioplayers paketi kullanılabilir
    
    // Basit yaklaşım: Audio chunk'ları buffer'a ekle ve oynat
    // Production'da daha gelişmiş bir streaming çözümü kullanılmalı
    
    try {
      // Audio chunk'ı oynat
      // Bu kısım audio player kütüphanesine göre özelleştirilmeli
      _audioPlayer.load(
        StreamAudioSource((_) async* {
          yield audioChunk;
        }),
      );
      
      if (!_isPlaying) {
        _audioPlayer.play();
        _isPlaying = true;
      }
    } catch (e) {
      print('❌ Audio oynatma hatası: $e');
    }
  }

  // Callback'ler (override edilebilir)
  void _onConnected(Map<String, dynamic> message) {}
  void _onBargeIn() {}
  void _onAIInterrupted() {}
  void _onAIResponseComplete() {}
  void _onError(String error) {}
  void _onDisconnected() {}
}

/// Streaming audio source için helper class
class StreamAudioSource extends StreamAudioSource {
  final Stream<Uint8List> Function(dynamic) _streamBuilder;

  StreamAudioSource(this._streamBuilder);

  @override
  Future<Stream<Uint8List>> getStream(dynamic tag) async* {
    yield* _streamBuilder(tag);
  }
}
```

### 3. Kullanım Örneği

```dart
import 'package:flutter/material.dart';
import 'realtime_phone_call_service.dart';

class AICallScreen extends StatefulWidget {
  final int consultantId;

  const AICallScreen({Key? key, required this.consultantId}) : super(key: key);

  @override
  State<AICallScreen> createState() => _AICallScreenState();
}

class _AICallScreenState extends State<AICallScreen> {
  final RealtimePhoneCallService _callService = RealtimePhoneCallService();
  bool _isConnected = false;
  bool _isCallActive = false;
  String _status = 'Bağlanıyor...';

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await _callService.connect(widget.consultantId);
      setState(() {
        _isConnected = true;
        _status = 'Bağlandı';
      });
    } catch (e) {
      setState(() {
        _status = 'Bağlantı hatası: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı hatası: $e')),
      );
    }
  }

  Future<void> _startCall() async {
    try {
      await _callService.startCall();
      setState(() {
        _isCallActive = true;
        _status = 'Görüşme aktif';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görüşme başlatılamadı: $e')),
      );
    }
  }

  Future<void> _stopCall() async {
    await _callService.stopCall();
    setState(() {
      _isCallActive = false;
      _status = 'Görüşme durduruldu';
    });
  }

  @override
  void dispose() {
    _callService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Görüşmesi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            if (_isConnected && !_isCallActive)
              ElevatedButton(
                onPressed: _startCall,
                child: const Text('Görüşmeyi Başlat'),
              ),
            if (_isCallActive)
              ElevatedButton(
                onPressed: _stopCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Görüşmeyi Durdur'),
              ),
          ],
        ),
      ),
    );
  }
}
```

## ⚙️ Yapılandırma

### API URL'i Ayarlayın

```dart
// Development
final uri = Uri.parse('ws://localhost:3001?token=$token&consultantId=$consultantId');

// Production
final uri = Uri.parse('wss://your-api-domain.com:3001?token=$token&consultantId=$consultantId');
```

## 🎯 Önemli Notlar

1. **Audio Format**: PCM 16-bit, 16kHz, Mono formatında audio gönderilmelidir
2. **Barge-in**: AI konuşurken kullanıcı konuşursa AI otomatik olarak durur
3. **Silence Detection**: 1 saniye sessizlik sonrası AI yanıt oluşturmaya başlar
4. **Streaming**: Tüm audio streaming formatında, dosya upload yok
5. **Token**: JWT token secure storage'da saklanmalı

## 🐛 Sorun Giderme

### Mikrofon İzni Verilmedi
```dart
// permission_handler ile izin kontrolü yapın
final status = await Permission.microphone.status;
if (!status.isGranted) {
  await Permission.microphone.request();
}
```

### WebSocket Bağlantı Hatası
- API URL'inin doğru olduğundan emin olun
- Token'ın geçerli olduğunu kontrol edin
- Firewall/proxy ayarlarını kontrol edin

### Audio Oynatma Sorunları
- `just_audio` yerine `audioplayers` paketi deneyin
- Audio formatının PCM 16kHz olduğundan emin olun
- Streaming için özel audio player yapılandırması gerekebilir

## 📚 Ek Kaynaklar

- [WebSocket Channel Documentation](https://pub.dev/packages/web_socket_channel)
- [Record Package Documentation](https://pub.dev/packages/record)
- [Just Audio Documentation](https://pub.dev/packages/just_audio)

## ✅ Checklist

- [ ] Gerekli paketler eklendi
- [ ] Permissions yapılandırıldı (Android & iOS)
- [ ] RealtimePhoneCallService eklendi
- [ ] API URL'i yapılandırıldı
- [ ] JWT token secure storage'da saklanıyor
- [ ] Test edildi (bağlantı, görüşme başlatma, durdurma)

