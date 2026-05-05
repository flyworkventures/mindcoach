// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindcoach/Http/http_service.dart';
import 'package:mindcoach/models/consultant_model.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mindcoach/core/repo/chat_repo.dart';
import 'package:mindcoach/models/message_model.dart';

import '../../specialists_screen/specialists_notifier.dart';
import '../chat_notifier.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/TrialQuotaService/trial_quota_service.dart';

class ChatMessage {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isFromMe;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isFromMe,
  });
}

class ConversationsState {
  final List<MessageModel> messages;
  final bool isLoadingMessages;
  final XFile? selectedImage;
  final bool isRecording;
  final String? recordingPath;
  final Duration recordingDuration;
  final ConsultantModel? consultantModel;
  final File? threeD;
  final DateTime? appointmentDate;
 
  const ConversationsState({
    required this.messages,
    this.isLoadingMessages = false,
    this.selectedImage,
    this.isRecording = false,
    this.recordingPath,
    this.recordingDuration = Duration.zero,
    this.consultantModel,
    this.threeD,
   this.appointmentDate,
  });
 
  ConversationsState copyWith({
    List<MessageModel>? messages,
    bool? isLoadingMessages,
    XFile? selectedImage,
    bool clearSelectedImage = false,
    bool? isRecording,
    String? recordingPath,
    Duration? recordingDuration,
    ConsultantModel? consultantModel,
    File? threeD,
    DateTime? appointmentDate,
    
  }) {
    return ConversationsState(
      messages: messages ?? this.messages,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      selectedImage: clearSelectedImage ? null : (selectedImage ?? this.selectedImage),
      isRecording: isRecording ?? this.isRecording,
      recordingPath: recordingPath ?? this.recordingPath,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      consultantModel: consultantModel ?? this.consultantModel,
      threeD: threeD ?? this.threeD,
     appointmentDate: appointmentDate ?? this.appointmentDate,
    );
  }
  }

