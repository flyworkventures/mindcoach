import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/locale_font_scaler.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/utils/time_format_utils.dart';
import 'package:mindcoach/Riverpod/Controllers/general_assistant_view_controller.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';

// Stil bilgileri için kullanılan sabitler
const Color _kAppbarGreen = Color(0xFF11998E);
const Color _kAppbarLightGreen = Color(0xFF38EF7D);
const Color _kGreetingStart = Color(0xFF2BD383);
const Color _kGreetingEnd = Color(0xFF11998E);
const Color _kInputShadow = Color(0x40000000);

class GeneralAssistantView extends ConsumerStatefulWidget {
  const GeneralAssistantView({super.key});

  @override
  ConsumerState<GeneralAssistantView> createState() => _GeneralAssistantViewState();
}


class _GeneralAssistantViewState extends ConsumerState<GeneralAssistantView> {
  final TextEditingController _messageController = TextEditingController();
  bool _isMenuOpen = false;
  String? _lastProcessedImagePath;
  bool _isSendingImage = false;
  Timer? _recordingTimer;
  RecorderController? _recorderController;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..sampleRate = 44100
      ..bitRate = 128000;
    
    Future.microtask(() async {
      if (!mounted) return;
      try {
        ref.read(generalAssistantViewControllerProvider.notifier).clearSelectedImage();
        _lastProcessedImagePath = null;
      } catch (e) {
        debugPrint("❌ GeneralAssistantView initState hatası: $e");
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recordingTimer?.cancel();
    _recorderController?.dispose();
    
    // Mesajları temizle (ekrandan çıkınca)
    if (mounted) {
      try {
        ref.read(generalAssistantViewControllerProvider.notifier).clearMessages();
        ref.read(generalAssistantViewControllerProvider.notifier).cleanup();
      } catch (e) {
        debugPrint("⚠️ dispose sırasında ref kullanılamadı: $e");
      }
    }
    super.dispose();
  }

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
    if (_isMenuOpen) {
      ref.read(generalAssistantViewControllerProvider.notifier).clearSelectedImage();
      _lastProcessedImagePath = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(generalAssistantViewControllerProvider).messages;
    final selectedImage = ref.watch(generalAssistantViewControllerProvider.select((state) => state.selectedImage));
    final isRecording = ref.watch(generalAssistantViewControllerProvider.select((state) => state.isRecording));
    
    // Kayıt süresini güncelle
    if (isRecording && _recordingTimer == null) {
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          final now = DateTime.now();
          final startTime = ref.read(generalAssistantViewControllerProvider).recordingDuration;
          ref.read(generalAssistantViewControllerProvider.notifier).updateRecordingDuration(
            Duration(seconds: now.difference(DateTime.now().subtract(startTime)).inSeconds),
          );
        } else {
          _recordingTimer?.cancel();
          _recordingTimer = null;
        }
      });
    } else if (!isRecording && _recordingTimer != null) {
      _recordingTimer?.cancel();
      _recordingTimer = null;
    }

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
                  
