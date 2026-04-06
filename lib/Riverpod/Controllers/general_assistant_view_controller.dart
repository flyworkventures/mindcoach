// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mindcoach/core/repo/chat_repo.dart';

/// General Assistant için mesaj modeli (sadece memory'de tutulur)
class GeneralAssistantMessage {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isFromMe;
  final String? imageUrl;
  final String? audioUrl;
  final String? voiceMessageContent; // Sesli mesajın metne çevrilmiş hali

  const GeneralAssistantMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isFromMe,
    this.imageUrl,
    this.audioUrl,
    this.voiceMessageContent,
  });
}

class GeneralAssistantState {
  final List<GeneralAssistantMessage> messages;
  final XFile? selectedImage;
  final bool isRecording;
  final String? recordingPath;
  final Duration recordingDuration;

  const GeneralAssistantState({
    required this.messages,
    this.selectedImage,
    this.isRecording = false,
    this.recordingPath,
    this.recordingDuration = Duration.zero,
  });

  GeneralAssistantState copyWith({
    List<GeneralAssistantMessage>? messages,
    XFile? selectedImage,
    bool clearSelectedImage = false,
    bool? isRecording,
    String? recordingPath,
    Duration? recordingDuration,
  }) {
    return GeneralAssistantState(
      messages: messages ?? this.messages,
      selectedImage: clearSelectedImage ? null : (selectedImage ?? this.selectedImage),
      isRecording: isRecording ?? this.isRecording,
      recordingPath: recordingPath ?? this.recordingPath,
      recordingDuration: recordingDuration ?? this.recordingDuration,
    );
  }
}

class GeneralAssistantViewController extends Notifier<GeneralAssistantState> {
  final ImagePicker _picker = ImagePicker();
  AudioRecorder? _audioRecorder;
  String? _currentRecordingPath;

  @override
  GeneralAssistantState build() {
    return const GeneralAssistantState(messages: []);
  }

  /// AudioRecorder'ı lazy olarak initialize et
  Future<AudioRecorder> _getAudioRecorder() async {
    if (_audioRecorder == null) {
      _audioRecorder = AudioRecorder();
      // Ses kayıt izinlerini kontrol et
      try {
        if (await _audioRecorder!.hasPermission()) {
          log("✅ Ses kayıt izni var");
        } else {
          log("❌ Ses kayıt izni yok");
        }
      } catch (e) {
        log("⚠️ Ses kayıt izni kontrolü hatası: $e");
      }
    }
    return _audioRecorder!;
  }

  /// Resim seç
  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        state = state.copyWith(selectedImage: image);
        log("✅ Resim seçildi: ${image.path}");
      }
    } catch (e) {
      log("❌ Resim seçme hatası: $e");
    }
  }

  /// Seçili resmi temizle
  void clearSelectedImage() {
    state = state.copyWith(clearSelectedImage: true);
  }

  /// Ses kaydına başla
  Future<void> startRecording() async {
    try {
      final recorder = await _getAudioRecorder();
      
      // Geçici dosya yolu oluştur
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';
      
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );
      
      state = state.copyWith(
        isRecording: true,
        recordingPath: _currentRecordingPath,
        recordingDuration: Duration.zero,
      );
      
      log("✅ Ses kaydı başlatıldı: $_currentRecordingPath");
    } catch (e) {
      log("❌ Ses kaydı başlatma hatası: $e");
      state = state.copyWith(isRecording: false);
    }
  }

  /// Ses kaydını durdur
  Future<String?> stopRecording() async {
    try {
      if (_audioRecorder != null && state.isRecording) {
        await _audioRecorder!.stop();
        final path = _currentRecordingPath;
        _currentRecordingPath = null;
        
        state = state.copyWith(
          isRecording: false,
          recordingDuration: Duration.zero,
        );
        
        log("✅ Ses kaydı durduruldu: $path");
        return path;
      }
      return null;
    } catch (e) {
      log("❌ Ses kaydı durdurma hatası: $e");
      state = state.copyWith(isRecording: false);
      return null;
    }
  }

  /// Ses kaydını iptal et
  Future<void> cancelRecording() async {
    try {
      if (_audioRecorder != null && state.isRecording) {
        await _audioRecorder!.stop();
        // Kayıt dosyasını sil
        if (_currentRecordingPath != null) {
          try {
            final file = File(_currentRecordingPath!);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            log("⚠️ Kayıt dosyası silinemedi: $e");
          }
        }
        _currentRecordingPath = null;
        
        state = state.copyWith(
          isRecording: false,
          recordingDuration: Duration.zero,
        );
        
        log("✅ Ses kaydı iptal edildi");
      }
    } catch (e) {
      log("❌ Ses kaydı iptal hatası: $e");
    }
  }

  /// Kayıt süresini güncelle
  void updateRecordingDuration(Duration duration) {
    if (state.isRecording) {
      state = state.copyWith(recordingDuration: duration);
    }
  }

  /// General Assistant mesaj gönder - text, image veya voice
  Future<void> sendMessage({
    String? message,
    File? imageFile,
    File? audioFile,
  }) async {
    try {
      ChatRepo chatRepo = ChatRepo(ref);
      
      // API'ye gönder ve response'u al
      final responseData = await chatRepo.sendGeneralAssistantMessage(
        message: message,
        imageFile: imageFile,
        audioFile: audioFile,
      );
      
      // Sesli mesaj için transcribed text'i al (API response'undan)
      String? transcribedText;
      if (audioFile != null && responseData != null) {
        transcribedText = responseData['transcribedText'] as String? ?? 
                         responseData['voiceMessageContent'] as String?;
      }
      
      // Kullanıcının mesajını ekle (response'dan sonra, böylece transcribed text'i ekleyebiliriz)
      final userMessage = GeneralAssistantMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: message ?? (imageFile != null ? '[Resim]' : '[Sesli Mesaj]'),
        createdAt: DateTime.now(),
        isFromMe: true,
        imageUrl: imageFile?.path,
        audioUrl: audioFile?.path,
        voiceMessageContent: transcribedText, // Sesli mesajın metne çevrilmiş hali
      );
      
      state = state.copyWith(
        messages: [userMessage, ...state.messages],
        clearSelectedImage: true,
      );
      
      // API'den gelen assistant cevabını ekle
      if (responseData != null) {
        final assistantMessage = responseData['message'] as String?;
        
        if (assistantMessage != null && assistantMessage.isNotEmpty) {
          final assistantResponse = GeneralAssistantMessage(
            id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
            text: assistantMessage,
            createdAt: DateTime.now(),
            isFromMe: false,
          );
          
          state = state.copyWith(
            messages: [assistantResponse, ...state.messages],
          );
          
          log("✅ Assistant cevabı eklendi: $assistantMessage");
        }
      }
      
      log("✅ General Assistant mesajı gönderildi");
    } catch (e) {
      log("❌ General Assistant mesaj gönderme hatası: $e");
      rethrow;
    }
  }

  /// Tüm mesajları temizle (ekrandan çıkınca)
  void clearMessages() {
    state = state.copyWith(messages: []);
    log("✅ General Assistant mesajları temizlendi");
  }
  
  void cleanup() {
    _audioRecorder?.dispose();
    _audioRecorder = null;
  }
}

final generalAssistantViewControllerProvider =
    NotifierProvider<GeneralAssistantViewController, GeneralAssistantState>(
  GeneralAssistantViewController.new,
);