class ConversationsNotifier extends StateNotifier<ConversationsState> {
  Ref? ref;
  final ImagePicker _picker = ImagePicker();
  AudioRecorder? _audioRecorder;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  
  ConversationsNotifier(this.ref) : super(ConversationsState(messages: []));

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
        log("❌ Ses kayıt izni kontrolü hatası: $e");
      }
    }
    return _audioRecorder!;
  }



  Future<void> getMessages(int id)async{
    final shouldShowInitialLoading = state.messages.isEmpty;
    if (shouldShowInitialLoading) {
      state = state.copyWith(isLoadingMessages: true);
    }
    try {
      ChatRepo chatRepo = ChatRepo(ref);
      List<MessageModel> messages = await chatRepo.getMessagesFromConsultantId(id.toString());
      state = state.copyWith(
        messages: messages,
        isLoadingMessages: false,
      );
    } catch (e) {
      log("❌ getMessages hatası: $e");
      state = state.copyWith(isLoadingMessages: false);
    }
  }

  /// Belirli bir consultant'ın mesajlarını temizle
  void clearMessages(int consultantId) {
    // Eğer mevcut mesajlar bu consultant'a aitse, temizle
    // Not: Bu basit bir implementasyon, daha gelişmiş bir çözüm için
    // mesajları consultantId'ye göre gruplamak gerekebilir
    state = state.copyWith(messages: [], isLoadingMessages: true);
  }


  /// Premium kontrolü yap
  bool _isPremium() {
    try {
      // Premium provider'dan premium status'u al (device-based)
      final premiumState = ref!.watch(AllProviders.premiumProvider);
      return premiumState.isPremium;
    } catch (e) {
      log("⚠️ Premium kontrolü hatası: $e");
      return false;
    }

    
  }

  /// Premium mesaj gönder - text, image veya voice gönderebilir
  Future<void> sendPremiumMessage({
    required int consultantId,
    String? message,
    File? imageFile,
    File? audioFile,
  }) async {
    // --- OPTİMİSTİK UPDATE: Mesajı API cevabı beklemeden anında ekle ---
    MessageModel? optimisticMsg;
    if (message != null && message.trim().isNotEmpty && imageFile == null && audioFile == null) {
      optimisticMsg = MessageModel(
        messageId: -DateTime.now().millisecondsSinceEpoch, // geçici negatif ID
        chatId: 0,
        senderId: 0,
        sender: 'user',
        message: message.trim(),
        sentTime: DateTime.now().toIso8601String(),
      );
      state = state.copyWith(messages: [...state.messages, optimisticMsg]);

      // Chat listesini de hemen güncelle
      _updateChatListLastMessage(consultantId, message.trim(), true);
    }

    try {
      ChatRepo chatRepo = ChatRepo(ref);
      await chatRepo.sendPremiumMessage(
        consultantId: consultantId,
        message: message,
        imageFile: imageFile,
        audioFile: audioFile,
      );

      // Resim/ses için chat listesini güncelle (text için zaten yapıldı)
      if (imageFile != null || audioFile != null) {
        final lastMessage = imageFile != null
            ? (message?.isNotEmpty == true ? message! : '[Resim]')
            : (message?.isNotEmpty == true ? message! : '[Sesli Mesaj]');
        _updateChatListLastMessage(consultantId, lastMessage, true);
        // Resim/ses mesajlarında optimistik update yok, sunucudan çek
        await getMessages(consultantId);
      }
      // Text mesajlarda getMessages çağırmıyoruz — optimistik mesaj zaten gösteriliyor,
      // 4 saniyelik polling timer sunucu cevabını (AI yanıtı dahil) yakalayacak.
    } catch (e) {
      // Hata durumunda optimistik mesajı geri al
      if (optimisticMsg != null) {
        final filtered = state.messages
            .where((m) => m.messageId != optimisticMsg!.messageId)
            .toList();
        state = state.copyWith(messages: filtered);
      }
      log("❌ sendPremiumMessage hatası: $e");
      rethrow;
    }
  }

  /// Normal mesaj gönder - premium kontrolü + trial kotası uygular.
  ///
  /// Non-premium kullanıcı için 10 mesajlık deneme kotası kontrol edilir.
  /// Kota dolmuşsa [TrialQuotaExceededException] fırlatılır; UI bunu yakalayıp
  /// paywall açmalı.
  ///
  /// 💡 Premium users: Sınırsız mesaj
  /// 💡 Trial users: 10 mesaj hakkı → paywall
  Future<void> sendMessage({
    required int id,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final bool isPremium = _isPremium();

    // Trial kota kontrolü — gönderim öncesi (10 mesaj limit).
    if (!isPremium) {
      final canSend = await TrialQuotaService.instance.canSendMessage();
      if (!canSend) {
        throw TrialQuotaExceededException.message();
      }
    }

    // NOT: Backend'de "premium" / "normal" mesaj endpoint ayrımı var; mevcut
    // davranış tüm mesajları premium endpoint'ine gönderiyordu. Trial kotası
    // kontrolünü yukarıda client tarafında yaptığımız için bu davranışı aynen
    // koruyoruz — backend tarafında ayrıca limit kontrolü yoksa client gating
    // tek savunma hattı. Backend ayrımı netleşince burada split yapılır.
    await sendPremiumMessage(consultantId: id, message: trimmed);

    // Başarılı gönderim → trial sayacını ilerlet (sadece non-premium).
    if (!isPremium) {
      await TrialQuotaService.instance.incrementMessage();
    }
  }
  
  /// Consultant ID'yi SpecialistId'ye çevir (basit mapping: 1-5 arası)
  SpecialistId? _consultantIdToSpecialistId(int consultantId) {
    if (consultantId >= 1 && consultantId <= 5) {
      return SpecialistId.values[consultantId - 1];
    }
    return null;
  }
  
  /// Chat listesindeki son mesajı güncelle
  void _updateChatListLastMessage(int consultantId, String lastMessage, bool isFromMe) {
    try {
      final specialistId = _consultantIdToSpecialistId(consultantId);
      if (specialistId != null && ref != null) {
        ref!.read(chatProvider.notifier).upsertLastMessage(
          id: specialistId,
          consultantId: consultantId,  // gerçek API ID'si
          lastMessage: lastMessage,
          time: DateTime.now(),
          isFromMe: isFromMe,
        );
        log("✅ Chat listesi güncellendi: consultantId=$consultantId, message=$lastMessage");
      }
    } catch (e) {
      log("⚠️ Chat listesi güncelleme hatası: $e");
    }
  }

  /// Resim mesajı gönder — trial kotası 20 mesajlık genel kotaya dahildir.
  Future<void> sendImageMessage({
    required int consultantId,
    required File imageFile,
    String? message,
  }) async {
    final isPremium = _isPremium();

    if (!isPremium) {
      final canSend = await TrialQuotaService.instance.canSendMessage();
      if (!canSend) {
        throw TrialQuotaExceededException.message();
      }
    }

    if (isPremium) {
      await sendPremiumMessage(
        consultantId: consultantId,
        imageFile: imageFile,
        message: message,
      );
    } else {
      ChatRepo chatRepo = ChatRepo(ref);
      await chatRepo.sendImageMessage(
        consultantId: consultantId,
        imageFile: imageFile,
        message: message,
      );
      final lastMessage = message?.isNotEmpty == true ? message! : '[Resim]';
      _updateChatListLastMessage(consultantId, lastMessage, true);
    }

    if (!isPremium) {
      await TrialQuotaService.instance.incrementMessage();
    }
  }

  /// Sesli mesaj gönder — trial kotası 20 mesajlık genel kotaya dahildir.
  Future<void> sendVoiceMessage({
    required int consultantId,
    required File audioFile,
    String? message,
  }) async {
    try {
      final isPremium = _isPremium();

      if (!isPremium) {
        final canSend = await TrialQuotaService.instance.canSendMessage();
        if (!canSend) {
          throw TrialQuotaExceededException.message();
        }
      }

      if (isPremium) {
        await sendPremiumMessage(
          consultantId: consultantId,
          audioFile: audioFile,
          message: message,
        );
      } else {
        ChatRepo chatRepo = ChatRepo(ref);
        await chatRepo.sendVoiceMessage(
          consultantId: consultantId,
          audioFile: audioFile,
          message: null,
        );
        _updateChatListLastMessage(consultantId, '[Sesli Mesaj]', true);
      }

      if (!isPremium) {
        await TrialQuotaService.instance.incrementMessage();
      }
    } catch (e) {
      log("❌ sendVoiceMessage hatası: $e");
      rethrow;
    }
  }

  void receiveDummyReply({
    required SpecialistId id,
    String text = "Got it. Tell me more.",
  }) {
    // TODO: Implement dummy reply functionality if needed
    /*
    final msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      createdAt: DateTime.now(),
      isFromMe: false,
    );
    final current = messagesOf(id);
    state = state.copyWith(
      messagesBySpecialist: {
        ...state.messagesBySpecialist,
        id: [msg, ...current],
      },
    );
    */
  }

  void clearConversation(SpecialistId id) {
    /*
    final map = {...state.messagesBySpecialist}..remove(id);
    state = state.copyWith(messagesBySpecialist: map);
    */
  }

  /// Galeriden resim seç
  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        log("Image selected: ${image.path}");
        state = state.copyWith(selectedImage: image);
      }
    } catch (e) {
      log("Error picking image: $e");
    }
  }

  /// Kameradan resim seç
  Future<void> pickImageFromCamera() async {
    try {
      log("📷 [CAMERA] Kamera açılıyor...");
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image != null) {
        log("✅ [CAMERA] Fotoğraf seçildi: ${image.path}");
        state = state.copyWith(selectedImage: image);
      } else {
        log("ℹ️ [CAMERA] Kullanıcı fotoğraf çekmeyi iptal etti");
      }
    } catch (e, stackTrace) {
      log("❌ [CAMERA] Kamera hatası: $e");
      log("❌ [CAMERA] Stack trace: $stackTrace");
    }
  }

  /// Seçili resmi temizle
  void clearSelectedImage() {
    state = state.copyWith(clearSelectedImage: true);
    debugPrint("Resim temizlendi, yeni state: ${state.selectedImage?.path}");
  }

  /// Ses kaydı başlat (RecorderController ile)
  Future<void> startRecordingWithPath(String path) async {
    // Eğer zaten kayıt yapılıyorsa, önce durdur
    if (state.isRecording) {
      await stopRecording();
    }

    try {
      _currentRecordingPath = path;
      _recordingStartTime = DateTime.now();

      state = state.copyWith(
        isRecording: true,
        recordingPath: _currentRecordingPath,
        recordingDuration: Duration.zero,
      );

      log("🎤 Ses kaydı başlatıldı: $_currentRecordingPath");
    } catch (e) {
      log("❌ Ses kaydı başlatılamadı: $e");
    }
  }

  /// Ses kaydı başlat (eski metod - geriye dönük uyumluluk için)
  Future<void> startRecording() async {
    // Bu metod artık kullanılmıyor, RecorderController kullanılıyor
    log("⚠️ startRecording() kullanılmıyor, startRecordingWithPath() kullanın");
  }

  /// Ses kaydını durdur (RecorderController kullanıldığı için sadece state güncellemesi yapıyor)
  /// Path UI'dan (RecorderController.stop()) geliyor
  Future<String?> stopRecording({bool cancel = false}) async {
    if (!state.isRecording) {
      log("⚠️ stopRecording çağrıldı ama kayıt yapılmıyor");
      return null;
    }

    try {
      final path = state.recordingPath;
      
      if (cancel) {
        // Kayıt iptal edildi, dosyayı sil
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            log("🗑️ İptal edilen kayıt dosyası silindi: $path");
          }
        }
        state = state.copyWith(
          isRecording: false,
          recordingPath: null,
          recordingDuration: Duration.zero,
        );
        _currentRecordingPath = null;
        _recordingStartTime = null;
        return null;
      }

      // Kayıt başarılı - state'i güncelle
      state = state.copyWith(
        isRecording: false,
        recordingDuration: Duration.zero,
      );

      if (path != null) {
        final recordingFile = File(path);
        if (await recordingFile.exists()) {
          log("✅ Ses kaydı tamamlandı: $path");
          _currentRecordingPath = null;
          _recordingStartTime = null;
          return path;
        } else {
          log("❌ Ses kaydı dosyası bulunamadı: $path");
        }
      }

      _currentRecordingPath = null;
      _recordingStartTime = null;
      return null;
    } catch (e) {
      log("❌ Ses kaydı durdurulamadı: $e");
      state = state.copyWith(
        isRecording: false,
        recordingPath: null,
        recordingDuration: Duration.zero,
      );
      _currentRecordingPath = null;
      _recordingStartTime = null;
      return null;
    }
  }

  /// Kayıt süresini güncelle
  void updateRecordingDuration() {
    if (state.isRecording && _recordingStartTime != null) {
      final duration = DateTime.now().difference(_recordingStartTime!);
      state = state.copyWith(recordingDuration: duration);
    }
  }

  /// Kayıt path'ini güncelle (RecorderController.stop() sonrası)
  void updateRecordingPath(String path) {
    _currentRecordingPath = path;
    state = state.copyWith(recordingPath: path);
    log("📝 Kayıt path güncellendi: $path");
  }

  /// Ses kaydını iptal et
  Future<void> cancelRecording() async {
    await stopRecording(cancel: true);
  }

  /// Cleanup: AudioRecorder'ı dispose et
  @override
  void dispose() {
    try {
      // Eğer kayıt devam ediyorsa durdur
      if (state.isRecording) {
        stopRecording(cancel: true);
      }
      // AudioRecorder'ı temizle (record paketi 6.x'te dispose yoksa null yap)
      _audioRecorder = null;
    } catch (e) {
      log("❌ AudioRecorder dispose hatası: $e");
    }
    super.dispose();
  }




  /// Video call başlat (3D model indirme ve state yönetimi)
  Future<void> startVideoCall(ConsultantModel consultant, DateTime? appointmentDate) async {
    try {
      state.copyWith(appointmentDate: appointmentDate);
      // url3d null kontrolü
      if (consultant.url3d == null || consultant.url3d!.isEmpty) {
        log("⚠️ Consultant'ın 3D model URL'i yok: ${consultant.id}");
        state = state.copyWith(consultantModel: consultant);
        return;
      }

      log("📥 3D model indiriliyor: ${consultant.url3d}");
      
      HttpService httpService = HttpService(ref: ref);
      final response = await httpService.getUrl(url: consultant.url3d!);
      
      if (response.statusCode != 200) {
        log("❌ 3D model indirme hatası: ${response.statusCode}");
        state = state.copyWith(consultantModel: consultant);
        return;
      }

      final path = await getTemporaryDirectory();
      final file = File('${path.path}/model_${consultant.id}_${DateTime.now().millisecondsSinceEpoch}.glb');
      await file.writeAsBytes(response.bodyBytes);

      log("✅ 3D model indirildi: ${file.path}");
      
      state = state.copyWith(
        consultantModel: consultant,
        threeD: file,
      );
    } catch (e) {
      log("❌ startVideoCall hatası: $e");
      // Hata olsa bile consultant model'i state'e ekle
      state = state.copyWith(consultantModel: consultant);
    }
  }


}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) => ConversationsNotifier(ref));