                  if (messages.isEmpty) ...[
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
                        child: Center(child: _buildGreetingContent()),
                      ),
                    ),
                  ],
                  
                  if (messages.isNotEmpty) ...[
                    Expanded(
                      child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        reverse: true,
                        itemCount: messages.length,
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                        itemBuilder: (context, index) {
                          final m = messages[index];
                          return _MessageBubble(message: m);
                        },
                      ),
                    ),
                  ],
                  
                  _buildInputArea(selectedImage),
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
                'General Assistant',
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
              child: Container(
                width: 38.w,
                height: 38.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      ref.read(AllProviders.userProvider)?.profilePhotoUrl ?? AppConstants.defaultPpUrl,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingContent() {
    return Center(
      child: Text(
        'Merhaba! Size nasıl yardımcı olabilirim?',
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

  Widget _buildInputArea(XFile? selectedImage) {
    final hasText = _messageController.text.trim().isNotEmpty;
    final hasImage = selectedImage != null;
    final isRecording = ref.watch(generalAssistantViewControllerProvider.select((state) => state.isRecording));
    final recordingDuration = ref.watch(generalAssistantViewControllerProvider.select((state) => state.recordingDuration));
    final canSend = hasText || hasImage;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRecording)
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
              width: 339.w,
              constraints: BoxConstraints(maxHeight: 100.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                boxShadow: const [BoxShadow(color: _kInputShadow, offset: Offset(0, 2), blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
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
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
                            waveStyle: const WaveStyle(
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
                          if (mounted) {
                            await ref.read(generalAssistantViewControllerProvider.notifier).cancelRecording();
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
          
          if (hasImage && !isRecording)
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
              width: 339.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40.w),
                boxShadow: const [BoxShadow(color: _kInputShadow, offset: Offset(0, 2), blurRadius: 4)],
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
                        File(selectedImage.path),
                            width: 50.w,
                            height: 50.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(context.l10n.image, maxLines: 1, style: GoogleFonts.poppins()),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(generalAssistantViewControllerProvider.notifier).clearSelectedImage();
                      setState(() {
                        _lastProcessedImagePath = null;
                      });
                    },
                    icon: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: Icon(Icons.close, color: Colors.white, size: 16.w),
                    ),
                  ),
                ],
              ),
            ),
          
          Container(
            width: 339.w,
            constraints: BoxConstraints(maxHeight: 80.h),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.w),
              boxShadow: const [BoxShadow(color: _kInputShadow, offset: Offset(0, 2), blurRadius: 4)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.quicksand(fontSize: 14.w),
                      decoration: InputDecoration(
                        hintText: context.l10n.typeAMessage,
                        hintStyle: GoogleFonts.quicksand(
                          fontSize: 12.w,
                          fontWeight: FontWeight.w500,
                          height: 18.h / 12.w,
                          color: Colors.black,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (text) => setState(() {}),
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
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _toggleMenu,
                      icon: SvgPicture.asset(
                        'assets/svg/add_icon.svg',
                        width: 18.w,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (!isRecording) {
                                await _startRecording();
                              }
                            },
                            onLongPressStart: (details) async {
                              if (!isRecording) {
                                await _startRecording();
                              }
                            },
                            onLongPressEnd: (details) async {
                              if (isRecording && _recorderController != null) {
                                await _stopAndSendRecording();
                              }
                            },
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: null,
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
                          if (canSend || isRecording)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _isSendingImage
                                  ? null
                                  : (isRecording ? _sendVoiceMessageFromRecording : _sendMessage),
                              icon: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2BD383),
                                  shape: BoxShape.circle,
                                ),
                                child: _isSendingImage
                                    ? SizedBox(
                                        width: 16.w,
                                        height: 16.h,
                                        child: const CircularProgressIndicator(
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

  Widget _buildAttachmentMenu(BuildContext context) {
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
              'Kamera',
              'assets/svg/camera_icon.svg',
              () async {
                _toggleMenu();
                await ref.read(generalAssistantViewControllerProvider.notifier).pickImage();
              },
            ),
            _buildMenuItem(
              'Galeri',
              'assets/svg/gallery_icon.svg',
              () async {
                _toggleMenu();
                await ref.read(generalAssistantViewControllerProvider.notifier).pickImage();
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

  Future<void> _sendMessage() async {
    final hasText = _messageController.text.trim().isNotEmpty;
    final selectedImage = ref.watch(generalAssistantViewControllerProvider.select((state) => state.selectedImage));
    final hasImage = selectedImage != null;
      
    if (!hasText && !hasImage) return;

    try {
      if (hasImage) {
        final image = ref.watch(generalAssistantViewControllerProvider.select((state) => state.selectedImage));
        if (image != null) {
          await _handleImageSelected(image);
        }
      } else if (hasText) {
        final trimmed = _messageController.text.trim();
        if (trimmed.isEmpty) return;

        await ref.read(generalAssistantViewControllerProvider.notifier).sendMessage(
              message: trimmed,
            );

        _messageController.clear();
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorMessageFailed),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    if (_recorderController == null) {
      _recorderController = RecorderController()
        ..androidEncoder = AndroidEncoder.aac
        ..androidOutputFormat = AndroidOutputFormat.mpeg4
        ..sampleRate = 44100
        ..bitRate = 128000;
    }

    final isRecording = ref.read(generalAssistantViewControllerProvider).isRecording;
    if (!isRecording && _recorderController != null) {
      try {
        final path = (await getTemporaryDirectory()).path +
            '/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await ref.read(generalAssistantViewControllerProvider.notifier).startRecording();
        await _recorderController!.record(path: path);
      } catch (e) {
        await ref.read(generalAssistantViewControllerProvider.notifier).cancelRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.errorRecordingStart),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _stopAndSendRecording() async {
    final isRecording = ref.read(generalAssistantViewControllerProvider).isRecording;
    if (isRecording && _recorderController != null) {
      try {
        final path = await _recorderController!.stop();
        if (path != null && path.isNotEmpty) {
          final file = File(path);
          if (await file.exists() && mounted) {
            await _sendVoiceMessage(path);
          }
        }
        await ref.read(generalAssistantViewControllerProvider.notifier).stopRecording();
      } catch (e) {
        await ref.read(generalAssistantViewControllerProvider.notifier).cancelRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.errorRecordingStop),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendVoiceMessageFromRecording() async {
    if (ref.read(generalAssistantViewControllerProvider).isRecording) {
      await _stopAndSendRecording();
    }
  }

  Future<void> _sendVoiceMessage(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.errorVoiceFileNotFound),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await ref.read(generalAssistantViewControllerProvider.notifier).sendMessage(
            audioFile: file,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorVoiceMessageFailed),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleImageSelected(XFile image) async {
    if (image.path == _lastProcessedImagePath || _isSendingImage) {
      return;
    }

    setState(() {
      _lastProcessedImagePath = image.path;
      _isSendingImage = true;
    });

    if (!mounted) return;

    try {
      final file = File(image.path);
      final messageText = _messageController.text.trim();

      await ref.read(generalAssistantViewControllerProvider.notifier).sendMessage(
            imageFile: file,
            message: messageText.isNotEmpty ? messageText : null,
          );

      _messageController.clear();
      ref.read(generalAssistantViewControllerProvider.notifier).clearSelectedImage();

      if (mounted) {
        setState(() {
          _lastProcessedImagePath = null;
          _isSendingImage = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorImageFailed),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingImage = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({required this.message});
  final GeneralAssistantMessage message;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool showContent = false;

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isFromMe;
    final hasImage = widget.message.imageUrl != null && widget.message.imageUrl!.isNotEmpty;
    final hasVoice = widget.message.audioUrl != null && widget.message.audioUrl!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
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
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.w),
                    child: Image.file(
                      File(widget.message.imageUrl!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150.h,
                          color: Colors.grey[300],
                          child: Icon(Icons.broken_image, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                if (hasVoice) ...[
                  if (hasImage) SizedBox(height: 8.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, color: isMe ? Colors.white : Colors.black87, size: 24.w),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '[Sesli Mesaj]',
                              style: GoogleFonts.quicksand(
                                fontSize: 11.w,
                                fontWeight: FontWeight.w500,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox.shrink(),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      showContent = !showContent;
                                    });
                                  },
                                  child: Text(
                                    "Metne çevir",
                                    style: GoogleFonts.quicksand(
                                      fontSize: 11.w,
                                      fontWeight: FontWeight.w500,
                                      color: isMe ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (showContent) ...[
                    SizedBox(height: 8.h),
                    Text(
                      widget.message.voiceMessageContent ?? "Anlaşılmadı",
                      style: GoogleFonts.quicksand(
                        fontSize: 14.w,
                        fontWeight: FontWeight.w600,
                        color: isMe ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
                if (widget.message.text.isNotEmpty && !hasVoice) ...[
                  if (hasImage) SizedBox(height: 8.h),
                  Text(
                    widget.message.text,
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
        // Mesaj saati - bubble'ın altında
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            TimeFormatUtils.formatTime(context, widget.message.createdAt),
            style: GoogleFonts.quicksand(
              fontSize: 10.w,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}
