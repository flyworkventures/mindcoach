import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart' as audio_players;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/Analytics/analytics_service.dart';
import 'package:mindcoach/core/analytics/analytics_events.dart';
import 'package:mindcoach/Services/TrialQuotaService/trial_quota_service.dart';
import 'package:mindcoach/Services/rive_preload_service.dart';
import 'package:mindcoach/View/chat_screen/chat_notifier.dart';
import 'package:mindcoach/View/appointments/appointments_notifier.dart';
import 'package:mindcoach/View/specialists_screen/specialist_detail_screen.dart';
import 'package:mindcoach/core/locale/locale_provider.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/routes/video_call_route_args.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/revenuecat_paywalls.dart';
import 'package:mindcoach/models/consultant_model.dart';
import 'package:mindcoach/models/message_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';

import '../notifiers/conversation_notifier.dart';

// Global AudioPlayer controller - aynı anda sadece bir ses oynatılabilir
final _globalAudioPlayer = audio_players.AudioPlayer();
String? _currentlyPlayingMessageId;

class ConversationScreen extends ConsumerStatefulWidget {
  final ConsultantModel specialistId;

  /// Bu ekran bir SpecialistDetailScreen üzerinden açıldıysa true olur.
  /// AppBar'daki avatar/isim alanına basıldığında yeni bir detay sayfası
  /// push'lamak yerine geri pop ederek loop'u engelleriz.
  final bool fromDetail;

