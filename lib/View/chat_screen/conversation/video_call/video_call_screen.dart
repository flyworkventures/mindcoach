import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/View/chat_screen/notifiers/conversation_notifier.dart';
import 'package:mindcoach/core/repo/stream_call_repo.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:developer';
import 'dart:io';

import '../../../../core/utils/screen_size_extensions.dart';


const Color _kAppbarGreen = Color(0xFF11998E);
const Color _kLiveText = Color(0xFF111111); // Live yazısı rengi

class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({super.key});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}



class _ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
  });
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  Flutter3DController controller = Flutter3DController();
  AudioRecorder? _audioRecorder;
  StreamCallRepo? _streamCallRepo;
  AudioPlayer? _audioPlayer;
  bool _isRecording = false;
  String? _recordingPath;
  String _status = 'Hazır';
  List<String> _availableAnimations = [];
  bool _isGlowing = false;
  DateTime? _recordingStartTime;
  bool _isPlayingAIResponse = false; 
  List<_ChatMessage> _chatMessages = []; 

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadAnimations();
  }


  Future<void> _initializeServices() async {
    _streamCallRepo = StreamCallRepo(ref);
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    

    _audioPlayer!.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {

        _stopHeadActionAnimation();
        if (mounted) {
          setState(() {
            _isPlayingAIResponse = false;
            _status = 'Hazır';
          });
        }
        log('✅ [VIDEO-CALL] AI sesi bitti, animasyon durduruldu');
      }
    });
    

    if (await _audioRecorder!.hasPermission()) {
      log("✅ Mikrofon izni var");
      setState(() {
        _status = 'Hazır';
      });
    } else {
      setState(() {
        _status = 'Mikrofon izni gerekli';
      });
    }
  }


  Future<void> _loadAnimations() async {
    try {
      final animations = await controller.getAvailableAnimations();
      setState(() {
        _availableAnimations = animations;
      });

    } catch (e) {

    }
  }



  Future<void> _startRecording() async {
    if (_isRecording || _audioRecorder == null) return;

    try {

      if (!await _audioRecorder!.hasPermission()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon izni gerekli')),
        );
        return;
      }


      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${tempDir.path}/stream_call_$timestamp.m4a';


      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100, 
          numChannels: 1,
          bitRate: 128000, 
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _isGlowing = true;
        _status = 'Kayıt alınıyor...';
        _recordingStartTime = DateTime.now();
      });

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt başlatılamadı: $e')),
      );
    }
  }


  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording || _audioRecorder == null || _recordingPath == null) return;

    try {

      final path = await _audioRecorder!.stop();
      final actualPath = path ?? _recordingPath!;

      setState(() {
        _isRecording = false;
        _isGlowing = false;
        _status = 'Gönderiliyor...';
      });




      final file = File(actualPath);
      if (!await file.exists()) {
        throw Exception('Kayıt dosyası bulunamadı');
      }


      if (_recordingStartTime != null) {
        final recordingDuration = DateTime.now().difference(_recordingStartTime!);
        const minDuration = Duration(milliseconds: 500); 
        
        if (recordingDuration < minDuration) {
       
          setState(() {
            _status = 'Kayıt çok kısa';
            _isRecording = false;
            _isGlowing = false;
            _recordingStartTime = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt çok kısa, lütfen daha uzun kayıt yapın')),
          );

          try {
            await file.delete();
          } catch (e) {
            log('⚠️ Dosya silinemedi: $e');
          }
          return;
        }
      }


      _recordingStartTime = null;


      final conversationsState = ref.read(conversationsProvider);
      final consultant = conversationsState.consultantModel;
      
      if (consultant == null) {
        throw Exception('Consultant bulunamadı');
      }


      final response = await _streamCallRepo!.sendStreamCallAudio(
        consultantId: consultant.id,
        audioFile: file,
      );

      if (response != null && response['success'] == true) {

        

        final transcribedText = response['transcribedText'] as String?;
        if (transcribedText != null && transcribedText.isNotEmpty) {
          if (mounted) {
            setState(() {
              _chatMessages.add(_ChatMessage(
                text: transcribedText,
                isFromUser: true,
                timestamp: DateTime.now(),
              ));
            });
          }
        }
        

        final aiVoiceURL = response['aiVoiceURL'] as String?;
        final audioContent = response['audioContent'] as String?;
        
        log(' aiVoiceURL: $aiVoiceURL');
        log(' audioContent: ${audioContent != null ? audioContent.substring(0, 50) : null}...');
        

        if (audioContent != null && audioContent.isNotEmpty) {
          if (mounted) {
            setState(() {
              _chatMessages.add(_ChatMessage(
                text: audioContent,
                isFromUser: false,
                timestamp: DateTime.now(),
              ));
            });
          }
        }
        
        if (aiVoiceURL != null && aiVoiceURL.isNotEmpty) {

          await _playAIResponse(aiVoiceURL);
        } else {
          log('⚠️ [VIDEO-CALL] aiVoiceURL boş veya null');
          if (mounted) {
            setState(() {
              _status = 'Yanıt bekleniyor...';
            });
          }
        }

        try {
          await file.delete();
        } catch (e) {
          log('⚠️ Dosya silinemedi: $e');
        }
      } else {
        log('❌ [VIDEO-CALL] Response null veya success false');
        throw Exception('Audio gönderilemedi: ${response?['error'] ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      log('❌ [STREAM-CALL] Gönderme hatası: $e');
      setState(() {
        _status = 'Hata: $e';
        _isRecording = false;
        _isGlowing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }


  Future<void> _playAIResponse(String aiVoiceURL) async {
    if (_audioPlayer == null) {
      return;
    }
    
    try {
      if (!mounted) return;
      
      setState(() {
        _isPlayingAIResponse = true;
        _status = 'AI konuşuyor...';
      });
      

      _startHeadActionAnimation();
      

      await _audioPlayer!.setUrl(aiVoiceURL);
      await _audioPlayer!.play();
      

    } catch (e, stackTrace) {
      log(' AI sesi oynatma hatası: $e');
      log(' Stack trace: $stackTrace');
      _stopHeadActionAnimation();
      if (mounted) {
        setState(() {
          _isPlayingAIResponse = false;
          _status = 'Ses oynatılamadı: $e';
        });
      }
    }
  }


  void _startHeadActionAnimation() {
    try {

      final headActionAnimation = _availableAnimations.firstWhere(
        (anim) => anim.toLowerCase().contains('headaction') || 
                  anim.toLowerCase().contains('head_action'),
        orElse: () => _availableAnimations.isNotEmpty ? _availableAnimations.first : '',
      );
      
      if (headActionAnimation.isNotEmpty) {
        controller.playAnimation(animationName: headActionAnimation);
      } else {

        if (_availableAnimations.isNotEmpty) {
          controller.playAnimation(animationName: _availableAnimations.first);
        }
      }
    } catch (e) {

    }
  }


  void _stopHeadActionAnimation() {
    try {
      controller.pauseAnimation();
    
    } catch (e) {
     
    }
  }

  @override
  void dispose() {
   
    _audioRecorder?.dispose();
    _audioPlayer?.dispose();
    _audioPlayer?.stop();
    _stopHeadActionAnimation(); 
    _chatMessages.clear();
    _isRecording = false;
    _isGlowing = false;
    _isPlayingAIResponse = false;
    _status = 'Hazır';
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBFCFF),
              Color(0xFFF9FAFF), 
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              _buildLiveHeader(context),
       
              Expanded(child: _buildVideoCard(context)),

              _buildMicrophoneButton(context),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLiveHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pop(context);
              },
              icon: SvgPicture.asset(
                  'assets/svg/arrow_back.svg',
                  width: 12.w,
                  colorFilter: const ColorFilter.mode(_kLiveText, BlendMode.srcIn)
              ),
            ),
          ),

        
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
         
                SvgPicture.asset(
                    'assets/svg/video_call.svg',
                    width: 22.w,
                    colorFilter: const ColorFilter.mode(_kLiveText, BlendMode.srcIn)
                ),
                SizedBox(width: 6.w),
                // Live Yazısı
                Text(
                  'Live',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 20.w,
                    fontWeight: FontWeight.w500, 
                    letterSpacing: -0.3,
                    height: 1.0, 
                    color: _kLiveText,
                  ),
                ),
              ],
            ),
          ),


          SizedBox(width: 48.w), 
        ],
      ),
    );
  }


  Widget _buildVideoCard(BuildContext context) {
    final conversationsState = ref.watch(conversationsProvider);
    final consultantModel = conversationsState.consultantModel;
    final threeDFile = conversationsState.threeD;
    
    if (consultantModel == null) {
      return Center(
        child: Text(
          'Consultant bulunamadı',
          style: GoogleFonts.quicksand(fontSize: 16.w),
        ),
      );
    }

    if (threeDFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text(
              '3D model yükleniyor...',
              style: GoogleFonts.quicksand(fontSize: 16.w),
            ),
          ],
        ),
      );
    }

   
    const double cardRadius = 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 27.w),
      child: Container(
        width: 339.w,
        
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0x40000000), // #00000040
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius.w),
          child: Stack(
            fit: StackFit.expand,
            children: [
          
              Align(
                alignment: Alignment.topCenter,
                child: ClipRRect(
                  
                  child: Align(
                        alignment: Alignment.topCenter,
                  heightFactor: 0.30, 
                    child: Container(
                      color: Colors.greenAccent,
                      height: 900.h,
                      child: Flutter3DViewer(
                      
                        onLoad: (modelAddress) {
                        
                          _loadAnimations();
                        },
                        controller: controller,
                        src: threeDFile.path,
                      ),
                    ),
                  ),
                ),
              ),
      
        /*      Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(43, 211, 131, 0), // rgba(43, 211, 131, 0)
                        _kAppbarGreen, // #11998E
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ), */
              
          
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 300.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.95),
                        Colors.white,
                      ],
                      stops: [0.0, 0.3, 1.0],
                    ),
                  ),
                  child: _chatMessages.isEmpty
                      ? SizedBox.shrink()
                      : ListView.builder(
                          reverse: true,
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          itemCount: _chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = _chatMessages[_chatMessages.length - 1 - index];
                            return _ChatBubble(
                              message: message,
                            );
                          },
                        ),
                ),
              ),
              
             
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 300.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.95),
                        Colors.white,
                      ],
                      stops: [0.0, 0.3, 1.0],
                    ),
                  ),
                  child: _chatMessages.isEmpty
                      ? SizedBox.shrink()
                      : ListView.builder(
                          reverse: true,
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          itemCount: _chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = _chatMessages[_chatMessages.length - 1 - index];
                            return _ChatBubble(
                              message: message,
                            );
                          },
                        ),
                ),
              ),
              
        
              if (_status.isNotEmpty && _status != 'Hazır')
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  right: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Text(
                      _status,
                      style: GoogleFonts.quicksand(
                        fontSize: 12.w,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        _startRecording();
      },
      onLongPressEnd: (_) {
        _stopRecordingAndSend();
      },
      onTap: () {
        if (_isRecording) {
          _stopRecordingAndSend();
        } else {
          _startRecording();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isGlowing ? 120.w : 100.w,
        height: _isGlowing ? 120.h : 100.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording ? Colors.red : const Color(0xFF2BD383),
          boxShadow: _isGlowing
              ? [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : const Color(0xFF2BD383))
                        .withValues(alpha: 0.6),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: (_isRecording ? Colors.red : const Color(0xFF2BD383))
                        .withValues(alpha: 0.4),
                    blurRadius: 50,
                    spreadRadius: 20,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Icon(
          _isRecording ? Icons.mic : Icons.mic_none,
          size: 50.w,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 250.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF2BD383).withOpacity(0.12)
                  : const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(
                color: isUser
                    ? const Color(0xFF2BD383).withOpacity(0.35)
                    : const Color(0xFFE2E2E2),
                width: 1,
              ),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.quicksand(
                fontSize: 13.w,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

