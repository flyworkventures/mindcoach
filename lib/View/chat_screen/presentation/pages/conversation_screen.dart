import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart' as audio_players;
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:mindcoach/View/chat_screen/notifiers/conversation_notifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mindcoach/core/locale/locale_provider.dart';

import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/locale_font_scaler.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

import 'package:mindcoach/View/chat_screen/constants/conversation_strings.dart';
import 'package:mindcoach/View/chat_screen/constants/chat_strings.dart';
import 'package:mindcoach/models/consultant_model.dart';
import 'package:mindcoach/models/message_model.dart';
import 'package:mindcoach/Riverpod/providers/user_provider.dart';
 


 

// Stil bilgileri için kullanılan sabitler
const Color _kAppbarGreen = Color(0xFF11998E);
const Color _kAppbarLightGreen = Color(0xFF38EF7D);
const Color _kGreetingStart = Color(0xFF2BD383);
const Color _kGreetingEnd = Color(0xFF11998E);
const Color _kFreeBorder = Color(0xFF686868);
const Color _kFreeText = Color(0xFF5A5A5A);
const Color _kInputShadow = Color(0x40000000);

class ConversationScreen extends ConsumerStatefulWidget {
  final ConsultantModel specialistId;

  const ConversationScreen({
    super.key,
    required this.specialistId,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

// Global AudioPlayer controller - aynı anda sadece bir ses oynatılabilir
final _globalAudioPlayer = audio_players.AudioPlayer();
String? _currentlyPlayingMessageId;

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isMenuOpen = false;
  String? _lastProcessedImagePath; // İşlenen son resmin path'ini tutar
  bool _isSendingImage = false; // Resim gönderilirken flag
  Timer? _recordingTimer; // Kayıt süresi için timer
  Timer? _messagesStreamTimer; // Mesajları periyodik çekmek için timer
  RecorderController? _recorderController; // Ses kaydı için controller

   @override
  void initState() {
    super.initState();
    // RecorderController'ı initialize et (standart kalite ayarları)
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..sampleRate = 44100 // Standart sample rate
      ..bitRate = 128000; // 128 kbps (standart kalite)
      // iOS için encoder otomatik olarak aacLc kullanılır
    debugPrint("✅ RecorderController initialize edildi");
    
    // Sayfa açıldığında eski seçili resmi temizle
    Future.microtask(() async {
      if (!mounted) return;
      try {
        ref.read(conversationsProvider.notifier).clearSelectedImage();
        _lastProcessedImagePath = null;
        if (mounted) {
          await ref.read(conversationsProvider.notifier).getMessages(widget.specialistId.id);
        }
      } catch (e) {
        debugPrint("❌ ConversationPage initState hatası: $e");
      }
    });
    
    // Mesajları periyodik olarak çek (0.5 saniyede bir)
    _messagesStreamTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        ref.read(conversationsProvider.notifier).getMessages(widget.specialistId.id);
      } else {
        _messagesStreamTimer?.cancel();
        _messagesStreamTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recordingTimer?.cancel();
    _messagesStreamTimer?.cancel();
    _recorderController?.dispose();
    // Eğer kayıt devam ediyorsa durdur (mounted kontrolü ile)
    if (mounted) {
      try {
        final isRecording = ref.read(conversationsProvider).isRecording;
        if (isRecording) {
          ref.read(conversationsProvider.notifier).cancelRecording();
        }
      } catch (e) {
        // Widget unmount olduysa ref kullanılamaz, sessizce devam et
        debugPrint("⚠️ dispose sırasında ref kullanılamadı (normal): $e");
      }
    }
    super.dispose();
  }
  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
    // Menü açıldığında eski seçili resmi temizle
    if (_isMenuOpen) {
      ref.read(conversationsProvider.notifier).clearSelectedImage();
      _lastProcessedImagePath = null;
    }
  }
  @override
  Widget build(BuildContext context) {
    // Read messages from provider and sort by sentTime.
    // DB provides ISO strings like "2025-12-29T01:58:44.512Z" — parse them to DateTime.
    final List<MessageModel> allMessages = ref.watch(conversationsProvider).messages;
    
    // Seçilen resmi dinle (otomatik gönderme yok, buton ile gönderilecek)
    final selectedImage = ref.watch(conversationsProvider.select((state) => state.selectedImage));
    final isRecording = ref.watch(conversationsProvider.select((state) => state.isRecording));
    
    // Kayıt süresini güncelle
    if (isRecording && _recordingTimer == null) {
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          ref.read(conversationsProvider.notifier).updateRecordingDuration();
        } else {
          _recordingTimer?.cancel();
          _recordingTimer = null;
        }
      });
    } else if (!isRecording && _recordingTimer != null) {
      _recordingTimer?.cancel();
      _recordingTimer = null;
    }
    
    // Eğer resim temizlendiyse _lastProcessedImagePath'i de temizle
    if (selectedImage == null && _lastProcessedImagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _lastProcessedImagePath = null;
          });
        }
      });
    }
    
    // Mesajları tarihe göre sırala (yeni -> eski)
    // reverse: true olduğu için ListView'da ters çevrilir ve en altta en yeni mesaj görünecek
    final List<MessageModel> messages = List.from(allMessages)
      ..sort((a, b) {
        final dateA = _parseSentTime(a.sentTime);
        final dateB = _parseSentTime(b.sentTime);
        return dateB.compareTo(dateA); // Yeni mesajlar önce, eski mesajlar sonra (reverse ile eski->yeni görünecek)
      });



    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBFCFF), Color(0xFFF9FAFF)],
            stops: [0.075, 1.0133],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildCustomAppBar(context),

                  if(messages.isEmpty)...[
                        Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
                      width: 339.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.w),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          if (messages.isEmpty) Center(child: _buildGreetingContent()),

                          ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            reverse: true,
                            itemCount: messages.length,
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                            itemBuilder: (context, index) {
                              final m = messages[index];
                              return _MessageBubble(message: m);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],

         if(messages.isNotEmpty)...[
                        Expanded(
                    child: Stack(
                      children: [
  
                    
                        ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          reverse: true,
                          itemCount: messages.length,
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                          itemBuilder: (context, index) {
                            final m = messages[index];
                            return _MessageBubble(message: m);
                          },
                        ),
                      ],
                    ),
                  ),
                  ],


              

                  _buildInputArea(
                    widget.specialistId.names[ref.read(localeProvider.notifier).getLanguageCode()],
                    selectedImage,
                  ),
                ],
              ),

              if (_isMenuOpen) ...[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() => _isMenuOpen = false),
                    child: const SizedBox.expand(),
                  ),
                ),
                _buildAttachmentMenu(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(top: 15.h, bottom: 10.h, left: 16.w, right: 16.w),
      child: SizedBox(
        height: 40.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: SvgPicture.asset('assets/svg/arrow_back.svg', width: 10.w),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            Center(
              child: Text(
                'Mind Coach',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22.w,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1 * 20.w,
                  height: 1.0,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_kAppbarGreen, _kAppbarLightGreen],
                      stops: [0.369, 2.0276],
                    ).createShader(Rect.fromLTWH(0, 0, 350.w, 50.h)),
                ),
              ),
            ),

            Positioned(
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IntrinsicWidth(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27.w),
                        border: Border.all(color: _kFreeBorder, width: 1.w),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        child: Text(
                          l10n.free,
                          style: GoogleFonts.quicksand(
                            fontSize: 10.w,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            color: _kFreeText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 38.w,
                    height: 38.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                      image:  DecorationImage(
                        image: NetworkImage(ref.read(userProvider)?.profilePhotoUrl ?? AppConstants.defaultPpUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(String mentorName, XFile? selectedImage) {
    final hasText = _messageController.text.trim().isNotEmpty;
    var hasImage = ref.watch(conversationsProvider).selectedImage != null;
    final isRecording = ref.watch(conversationsProvider.select((state) => state.isRecording));
    final recordingDuration = ref.watch(conversationsProvider.select((state) => state.recordingDuration));
    final canSend = hasText || hasImage;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Overflow'u önlemek için
        children: [
          // Kayıt UI'ı - WhatsApp tarzı (overflow düzeltildi)
          if (isRecording)
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
              width: 339.w,
              constraints: BoxConstraints(
                maxHeight: 100.h, // Overflow'u önlemek için max height
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                boxShadow: const [
                  BoxShadow(
                    color: _kInputShadow,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max, // Overflow'u önlemek için
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 12.w,
                                  height: 12.h,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    _formatDuration(recordingDuration),
                                    style: GoogleFonts.quicksand(
                                      fontSize: 14.w,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                       
                        ],
                      ),
                    ),
                  ),
                  // Gerçek zamanlı waveform
                  if (_recorderController != null)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: SizedBox(
                          height: 40.h,
                          width: double.infinity,
                          child: AudioWaveforms(
                            size: Size(315.w, 40.h),
                            recorderController: _recorderController!,
                            waveStyle: WaveStyle(
                              waveColor: Colors.grey,
                              extendWaveform: true,
                              showMiddleLine: false,
                              waveThickness: 2.0,
                            ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.w),
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ),

                  if (_recorderController != null)
                      Expanded(
                            child: IconButton(
                              onPressed: () async {
                                // Kayıt iptal et
                                if (mounted) {
                                  await ref.read(conversationsProvider.notifier).cancelRecording();
                                  if (_recorderController != null) {
                                    await _recorderController!.stop();
                                  }
                                }
                              },
                              icon: Icon(Icons.close, color: Colors.red, size: 20.w),
                            ),
                          ),


                ],
              ),
            ),
          // Seçili resim preview
          if (hasImage && !isRecording)
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
              width: 339.w,
              height:    50.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40.w),
                boxShadow: const [
                  BoxShadow(
                    color: _kInputShadow,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                                      margin: EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40.w),
                          child: Image.file(
                            File(ref.watch(conversationsProvider).selectedImage!.path),
                            width: 50.w,
                            height: 50.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                        Text(
                   "Image",
                   maxLines: 1,
                   style: GoogleFonts.poppins(
                    
                  
                   ),
                  ),
                    ],
                  ),
                
                  IconButton(
                    onPressed: () {
                      // Resmi state'ten temizle
                      ref.read(conversationsProvider.notifier).clearSelectedImage();
                      // UI'ı güncelle
                      setState(() {
                        _lastProcessedImagePath = null;
                      });
                    },
                    icon: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 16.w),
                    ),
                  ),
                ],
              ),
            ),
          // Input container
          Container(
            width: 339.w,
            constraints: BoxConstraints(
              maxHeight: 80.h, // Overflow'u önlemek için max height
            ),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.w),
              boxShadow: const [
                BoxShadow(
                  color: _kInputShadow,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Overflow'u önlemek için
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.quicksand(fontSize: 14.w),
                      decoration: InputDecoration(
                        hintText: ConversationStrings.askMentor(context, mentorName),
                        hintStyle: GoogleFonts.quicksand(
                          fontSize: 12.w,
                          fontWeight: FontWeight.w500,
                          height: 18.h / 12.w,
                          color: Colors.black,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (text) {
                        setState(() {}); // Buton durumunu güncelle
                      },
                      onSubmitted: (text) {
                        if (canSend) {
                          _sendMessage();
                        }
                      },
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max, // Overflow'u önlemek için
                  children: [
                    // Sol tarafta: Artı butonu
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: _toggleMenu,
                      icon: SvgPicture.asset(
                        'assets/svg/add_icon.svg',
                        width: 18.w,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                      ),
                    ),
                    // Ortada: Gönderme butonu (varsa)

                    // Sağ tarafta: Mikrofon ve Sparkles (video call) butonları
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Overflow'u önlemek için
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Ses kaydı butonu - onTap ile başlat, onLongPress ile de çalışır
                          GestureDetector(
                            onTap: () async {
                              // onTap ile kayıt başlat
                              if (!isRecording) {
                                await _startRecording();
                              }
                            },
                            onLongPressStart: (details) async {
                              // onLongPress ile de kayıt başlat
                              if (!isRecording) {
                                await _startRecording();
                              }
                            },
                            onLongPressEnd: (details) async {
                              // Basmayı bıraktığında otomatik gönder
                              debugPrint("🎤 onLongPressEnd tetiklendi, isRecording: $isRecording");
                              if (isRecording && _recorderController != null) {
                                await _stopAndSendRecording();
                              }
                            },
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: null, // GestureDetector kullanıyoruz
                              icon: SvgPicture.asset(
                                'assets/svg/microphone.svg',
                                width: 14.w,
                                colorFilter: ColorFilter.mode(
                                  isRecording ? Colors.red : Colors.black54,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          // Sparkles/Video call butonu
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () {
                              ref.read(conversationsProvider.notifier).startVideoCall(widget.specialistId,null);
                              Navigator.pushNamed(context, PageRoutes.videoCall);
                            },
                            icon: SvgPicture.asset('assets/svg/video_call.svg', width: 22.w),
                          ),

                                              if (canSend || isRecording)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: _isSendingImage ? null : (isRecording ? _sendVoiceMessageFromRecording : _sendMessage),
                        icon: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2BD383),
                            shape: BoxShape.circle,
                          ),
                          child: _isSendingImage
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.send, color: Colors.white, size: 16.w),
                        ),
                      ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mesaj gönderme işlemi (normal mesaj veya resim)
  Future<void> _sendMessage() async {
    final hasText = _messageController.text.trim().isNotEmpty;
    final selectedImage = ref.watch(conversationsProvider.select((state) => state.selectedImage));
    final hasImage = selectedImage != null;

    if (!hasText && !hasImage) return;

    try {
      if (hasImage) {
        // Resim gönder
        final image = ref.watch(conversationsProvider.select((state) => state.selectedImage));
        if (image != null) {
          await _handleImageSelected(image);
        }
      } else if (hasText) {
        // Normal mesaj gönder
        final trimmed = _messageController.text.trim();
        if (trimmed.isEmpty) return;

        // Eğer seçili resim varsa temizle (normal mesaj gönderilirken)
        if (hasImage) {
          ref.read(conversationsProvider.notifier).clearSelectedImage();
          setState(() {
            _lastProcessedImagePath = null;
          });
        }

        // Fire-and-forget: İstek gönderildikten sonra loading bitir
        ref.read(conversationsProvider.notifier).sendMessage(
              id: widget.specialistId.id,
              text: trimmed,
            ).then((_) {
          // Arka planda mesajları yükle
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ref.read(conversationsProvider.notifier).getMessages(widget.specialistId.id);
            }
          });
        }).catchError((e) {
          debugPrint("❌ Mesaj gönderme hatası: $e");
        });

        _messageController.clear();
        setState(() {}); // Buton durumunu güncelle
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj gönderilemedi: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAttachmentMenu(BuildContext context) {
    final l10n = context.l10n;
    return Positioned(
      bottom: 74.h,
      left: 20.w,
      child: Container(
        width: 107.w,
        height: 99.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMenuItem(
              l10n.camera,
              'assets/svg/camera_icon.svg',
              () async {
                _toggleMenu();
                await ref.read(conversationsProvider.notifier).pickImageFromCamera();
              },
            ),
            _buildMenuItem(
              l10n.gallery,
              'assets/svg/gallery_icon.svg',
              () async {
                _toggleMenu();
                await ref.read(conversationsProvider.notifier).pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, String svgPath, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Row(
            children: [
              SvgPicture.asset(
                svgPath,
                width: 20.w,
                colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: LocaleFontScaler.scale(context, 13),
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingContent() {
    return Center(
      child: Text(
        ChatStrings.greeting(context, ref.read(userProvider)?.username ?? "Mindcoach"),
        textAlign: TextAlign.center,
        style: GoogleFonts.quicksand(
          fontSize: 48.w,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1 * 48.w,
          height: 1.0,
          foreground: Paint()
            ..shader = const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [_kGreetingStart, _kGreetingEnd],
            ).createShader(Rect.fromLTWH(0, 0, 300.w, 50.h)),
        ),
      ),
    );
  }

  /// Sesli mesaj gönder
  Future<void> _sendVoiceMessage(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ses dosyası bulunamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Fire-and-forget: İstek gönderildikten sonra loading bitir
      ref.read(conversationsProvider.notifier).sendVoiceMessage(
            consultantId: widget.specialistId.id,
            audioFile: file,
            message: null, // Mesaj boş bırakılıyor
          ).then((_) {
        // Arka planda mesajları yükle
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ref.read(conversationsProvider.notifier).getMessages(widget.specialistId.id);
          }
        });
      }).catchError((e) {
        // Hata durumunda kullanıcıya bildir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sesli mesaj gönderilemedi: ${e.toString()}'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesli mesaj gönderilemedi: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Kayıt başlat (onTap ve onLongPressStart için ortak metod)
  Future<void> _startRecording() async {
    if (_recorderController == null) {
      _recorderController = RecorderController()
        ..androidEncoder = AndroidEncoder.aac
        ..androidOutputFormat = AndroidOutputFormat.mpeg4
        ..sampleRate = 44100 // Standart sample rate
        ..bitRate = 128000; // 128 kbps (standart kalite)
        // iOS için encoder otomatik olarak aacLc kullanılır
    }
    
    final isRecording = ref.read(conversationsProvider).isRecording;
    if (!isRecording && _recorderController != null) {
      try {
        final path = (await getTemporaryDirectory()).path + '/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
        debugPrint("🎤 Kayıt başlatılıyor: $path");
        
        // State'i önce güncelle
        await ref.read(conversationsProvider.notifier).startRecordingWithPath(path);
        
        // Sonra kaydı başlat
        await _recorderController!.record(path: path);
        debugPrint("🎤 RecorderController kayıt başladı");
      } catch (e, stackTrace) {
        debugPrint("❌ Kayıt başlatma hatası: $e");
        debugPrint("❌ Stack trace: $stackTrace");
        await ref.read(conversationsProvider.notifier).cancelRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ses kaydı başlatılamadı: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Kayıt durdur ve gönder (onLongPressEnd ve gönder butonu için)
  Future<void> _stopAndSendRecording() async {
    final isRecording = ref.read(conversationsProvider).isRecording;
    if (isRecording && _recorderController != null) {
      try {
        debugPrint("🎤 RecorderController durduruluyor...");
        
        // RecorderController'ı durdur ve path'i al
        final path = await _recorderController!.stop();
        debugPrint("🎤 RecorderController durduruldu, path: $path");
        
        // State'i güncelle (path'i state'e kaydet)
        if (path != null && path.isNotEmpty) {
          // Path'i state'e kaydet
          ref.read(conversationsProvider.notifier).updateRecordingPath(path);
          
          // State'i güncelle
          await ref.read(conversationsProvider.notifier).stopRecording();
          
          // Dosya var mı kontrol et
          final file = File(path);
          if (await file.exists() && mounted) {
            debugPrint("🎤 Sesli mesaj gönderiliyor: $path");
            await _sendVoiceMessage(path);
          } else {
            debugPrint("❌ Ses dosyası bulunamadı: $path");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ses dosyası bulunamadı'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          debugPrint("❌ Path null veya boş: $path");
          await ref.read(conversationsProvider.notifier).cancelRecording();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ses kaydı bulunamadı'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        debugPrint("❌ Kayıt durdurma hatası: $e");
        debugPrint("❌ Stack trace: $stackTrace");
        await ref.read(conversationsProvider.notifier).cancelRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ses kaydı durdurulamadı: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Sesli mesaj gönder (kayıt varsa)
  Future<void> _sendVoiceMessageFromRecording() async {
    if (ref.read(conversationsProvider).isRecording) {
      await _stopAndSendRecording();
    }
  }

  /// Süreyi formatla (mm:ss)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// sentTime'ı DateTime'a çevirir (String veya DateTime olabilir)
  DateTime _parseSentTime(dynamic sentTime) {
    if (sentTime == null) {
      return DateTime(1970); // Null ise çok eski bir tarih döndür
    }
    
    if (sentTime is DateTime) {
      return sentTime;
    }
    
    if (sentTime is String) {
      try {
        return DateTime.parse(sentTime);
      } catch (e) {
        // Parse edilemezse çok eski bir tarih döndür
        return DateTime(1970);
      }
    }
    
    // Diğer durumlar için çok eski bir tarih döndür
    return DateTime(1970);
  }

  /// Seçilen resmi işle ve gönder
  Future<void> _handleImageSelected(XFile image) async {
    // Aynı resmi tekrar işleme
    if (image.path == _lastProcessedImagePath || _isSendingImage) {
      return;
    }
    
    // İşlenen resmi işaretle ve flag'i set et
    setState(() {
      _lastProcessedImagePath = image.path;
      _isSendingImage = true;
    });
    
    if (!mounted) return;
    
    try {
      // XFile'ı File'a çevir
      final file = File(image.path);
      
      // Mesaj metnini al (varsa)
      final messageText = _messageController.text.trim();
      
      // Resmi gönder (API otomatik olarak CDN'e yükler)
      // Fire-and-forget: İstek gönderildikten sonra loading bitir, yanıt bekleme
      ref.read(conversationsProvider.notifier).sendImageMessage(
        consultantId: widget.specialistId.id,
        imageFile: file,
        message: messageText.isNotEmpty ? messageText : null,
      ).then((_) {
        // Arka planda mesajları yükle
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ref.read(conversationsProvider.notifier).getMessages(widget.specialistId.id);
          }
        });
      }).catchError((e) {
        // Hata durumunda kullanıcıya bildir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resim gönderilemedi: ${e.toString()}'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
      
      // Resmi ve mesajı hemen temizle (fire-and-forget yaklaşımı)
      // İstek gönderildi, kullanıcı yanıt beklemiyor
      _messageController.clear();
      
      // State'i temizle ve UI'ı güncelle
      ref.read(conversationsProvider.notifier).clearSelectedImage();
      
      // UI'ı güncelle - setState ile resim preview'ı kaldırılacak
      // ref.watch ile dinlenen selectedImage null olacak ve widget rebuild olacak
      if (mounted) {
        setState(() {
          _lastProcessedImagePath = null;
          _isSendingImage = false;
        });
      }
      
      // Loading direkt bitir, yanıt beklenmiyor
      // Başarı mesajı gösterilmiyor (fire-and-forget)
    } catch (e) {
      // Hata durumunda resmi temizleme (kullanıcı tekrar deneyebilir)
      
      // Hata mesajı
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim gönderilemedi: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Flag'i temizle
      if (mounted) {
        setState(() {
          _isSendingImage = false;
        });
      }
    }
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({required this.message});
  final MessageModel message;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  final PlayerController _playerController = PlayerController();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Ses dosyasının süresini önceden oku
    _loadAudioDuration();
    
    // Global AudioPlayer'ı dinle
    _globalAudioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        final isThisPlaying = _currentlyPlayingMessageId == widget.message.messageId.toString();
        setState(() {
          _isPlaying = isThisPlaying && state == audio_players.PlayerState.playing;
        });
      }
    });
    _globalAudioPlayer.onDurationChanged.listen((duration) {
      if (mounted && duration != Duration.zero) {
        // Tüm mesajlar için duration'ı güncelle (aynı URL'ye sahipse)
        setState(() {
          _duration = duration;
        });
      }
    });
    _globalAudioPlayer.onPlayerComplete.listen((_) {
      if (mounted && _currentlyPlayingMessageId == widget.message.messageId.toString()) {
        setState(() {
          _isPlaying = false;
        });
        _currentlyPlayingMessageId = null;
      }
    });
    
    // PlayerController'ı ses URL'si ile başlat (sadece gerektiğinde)
    // preparePlayer çağrısını kaldırdık - oynatma sırasında hazırlanacak
  }

  Future<void> _loadAudioDuration() async {
    if (widget.message.voiceURL != null && widget.message.voiceURL!.isNotEmpty) {
      try {
        // Ses dosyasının süresini oku - geçici bir player ile
        final tempPlayer = audio_players.AudioPlayer();
        Duration? loadedDuration;
        bool durationLoaded = false;
        
        // Duration'ı dinle
        final subscription = tempPlayer.onDurationChanged.listen((duration) {
          if (duration != Duration.zero && !durationLoaded) {
            loadedDuration = duration;
            durationLoaded = true;
          }
        });
        
        await tempPlayer.setSource(audio_players.UrlSource(widget.message.voiceURL!));
        
        // Duration'ın yüklenmesini bekle (max 2 saniye)
        int attempts = 0;
        while (!durationLoaded && attempts < 20 && mounted) {
          await Future.delayed(Duration(milliseconds: 100));
          attempts++;
        }
        
        await subscription.cancel();
        await tempPlayer.dispose();
        
        if (loadedDuration != null && mounted) {
          setState(() {
            _duration = loadedDuration!;
          });
          debugPrint("✅ Ses süresi yüklendi: ${_duration.inSeconds}s");
        }
      } catch (e) {
        debugPrint("❌ Ses süresi okunamadı: $e");
        // Hata durumunda süreyi 0 olarak bırak
      }
    }
  }

  @override
  void dispose() {
    // Eğer bu mesaj oynatılıyorsa durdur
    if (_currentlyPlayingMessageId == widget.message.messageId.toString()) {
      _globalAudioPlayer.stop();
      _currentlyPlayingMessageId = null;
    }
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      // Eğer başka bir mesaj oynatılıyorsa durdur
      if (_currentlyPlayingMessageId != null && _currentlyPlayingMessageId != widget.message.messageId.toString()) {
        await _globalAudioPlayer.stop();
      }

      if (_isPlaying) {
        await _globalAudioPlayer.pause();
        _currentlyPlayingMessageId = null;
        setState(() {
          _isPlaying = false;
        });
      } else {
        if (widget.message.voiceURL != null && widget.message.voiceURL!.isNotEmpty) {
          _currentlyPlayingMessageId = widget.message.messageId.toString();
          
          try {
            // Önce source'u set et
            await _globalAudioPlayer.setSource(audio_players.UrlSource(widget.message.voiceURL!));
            // Sonra play
            await _globalAudioPlayer.resume();
            setState(() {
              _isPlaying = true;
            });
          } catch (e) {
            debugPrint("❌ Ses oynatma hatası: $e");
            _currentlyPlayingMessageId = null;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ses dosyası oynatılamadı'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Sesli mesaj oynatma hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesli mesaj oynatılamadı: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.sender == "user";
    final hasImage = widget.message.isFile == true && widget.message.fileURL != null && widget.message.fileURL!.isNotEmpty;
    final hasVoice = widget.message.isVoiceMessage == true && widget.message.voiceURL != null && widget.message.voiceURL!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 260.w),
            child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF2BD383) : const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(16.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resim varsa göster
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.w),
                    child: Image.network(
                      widget.message.fileURL!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150.h,
                          color: Colors.grey[300],
                          child: Icon(Icons.broken_image, color: Colors.grey[600]),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 150.h,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                // Sesli mesaj varsa göster
                if (hasVoice) ...[
                  if (hasImage) SizedBox(height: 8.h),
                  Row(
                    mainAxisSize: MainAxisSize.min, // Overflow'u önlemek için
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: isMe ? Colors.white : Colors.black87,
                          size: 24.w,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Overflow'u önlemek için
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gerçek zamanlı waveform - oynatma sırasında animasyonlu
                            StreamBuilder<Duration>(
                              stream: _isPlaying 
                                  ? Stream.periodic(Duration(milliseconds: 100), (_) {
                                      // Position'ı stream'den al
                                      return Duration.zero; // Placeholder, gerçek position için listener kullanılacak
                                    })
                                  : Stream.value(Duration.zero),
                              builder: (context, snapshot) {
                                return SizedBox(
                                  height: 30.h,
                                  width: double.infinity, // Expanded içinde genişliği sınırla
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min, // Overflow'u önlemek için
                                    children: List.generate(
                                      15, // 20'den 15'e düşürüldü overflow'u önlemek için
                                      (index) {
                                        // Oynatma sırasında rastgele animasyon (gerçek ses verisi için API'den waveform data gerekli)
                                        final random = (index * 7 + DateTime.now().millisecondsSinceEpoch) % 10;
                                        return Flexible(
                                          child: AnimatedContainer(
                                            duration: Duration(milliseconds: 100),
                                            width: 2.5.w, // 3.w'den 2.5.w'ye düşürüldü
                                            height: _isPlaying 
                                                ? (index % 3 == 0 ? 20.h + random : (index % 2 == 0 ? 12.h + (random ~/ 2) : 8.h + (random ~/ 3)))
                                                : (index % 3 == 0 ? 20.h : (index % 2 == 0 ? 12.h : 8.h)),
                                            decoration: BoxDecoration(
                                              color: isMe ? Colors.white70 : Colors.black54,
                                              borderRadius: BorderRadius.circular(2.w),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 4.h),
                            // Süre - sadece mesaj uzunluğu
                            Text(
                              _duration != Duration.zero
                                  ? _formatDuration(_duration)
                                  : '--:--',
                              style: GoogleFonts.quicksand(
                                fontSize: 11.w,
                                fontWeight: FontWeight.w500,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                // Mesaj metni
                if (widget.message.message.isNotEmpty && !hasVoice) ...[
                  if (hasImage) SizedBox(height: 8.h),
                  Text(
                    widget.message.message,
                    style: GoogleFonts.quicksand(
                      fontSize: 14.w,
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