  const ConversationScreen({
    super.key,
    required this.specialistId,
    this.fromDetail = false,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isMenuOpen = false;
  String? _lastProcessedImagePath;
  bool _isSendingImage = false;
  Timer? _recordingTimer;
  Timer? _replyPollTimer;
  RecorderController? _recorderController;

  /// WhatsApp tarzı ses kaydı: basılı tut / yukarı kilitle / sola iptal
  bool _isRecordingLocked = false;
  bool _isHoldRecording = false;
  double _recordSlideDx = 0;
  double _recordSlideDy = 0;
  static const double _lockThreshold = -56;
  static const double _cancelThreshold = -72;

  static const WaveStyle _recordingWaveStyle = WaveStyle(
    waveColor: Color(0xFFE53935),
    extendWaveform: true,
    showMiddleLine: false,
    showTop: true,
    showBottom: true,
    spacing: 5,
    waveThickness: 3,
    scaleFactor: 90,
    waveCap: StrokeCap.round,
  );

  static const WaveStyle _lockedRecordingWaveStyle = WaveStyle(
    waveColor: Color(0xFF21BC87),
    extendWaveform: true,
    showMiddleLine: false,
    showTop: true,
    showBottom: true,
    spacing: 5,
    waveThickness: 3,
    scaleFactor: 90,
    waveCap: StrokeCap.round,
  );

  RecorderController _createRecorderController() {
    return RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..sampleRate = 44100
      ..bitRate = 128000
      ..updateFrequency = const Duration(milliseconds: 50);
  }

  @override
  void initState() {
    super.initState();

    _recorderController = _createRecorderController();

    // Görüntülü arama için Rive dosyasını arka planda ön yükle (normalize edilmiş URL ile cache anahtarı tek).
    RivePreloadService.instance.preload(widget.specialistId.url3d);

    Future.microtask(() async {
      if (!mounted) return;
      AnalyticsService.instance.capture(
        AnalyticsEvents.conversationOpened,
        properties: {'consultant_id': widget.specialistId.id},
      );
      try {
        // Önce eski konuşma mesajlarını temizle (A→B geçişinde yanlış mesaj görünmesin)
        ref
            .read(conversationsProvider.notifier)
            .clearMessages(widget.specialistId.id);
        ref.read(conversationsProvider.notifier).clearSelectedImage();
        _lastProcessedImagePath = null;
        if (mounted) {
          await ref
              .read(conversationsProvider.notifier)
              .getMessages(widget.specialistId.id);
        }
      } catch (e) {
        debugPrint(" ConversationPage initState hatası: $e");
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recordingTimer?.cancel();
    _replyPollTimer?.cancel();
    _recorderController?.dispose();

    if (mounted) {
      try {
        final isRecording = ref.read(conversationsProvider).isRecording;
        if (isRecording) {
          ref.read(conversationsProvider.notifier).cancelRecording();
        }
      } catch (e) {
        debugPrint("⚠️ dispose sırasında ref kullanılamadı (normal): $e");
      }
    }
    super.dispose();
  }

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);

    if (_isMenuOpen) {
      ref.read(conversationsProvider.notifier).clearSelectedImage();
      _lastProcessedImagePath = null;
    }
  }

  String _coachName() {
    final langCode = ref.read(localeProvider.notifier).getLanguageCode();
    final names = widget.specialistId.names;
    return names[langCode] as String? ??
        names['en'] as String? ??
        names.values.first.toString();
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(conversationsProvider);
    final List<MessageModel> allMessages = conversationState.messages;
    final bool isLoadingMessages = conversationState.isLoadingMessages;
    final bool hasExistingChatThread = ref.watch(
      chatProvider.select(
        (chatState) => chatState.chats.any(
          (chat) => chat.consultantId == widget.specialistId.id,
        ),
      ),
    );

    final selectedImage = ref.watch(
      conversationsProvider.select((state) => state.selectedImage),
    );
    final isRecording = ref.watch(
      conversationsProvider.select((state) => state.isRecording),
    );

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

    if (selectedImage == null && _lastProcessedImagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _lastProcessedImagePath = null;
          });
        }
      });
    }

    final List<MessageModel> messages = List.from(allMessages)
      ..sort((a, b) {
        final dateA = _parseSentTime(a.sentTime);
        final dateB = _parseSentTime(b.sentTime);
        return dateB.compareTo(dateA);
      });

    final isWaiting = messages.isNotEmpty && messages.first.sender == 'user';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(context),
                const Divider(height: 1, color: Color(0xFF96989C)),
                // ── Messages ──
                Expanded(
                  child:
                      (isLoadingMessages &&
                          messages.isEmpty &&
                          hasExistingChatThread)
                      ? const _ConversationShimmer()
                      : ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          reverse: true,
                          itemCount: messages.length + (isWaiting ? 1 : 0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemBuilder: (context, index) {
                            if (isWaiting && index == 0) {
                              return _TypingIndicator(
                                photoURL: widget.specialistId.photoURL,
                              );
                            }
                            final msgIndex = isWaiting ? index - 1 : index;
                            final m = messages[msgIndex];
                            return _MessageBubble(
                              message: m,
                              coachPhotoURL: widget.specialistId.photoURL,
                            );
                          },
                        ),
                ),

                // ── Input Area ──
                _buildInputArea(selectedImage, isRecording),
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
    );
  }

  // ── App Bar ──
  Widget _buildAppBar(BuildContext context) {
    final l = context.l10n;
    final name = _coachName();
    final photoURL = widget.specialistId.photoURL;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SvgPicture.asset('assets/icons/ic_bakc.svg'),
          ),
          const SizedBox(width: 12),

          // Avatar + Name area — tıklanınca SpecialistDetailScreen açılır.
          // Geri, sesli, görüntülü butonları bu alanın dışında kaldığı için
          // kendi tap target'ları korunur.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Bu ConversationScreen detaydan açıldıysa loop'u engellemek
                // için yeni detay push'lamak yerine geri pop ederiz.
                if (widget.fromDetail) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(
                      name: PageRoutes.specialistDetail,
                    ),
                    builder: (_) => SpecialistDetailScreen(
                      specialist: widget.specialistId,
                      fromConversation: true,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  // Coach avatar — circular, green border
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF21BC87),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: photoURL.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: photoURL,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const SizedBox.shrink(),
                              errorWidget: (_, _, _) => Image.asset(
                                'assets/images/profile_avatar.jpeg',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/profile_avatar.jpeg',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name + Online
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 20 / 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF2BD383),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              height: 4,
                              width: 4,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l.online,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                height: 16 / 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Video call (PREMIUM ONLY)
          Consumer(
            builder: (context, ref, _) {
              return GestureDetector(
                onTap: () async {
                  final isPremium = ref
                      .watch(AllProviders.premiumProvider)
                      .isPremium;
                  if (!isPremium) {
                    final isGuest =
                        (ref.read(AllProviders.userProvider)?.credential ?? '')
                            .toLowerCase() ==
                        'guest';
                    await presentPaywallForUser(context, isGuest: isGuest);
                  } else {
                    unawaited(_openVideoCall());
                  }
                },
                child: SvgPicture.asset('assets/icons/ic_video.svg'),
              );
            },
          ),
          const SizedBox(width: 16),

          // Phone call (PREMIUM ONLY)
          Consumer(
            builder: (context, ref, _) {
              return GestureDetector(
                onTap: () async {
                  final isPremium = ref
                      .watch(AllProviders.premiumProvider)
                      .isPremium;
                  if (!isPremium) {
                    final isGuest =
                        (ref.read(AllProviders.userProvider)?.credential ?? '')
                            .toLowerCase() ==
                        'guest';
                    await presentPaywallForUser(context, isGuest: isGuest);
                  } else {
                    Navigator.pushNamed(
                      context,
                      PageRoutes.voiceCallView,
                      arguments: widget.specialistId,
                    );
                  }
                },
                child: SvgPicture.asset('assets/icons/ic_call.svg'),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Input Area ──
  Widget _buildInputArea(XFile? selectedImage, bool isRecording) {
    final l = context.l10n;
    final hasText = _messageController.text.trim().isNotEmpty;
    final hasImage = ref.watch(conversationsProvider).selectedImage != null;
    final recordingDuration = ref.watch(
      conversationsProvider.select((state) => state.recordingDuration),
    );
    final isRecordingPaused = ref.watch(
      conversationsProvider.select((state) => state.isRecordingPaused),
    );
    final canSend = hasText || hasImage;

    const primaryGreen = Color(0xFF21BC87);
    final borderColor = Colors.black.withOpacity(0.05);
    final showLockedBar = isRecording && _isRecordingLocked;
    // Hold UI hemen görünsün — kayıt async başlasa bile
    final showHoldHint = _isHoldRecording && !_isRecordingLocked;
    final willCancel = _recordSlideDx <= _cancelThreshold;
    final willLock = _recordSlideDy <= _lockThreshold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Kilitli kayıt çubuğu (WhatsApp lock mode) ──
          if (showLockedBar)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F8),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  // Sil
                  GestureDetector(
                    onTap: () => _cancelVoiceRecording(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/trashIcon.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFE53935),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Kırmızı nokta + süre
                  _PulsingRecordDot(
                    active: !isRecordingPaused,
                    paused: isRecordingPaused,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(recordingDuration),
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_recorderController != null)
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: Opacity(
                          opacity: isRecordingPaused ? 0.35 : 1,
                          child: AudioWaveforms(
                            size: const Size(double.infinity, 36),
                            recorderController: _recorderController!,
                            waveStyle: _lockedRecordingWaveStyle,
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 4),
                  // Duraklat / Devam
                  GestureDetector(
                    onTap: () => _toggleRecordingPause(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F8F1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRecordingPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: primaryGreen,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Gönder
                  GestureDetector(
                    onTap: () => _sendVoiceMessageFromRecording(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/ic_send.svg',
                          width: 20,
                          height: 20,
                          fit: BoxFit.scaleDown,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Basılı tutarken kayıt çubuğu (anında görünür) ──
          if (showHoldHint)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: willCancel
                    ? const Color(0xFFFFEBEB)
                    : const Color(0xFFFFF4F4),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: willCancel
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFFFFD7D7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PulsingRecordDot(active: isRecording && !willCancel),
                      const SizedBox(width: 10),
                      Text(
                        isRecording
                            ? _formatDuration(recordingDuration)
                            : '00:00',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: willCancel
                              ? const Color(0xFFE53935)
                              : const Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          willCancel
                              ? 'Bırak, silinsin'
                              : willLock
                                  ? 'Bırak, kilitlensin'
                                  : (isRecording
                                      ? 'Kayıt yapılıyor'
                                      : 'Başlatılıyor…'),
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: willCancel
                                ? const Color(0xFFE53935)
                                : const Color(0xFF101828),
                          ),
                        ),
                      ),
                      Icon(
                        willLock
                            ? Icons.lock_outline
                            : Icons.lock_open_outlined,
                        size: 18,
                        color: willLock
                            ? primaryGreen
                            : const Color(0xFF96989C),
                      ),
                    ],
                  ),
                  if (_recorderController != null && !willCancel) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: Opacity(
                        opacity: isRecording ? 1 : 0.35,
                        child: AudioWaveforms(
                          size: const Size(double.infinity, 40),
                          recorderController: _recorderController!,
                          waveStyle: _recordingWaveStyle,
                        ),
                      ),
                    ),
                  ],
                  if (!willCancel && !willLock) ...[
                    const SizedBox(height: 6),
                    const Text(
                      '← Sil   ·   ↑ Kilitle   ·   Bırak = Gönder',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Image preview
          if (hasImage && !isRecording)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    child: Image.file(
                      File(
                        ref.watch(conversationsProvider).selectedImage!.path,
                      ),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.image,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      ref
                          .read(conversationsProvider.notifier)
                          .clearSelectedImage();
                      setState(() {
                        _lastProcessedImagePath = null;
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

          // Main input row — kilitli kayıtta gizli (üstte bar var)
          if (!showLockedBar)
            Row(
              children: [
                if (!showHoldHint)
                  GestureDetector(
                    onTap: _toggleMenu,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: primaryGreen,
                        size: 28,
                      ),
                    ),
                  ),
                if (!showHoldHint) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    padding: const EdgeInsets.only(left: 16, top: 3, bottom: 3),
                    child: Row(
                      children: [
                        if (!showHoldHint)
                          Expanded(
                            child: TextField(
                              cursorColor: primaryGreen,
                              controller: _messageController,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: l.typeAMessage,
                                hintStyle: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) {
                                if (canSend) _sendMessage();
                              },
                            ),
                          )
                        else
                          const Expanded(child: SizedBox.shrink()),
                        const SizedBox(width: 8),
                        // Mic / Send — kısa basılı tut (~200ms) + kaydır
                        RawGestureDetector(
                          behavior: HitTestBehavior.opaque,
                          gestures: <Type, GestureRecognizerFactory>{
                            TapGestureRecognizer:
                                GestureRecognizerFactoryWithHandlers<
                                    TapGestureRecognizer>(
                              () => TapGestureRecognizer(),
                              (TapGestureRecognizer instance) {
                                instance.onTap = () async {
                                  if (_isSendingImage) return;
                                  if (canSend) {
                                    _sendMessage();
                                    return;
                                  }
                                  HapticFeedback.selectionClick();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Sesli mesaj için mikrofonu basılı tut',
                                      ),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                };
                              },
                            ),
                            LongPressGestureRecognizer:
                                GestureRecognizerFactoryWithHandlers<
                                    LongPressGestureRecognizer>(
                              () => LongPressGestureRecognizer(
                                duration: const Duration(milliseconds: 180),
                              ),
                              (LongPressGestureRecognizer instance) {
                                instance.onLongPressStart =
                                    (canSend || isRecording)
                                        ? null
                                        : (details) async {
                                            HapticFeedback.mediumImpact();
                                            setState(() {
                                              _isHoldRecording = true;
                                              _isRecordingLocked = false;
                                              _recordSlideDx = 0;
                                              _recordSlideDy = 0;
                                            });
                                            await _startRecording();
                                            if (mounted &&
                                                ref
                                                    .read(
                                                      conversationsProvider,
                                                    )
                                                    .isRecording) {
                                              HapticFeedback.lightImpact();
                                            }
                                          };
                                instance.onLongPressMoveUpdate = canSend
                                    ? null
                                    : (details) {
                                        if (!_isHoldRecording ||
                                            _isRecordingLocked) {
                                          return;
                                        }
                                        setState(() {
                                          var dx =
                                              details.offsetFromOrigin.dx;
                                          var dy =
                                              details.offsetFromOrigin.dy;
                                          if (dx < -20 &&
                                              dx.abs() > dy.abs()) {
                                            dy = 0;
                                          } else if (dy < -20 &&
                                              dy.abs() > dx.abs()) {
                                            dx = dx.clamp(-20, 0);
                                          }
                                          _recordSlideDx = dx;
                                          _recordSlideDy = dy;
                                        });
                                      };
                                instance.onLongPressEnd = canSend
                                    ? null
                                    : (details) async {
                                        final recording = ref
                                            .read(conversationsProvider)
                                            .isRecording;
                                        if (!recording &&
                                            !_isHoldRecording) {
                                          return;
                                        }

                                        final cancel = _recordSlideDx <=
                                            _cancelThreshold;
                                        final lock = _recordSlideDy <=
                                            _lockThreshold;

                                        if (cancel) {
                                          await _cancelVoiceRecording();
                                          return;
                                        }
                                        if (lock) {
                                          HapticFeedback.mediumImpact();
                                          setState(() {
                                            _isRecordingLocked = true;
                                            _isHoldRecording = false;
                                            _recordSlideDx = 0;
                                            _recordSlideDy = 0;
                                          });
                                          return;
                                        }
                                        setState(() {
                                          _isHoldRecording = false;
                                          _recordSlideDx = 0;
                                          _recordSlideDy = 0;
                                        });
                                        await _stopAndSendRecording();
                                      };
                              },
                            ),
                          },
                          child: Transform.translate(
                            offset: showHoldHint
                                ? Offset(
                                    _recordSlideDx.clamp(-90, 0),
                                    _recordSlideDy.clamp(-80, 0),
                                  )
                                : Offset.zero,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: showHoldHint ? 56 : 42,
                              height: showHoldHint ? 56 : 42,
                              decoration: BoxDecoration(
                                color: willCancel
                                    ? const Color(0xFFE53935)
                                    : (showHoldHint && isRecording
                                        ? const Color(0xFFE53935)
                                        : primaryGreen),
                                shape: BoxShape.circle,
                                boxShadow: showHoldHint
                                    ? [
                                        BoxShadow(
                                          color: (willCancel || isRecording
                                                  ? const Color(0xFFE53935)
                                                  : primaryGreen)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: _isSendingImage
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : canSend
                                      ? SvgPicture.asset(
                                          'assets/icons/ic_send.svg',
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.scaleDown,
                                        )
                                      : Icon(
                                          willCancel
                                              ? Icons.delete_outline
                                              : willLock
                                                  ? Icons.lock
                                                  : Icons.mic,
                                          color: Colors.white,
                                          size: showHoldHint ? 28 : 22,
                                        ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Attachment Menu ──
  Widget _buildAttachmentMenu(BuildContext context) {
    final l = context.l10n;
    return Positioned(
      bottom: 70,
      left: 16,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(l.camera, 'assets/svg/camera_icon.svg', () async {
              _toggleMenu();
              await ref
                  .read(conversationsProvider.notifier)
                  .pickImageFromCamera();
            }),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            _buildMenuItem(l.gallery, 'assets/svg/gallery_icon.svg', () async {
              _toggleMenu();
              await ref.read(conversationsProvider.notifier).pickImage();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, String svgPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              svgPath,
              width: 20,
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Send / Record methods ──

  int? _latestMessageId(List<MessageModel> messages) {
    if (messages.isEmpty) return null;
    final sorted = List<MessageModel>.from(messages)
      ..sort((a, b) {
        final aTime = _parseSentTime(a.sentTime);
        final bTime = _parseSentTime(b.sentTime);
        return bTime.compareTo(aTime);
      });
    return sorted.first.messageId;
  }

  bool _hasAssistantReplyAfter(int? previousTopMessageId) {
    final messages = ref.read(conversationsProvider).messages;
    if (messages.isEmpty) return false;
    final sorted = List<MessageModel>.from(messages)
      ..sort((a, b) {
        final aTime = _parseSentTime(a.sentTime);
        final bTime = _parseSentTime(b.sentTime);
        return bTime.compareTo(aTime);
      });
    final newest = sorted.first;
    if (previousTopMessageId == newest.messageId) return false;
    return newest.sender != 'user';
  }

  void _startReplyPolling({required int? previousTopMessageId}) {
    _replyPollTimer?.cancel();
    int ticks = 0;
    const maxTicks = 15; // ~15 sn içinde cevap bekle

    _replyPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      ticks++;
      try {
        await ref
            .read(conversationsProvider.notifier)
            .getMessages(widget.specialistId.id);
      } catch (_) {
        // Hata olursa polling devam etsin, max süre sonunda duracak.
      }

      if (_hasAssistantReplyAfter(previousTopMessageId) || ticks >= maxTicks) {
        timer.cancel();
        // AI create_appointment tool'u ile randevu oluşmuş olabilir — listeyi yenile
        if (_hasAssistantReplyAfter(previousTopMessageId)) {
          unawaited(
            ref.read(appointmentsProvider.notifier).refresh(silent: true),
          );
        }
      }
    });
  }

  /// Guest kullanıcıysa önce login'e yönlendiren, değilse paywall açan yardımcı.
  Future<void> _presentPaywallGated() async {
    final isGuest =
        (ref.read(AllProviders.userProvider)?.credential ?? '').toLowerCase() ==
        'guest';
    if (!mounted) return;
    await presentPaywallForUser(context, isGuest: isGuest);
  }

  Future<void> _openVideoCall() async {
    final premiumState = ref.read(AllProviders.premiumProvider);
    if (!premiumState.isPremium) {
      await _presentPaywallGated();
      return;
    }
    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      PageRoutes.videoCall,
      arguments: VideoCallRouteArgs(
        specialist: widget.specialistId,
        isTrial: false,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final previousTopMessageId = _latestMessageId(
      ref.read(conversationsProvider).messages,
    );
    final hasText = _messageController.text.trim().isNotEmpty;
    final selectedImage = ref.watch(
      conversationsProvider.select((state) => state.selectedImage),
    );
    final hasImage = selectedImage != null;

    if (!hasText && !hasImage) return;

    try {
      if (hasImage) {
        final image = ref.watch(
          conversationsProvider.select((state) => state.selectedImage),
        );
        if (image != null) {
          await _handleImageSelected(image);
        }
      } else if (hasText) {
        final trimmed = _messageController.text.trim();
        if (trimmed.isEmpty) return;

        if (hasImage) {
          ref.read(conversationsProvider.notifier).clearSelectedImage();
          setState(() {
            _lastProcessedImagePath = null;
          });
        }

        ref
            .read(conversationsProvider.notifier)
            .sendMessage(id: widget.specialistId.id, text: trimmed)
            .then((_) {
              AnalyticsService.instance.capture(
                AnalyticsEvents.messageSent,
                properties: {
                  'consultant_id': widget.specialistId.id,
                  'has_image': false,
                },
              );
              if (mounted) {
                _startReplyPolling(previousTopMessageId: previousTopMessageId);
              }
            })
            .catchError((Object e) async {
              if (!mounted) return;
              if (e is TrialQuotaExceededException) {
                await _presentPaywallGated();
                return;
              }
              debugPrint("❌ Mesaj gönderme hatası: $e");
            });

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

  Future<void> _sendVoiceMessage(String audioPath) async {
    final previousTopMessageId = _latestMessageId(
      ref.read(conversationsProvider).messages,
    );
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

      // Ses gönderildiği anda kullanıcı balonunu optimistik olarak göster.
      ref
          .read(conversationsProvider.notifier)
          .addOptimisticVoiceMessage(
            consultantId: widget.specialistId.id,
            localAudioPath: audioPath,
          );

      ref
          .read(conversationsProvider.notifier)
          .sendVoiceMessage(
            consultantId: widget.specialistId.id,
            audioFile: file,
            message: null,
          )
          .then((_) {
            if (mounted) {
              _startReplyPolling(previousTopMessageId: previousTopMessageId);
            }
          })
          .catchError((Object e) async {
            if (!mounted) return;
            if (e is TrialQuotaExceededException) {
              await _presentPaywallGated();
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.errorVoiceMessageFailed),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
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

  Future<void> _cancelVoiceRecording() async {
    try {
      if (_recorderController != null) {
        await _recorderController!.stop();
      }
    } catch (_) {}
    await ref.read(conversationsProvider.notifier).cancelRecording();
    if (!mounted) return;
    setState(() {
      _isRecordingLocked = false;
      _isHoldRecording = false;
      _recordSlideDx = 0;
      _recordSlideDy = 0;
    });
  }

  Future<void> _startRecording() async {
    _recorderController ??= _createRecorderController();

    final isRecording = ref.read(conversationsProvider).isRecording;
    if (!isRecording && _recorderController != null) {
      try {
        final path =
            '${(await getTemporaryDirectory()).path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await ref
            .read(conversationsProvider.notifier)
            .startRecordingWithPath(path);
        await _recorderController!.record(path: path);
      } catch (e) {
        await ref.read(conversationsProvider.notifier).cancelRecording();
        if (mounted) {
          setState(() {
            _isRecordingLocked = false;
            _isHoldRecording = false;
          });
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

  Future<void> _toggleRecordingPause() async {
    if (_recorderController == null) return;
    final notifier = ref.read(conversationsProvider.notifier);
    final paused = ref.read(conversationsProvider).isRecordingPaused;

    try {
      if (paused) {
        await _recorderController!.record();
        notifier.resumeRecording();
      } else {
        await _recorderController!.pause();
        notifier.pauseRecording();
      }
    } catch (e) {
      debugPrint('Recording pause/resume error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paused
                  ? context.l10n.errorRecordingStart
                  : 'Kayıt duraklatılamadı',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopAndSendRecording() async {
    final isRecording = ref.read(conversationsProvider).isRecording;
    if (isRecording && _recorderController != null) {
      try {
        final path = await _recorderController!.stop();
        if (!mounted) return;
        setState(() {
          _isRecordingLocked = false;
          _isHoldRecording = false;
          _recordSlideDx = 0;
          _recordSlideDy = 0;
        });
        if (path != null && path.isNotEmpty) {
          ref.read(conversationsProvider.notifier).updateRecordingPath(path);
          await ref.read(conversationsProvider.notifier).stopRecording();
          final file = File(path);
          if (await file.exists() && mounted) {
            await _sendVoiceMessage(path);
          } else {
            await ref.read(conversationsProvider.notifier).cancelRecording();
          }
        } else {
          await ref.read(conversationsProvider.notifier).cancelRecording();
        }
      } catch (e) {
        await ref.read(conversationsProvider.notifier).cancelRecording();
        if (mounted) {
          setState(() {
            _isRecordingLocked = false;
            _isHoldRecording = false;
          });
        }
      }
    }
  }

  Future<void> _sendVoiceMessageFromRecording() async {
    if (ref.read(conversationsProvider).isRecording) {
      await _stopAndSendRecording();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  DateTime _parseSentTime(dynamic sentTime) {
    if (sentTime == null) return DateTime(1970);
    if (sentTime is DateTime) return sentTime;
    if (sentTime is String) {
      try {
        return DateTime.parse(sentTime);
      } catch (e) {
        return DateTime(1970);
      }
    }
    return DateTime(1970);
  }

  Future<void> _handleImageSelected(XFile image) async {
    final previousTopMessageId = _latestMessageId(
      ref.read(conversationsProvider).messages,
    );
    if (image.path == _lastProcessedImagePath || _isSendingImage) return;

    setState(() {
      _lastProcessedImagePath = image.path;
      _isSendingImage = true;
    });

    if (!mounted) return;

    try {
      final file = File(image.path);
      final messageText = _messageController.text.trim();

      // Resmi anında kullanıcı balonu olarak göster.
      ref
          .read(conversationsProvider.notifier)
          .addOptimisticImageMessage(
            consultantId: widget.specialistId.id,
            localImagePath: image.path,
            message: messageText,
          );

      ref
          .read(conversationsProvider.notifier)
          .sendImageMessage(
            consultantId: widget.specialistId.id,
            imageFile: file,
            message: messageText.isNotEmpty ? messageText : null,
          )
          .then((_) {
            if (mounted) {
              _startReplyPolling(previousTopMessageId: previousTopMessageId);
            }
          })
          .catchError((Object e) async {
            if (!mounted) return;
            if (e is TrialQuotaExceededException) {
              await _presentPaywallGated();
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.errorImageFailed),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          });

      _messageController.clear();
      ref.read(conversationsProvider.notifier).clearSelectedImage();

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
          content: Text('Resim gönderilemedi: ${e.toString()}'),
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
}

// ── Typing Indicator ──

class _PulsingRecordDot extends StatefulWidget {
  final bool active;
  final bool paused;
  const _PulsingRecordDot({
    required this.active,
    this.paused = false,
  });

  @override
  State<_PulsingRecordDot> createState() => _PulsingRecordDotState();
}

class _PulsingRecordDotState extends State<_PulsingRecordDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    if (widget.active && !widget.paused) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingRecordDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldPulse = widget.active && !widget.paused;
    if (shouldPulse && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldPulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.paused
        ? const Color(0xFF96989C)
        : const Color(0xFFE53935);

    if (!widget.active || widget.paused) {
      return Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // 0 → 1 arası: halka büyür/solar, nokta nabız atar
        final t = Curves.easeOut.transform(_controller.value);
        final ringScale = 1.0 + (t * 1.35);
        final ringOpacity = (1.0 - t).clamp(0.0, 1.0);
        final dotScale = 0.82 + (0.18 * (1 - (2 * t - 1).abs()));

        return SizedBox(
          width: 22,
          height: 22,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: ringScale,
                child: Opacity(
                  opacity: ringOpacity * 0.55,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: dotScale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConversationShimmer extends StatelessWidget {
  const _ConversationShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: const [
        _ShimmerBubble(isMe: false, widthFactor: 0.58),
        _ShimmerBubble(isMe: true, widthFactor: 0.38),
        _ShimmerBubble(isMe: false, widthFactor: 0.72),
        _ShimmerBubble(isMe: true, widthFactor: 0.46),
        _ShimmerBubble(isMe: false, widthFactor: 0.63),
      ],
    );
  }
}

class _ShimmerBubble extends StatelessWidget {
  final bool isMe;
  final double widthFactor;
  const _ShimmerBubble({required this.isMe, required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    final bubble = Shimmer.fromColors(
      baseColor: const Color(0xFFEDEDED),
      highlightColor: const Color(0xFFF8F8F8),
      child: Container(
        width: MediaQuery.of(context).size.width * widthFactor,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 16 : 0),
            topRight: Radius.circular(isMe ? 0 : 16),
            bottomLeft: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
        ),
      ),
    );

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _CoachAvatar(photoURL: '', size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Align(alignment: Alignment.centerLeft, child: bubble),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final String photoURL;
  const _TypingIndicator({required this.photoURL});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Coach avatar
          _CoachAvatar(photoURL: widget.photoURL, size: 28),
          const SizedBox(width: 8),

          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    final t = (_controller.value - delay) % 1.0;
                    final opacity = (t < 0.5)
                        ? (0.3 + 0.7 * (t / 0.5))
                        : (1.0 - 0.7 * ((t - 0.5) / 0.5));
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Opacity(
                        opacity: opacity.clamp(0.3, 1.0),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF96989C),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coach Avatar ──

class _CoachAvatar extends StatelessWidget {
  final String photoURL;
  final double size;
  const _CoachAvatar({required this.photoURL, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: photoURL.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoURL,
                fit: BoxFit.cover,
                placeholder: (_, _) => const SizedBox.shrink(),
                errorWidget: (_, _, _) => Container(
                  color: const Color(0xFFF5F5F5),
                  child: Icon(
                    Icons.person,
                    size: size * 0.6,
                    color: const Color(0xFF96989C),
                  ),
                ),
              )
            : Container(
                color: const Color(0xFFF5F5F5),
                child: Icon(
                  Icons.person,
                  size: size * 0.6,
                  color: const Color(0xFF96989C),
                ),
              ),
      ),
    );
  }
}

// ── Message Bubble ──

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({required this.message, required this.coachPhotoURL});
  final MessageModel message;
  final String coachPhotoURL;

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
    _loadAudioDuration();

    _globalAudioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        final isThisPlaying =
            _currentlyPlayingMessageId == widget.message.messageId.toString();
        setState(() {
          _isPlaying =
              isThisPlaying && state == audio_players.PlayerState.playing;
        });
      }
    });
    _globalAudioPlayer.onDurationChanged.listen((duration) {
      if (mounted &&
          duration != Duration.zero &&
          _currentlyPlayingMessageId == widget.message.messageId.toString()) {
        setState(() {
          _duration = duration;
        });
      }
    });
    _globalAudioPlayer.onPlayerComplete.listen((_) {
      if (mounted &&
          _currentlyPlayingMessageId == widget.message.messageId.toString()) {
        setState(() {
          _isPlaying = false;
        });
        _currentlyPlayingMessageId = null;
      }
    });
  }

  Future<void> _loadAudioDuration() async {
    if (widget.message.voiceURL != null &&
        widget.message.voiceURL!.isNotEmpty) {
      try {
        final tempPlayer = audio_players.AudioPlayer();
        Duration? loadedDuration;
        bool durationLoaded = false;
        final voiceUrl = widget.message.voiceURL!;
        final isRemote =
            voiceUrl.startsWith('http://') || voiceUrl.startsWith('https://');

        final subscription = tempPlayer.onDurationChanged.listen((duration) {
          if (duration != Duration.zero && !durationLoaded) {
            loadedDuration = duration;
            durationLoaded = true;
          }
        });

        await tempPlayer.setSource(
          isRemote
              ? audio_players.UrlSource(voiceUrl)
              : audio_players.DeviceFileSource(voiceUrl),
        );

        // Bazı cihaz/sürümlerde onDurationChanged oynatma başlamadan tetiklenmiyor.
        // Bu yüzden getDuration() ile aktif polling yapıp süreyi önceden alıyoruz.
        int attempts = 0;
        while (!durationLoaded && attempts < 20 && mounted) {
          final polled = await tempPlayer.getDuration();
          if (polled != null && polled != Duration.zero) {
            loadedDuration = polled;
            durationLoaded = true;
            break;
          }
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }

        await subscription.cancel();
        await tempPlayer.dispose();

        if (loadedDuration != null && mounted) {
          setState(() {
            _duration = loadedDuration!;
          });
        }
      } catch (e) {
        debugPrint(" Ses süresi okunamadı: $e");
      }
    }
  }

  @override
  void dispose() {
    if (_currentlyPlayingMessageId == widget.message.messageId.toString()) {
      _globalAudioPlayer.stop();
      _currentlyPlayingMessageId = null;
    }
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_currentlyPlayingMessageId != null &&
          _currentlyPlayingMessageId != widget.message.messageId.toString()) {
        await _globalAudioPlayer.stop();
      }

      if (_isPlaying) {
        await _globalAudioPlayer.pause();
        _currentlyPlayingMessageId = null;
        setState(() {
          _isPlaying = false;
        });
      } else {
        if (widget.message.voiceURL != null &&
            widget.message.voiceURL!.isNotEmpty) {
          _currentlyPlayingMessageId = widget.message.messageId.toString();

          try {
            final voiceUrl = widget.message.voiceURL!;
            final isRemote =
                voiceUrl.startsWith('http://') ||
                voiceUrl.startsWith('https://');
            await _globalAudioPlayer.setSource(
              isRemote
                  ? audio_players.UrlSource(voiceUrl)
                  : audio_players.DeviceFileSource(voiceUrl),
            );
            await _globalAudioPlayer.resume();
            setState(() {
              _isPlaying = true;
            });
          } catch (e) {
            _currentlyPlayingMessageId = null;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.errorVoiceNotPlayed),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorVoiceMessageNotPlayed),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatAudioDuration(Duration duration) {
    if (duration == Duration.zero) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.sender == "user";
    final hasImage =
        widget.message.isFile == true &&
        widget.message.fileURL != null &&
        widget.message.fileURL!.isNotEmpty;
    final hasVoice =
        widget.message.isVoiceMessage == true &&
        widget.message.voiceURL != null &&
        widget.message.voiceURL!.isNotEmpty;

    if (isMe) {
      return _buildUserBubble(hasImage, hasVoice);
    }
    return _buildCoachBubble(hasImage, hasVoice);
  }

  Widget _buildUserBubble(bool hasImage, bool hasVoice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF21BC87),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.zero,
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: _buildBubbleContent(
              isMe: true,
              hasImage: hasImage,
              hasVoice: hasVoice,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachBubble(bool hasImage, bool hasVoice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CoachAvatar(photoURL: widget.coachPhotoURL, size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.zero,
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: _buildBubbleContent(
                    isMe: false,
                    hasImage: hasImage,
                    hasVoice: hasVoice,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleContent({
    required bool isMe,
    required bool hasImage,
    required bool hasVoice,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (() {
              final fileUrl = widget.message.fileURL!;
              final isRemote =
                  fileUrl.startsWith('http://') ||
                  fileUrl.startsWith('https://');
              if (isRemote) {
                return CachedNetworkImage(
                  imageUrl: fileUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const SizedBox.shrink(),
                  errorWidget: (_, _, _) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, color: Colors.grey[600]),
                  ),
                );
              }
              return Image.file(
                File(fileUrl),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, color: Colors.grey[600]),
                ),
              );
            })(),
          ),

        if (hasVoice) ...[
          if (hasImage) const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.22)
                    : const Color(0xFFE4E7EC),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isMe ? Colors.white : const Color(0xFFF2F4F7),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isMe ? const Color(0xFF21BC87) : Colors.black87,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(28, (index) {
                        return Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 2.5,
                              height: index % 4 == 0
                                  ? 14.0
                                  : (index % 2 == 0 ? 10.0 : 7.0),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : const Color(0xFF98A2B3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatAudioDuration(_duration),
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.95)
                        : const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (widget.message.message.isNotEmpty && !hasVoice) ...[
          if (hasImage) const SizedBox(height: 8),
          Text(
            widget.message.message,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isMe ? Colors.white : Color(0xFF96989C),
            ),
          ),
        ],
      ],
    );
  }
}
