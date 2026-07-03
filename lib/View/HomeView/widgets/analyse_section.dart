import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/Services/rive_preload_service.dart';
import 'package:mindcoach/View/chat_screen/conversation/video_call/video_call_realtime_screen.dart';
import 'package:mindcoach/View/specialists_screen/specialists_notifier.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/widgets/future_progress_dialog.dart';
import 'package:mindcoach/models/consultant_model.dart';

/// "AI-powered — understand your mind" analyse card shown right above the
/// coach list. Values mirror the Figma design.
class AnalyseSection extends ConsumerStatefulWidget {
  const AnalyseSection({super.key});

  @override
  ConsumerState<AnalyseSection> createState() => _AnalyseSectionState();
}

class _AnalyseSectionState extends ConsumerState<AnalyseSection> {
  static const _primaryGreen = Color(0xFF21BC87);
  static const _gradientEnd = Color(0xFFF6F6F6);

  /// Psikolojik analizi yürüten karakter (Sıla Yılmaz / Nova Care) consultants tablosunda bu id ile tanımlı.
  static const int _analysisConsultantId = 3;

  /// Sıla Yılmaz Rive dosyası — url3d boş gelirse yedek olarak kullanılır.
  static const String _analysisRiveFallbackUrl =
      'https://mindcoach.b-cdn.net/Female%20Riv/f_avatar7.riv';

  /// Kart görseli — Sıla Yılmaz karakterinin detay ekranındaki yandan duruşu.
  /// Consultant bulunamazsa yedek olarak kullanılır.
  static const String _analysisCardImageUrl =
      'https://mindcoach.b-cdn.net/c_nova_care_detail.png';

  /// Detay ekranındaki gibi photoURL uzantısından önce `_detail` ekler.
  String _resolveCardImageUrl(ConsultantModel? consultant) {
    final photo = consultant?.photoURL.trim();
    if (photo == null || photo.isEmpty) return _analysisCardImageUrl;
    final dotIndex = photo.lastIndexOf('.');
    if (dotIndex == -1) return _analysisCardImageUrl;
    return '${photo.substring(0, dotIndex)}_detail${photo.substring(dotIndex)}';
  }

  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    // Liste yüklendiğinde avatarı arka planda ön-yükle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAnalysisRiveIfPossible();
    });
  }

  void _preloadAnalysisRiveIfPossible() {
    final consultant = _findAnalysisConsultant(ref);
    final url = _resolveRiveUrl(consultant);
    if (url != null) {
      RivePreloadService.instance.preload(url);
    }
  }

  String? _resolveRiveUrl(ConsultantModel? consultant) {
    final raw = consultant?.url3d?.trim();
    if (raw != null && raw.isNotEmpty) {
      return RivePreloadService.normalizeRiveUrl(raw) ??
          _analysisRiveFallbackUrl;
    }
    return _analysisRiveFallbackUrl;
  }

  Future<void> _startAnalysis(BuildContext context) async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      await context.runWithProgressDialog(() async {
        ConsultantModel? consultant = await _resolveAnalysisConsultant();

        if (!context.mounted) return;

        if (consultant == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analiz danışmanı şu anda kullanılamıyor.'),
            ),
          );
          return;
        }

        final riveUrl = _resolveRiveUrl(consultant)!;
        consultant = consultant.copyWith(url3d: riveUrl);

        // 4 MB civarı .riv indirilmeden görüşme açılırsa ekran karanlık kalır.
        final riveReady = await RivePreloadService.instance.ensurePreloaded(
          riveUrl,
        );

        if (!context.mounted) return;

        if (!riveReady) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Avatar yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.',
              ),
            ),
          );
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoCallRealtimeScreen(
              specialist: consultant!,
              isAnalysis: true,
            ),
          ),
        );
      }, message: context.l10n.pleaseWait);
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  /// Önce bellekteki listeden, yoksa GET /consultants/:id ile danışmanı bulur.
  Future<ConsultantModel?> _resolveAnalysisConsultant() async {
    ConsultantModel? consultant = _findAnalysisConsultant(ref);
    if (consultant != null) return consultant;

    try {
      await ref.read(specialistsProvider.notifier).init();
    } catch (_) {}

    consultant = _findAnalysisConsultant(ref);
    if (consultant != null) return consultant;

    return ref
        .read(specialistsProvider.notifier)
        .fetchConsultantById(_analysisConsultantId);
  }

  ConsultantModel? _findAnalysisConsultant(WidgetRef ref) {
    final list = ref.read(specialistsProvider).specialists;
    return _pickAnalysisConsultant(list);
  }

  ConsultantModel? _pickAnalysisConsultant(List<ConsultantModel>? list) {
    if (list == null || list.isEmpty) return null;
    for (final c in list) {
      if (c.id == _analysisConsultantId) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    // Liste güncellenince Rive ön-yüklemesini tetikle.
    ref.listen<SpecialistsState>(specialistsProvider, (prev, next) {
      if (prev?.specialists != next.specialists) {
        _preloadAnalysisRiveIfPossible();
      }
    });

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: _isStarting ? null : () => _startAnalysis(context),
        child: ClipRect(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.85, -0.35),
                radius: 1.25,
                colors: [_primaryGreen, _gradientEnd],
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AiBadge(label: l.analyseBadge),
                          const SizedBox(height: 10),
                          Text(
                            l.analyseTitle,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              height: 20 / 16,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l.analyseSubtitle,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withValues(alpha: 0.65),
                              height: 18 / 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _StartAnalyzeButton(
                            label: l.analyseCta,
                            isLoading: _isStarting,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: AspectRatio(
                        aspectRatio: 205 / 270,
                        child: CachedNetworkImage(
                          imageUrl: _resolveCardImageUrl(
                            _findAnalysisConsultant(ref),
                          ),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          placeholder: (_, _) => const SizedBox.shrink(),
                          errorWidget: (_, _, _) => Image.asset(
                            'assets/analyse/analyse.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _AnalyseSectionState._primaryGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _AnalyseSectionState._primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _AnalyseSectionState._primaryGreen,
              height: 18 / 14,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartAnalyzeButton extends StatelessWidget {
  const _StartAnalyzeButton({
    required this.label,
    this.isLoading = false,
  });

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _AnalyseSectionState._primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (isLoading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
          ),
          if (!isLoading) ...[
            const SizedBox(width: 10),
            SvgPicture.asset(
              'assets/icons/ic_rightt.svg',
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
