import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mindcoach/Riverpod/Controllers/ProfileSetupController/profile_setup_controller.dart';
import 'package:mindcoach/Riverpod/Controllers/all_controllers.dart';
import 'package:mindcoach/Services/Analytics/analytics_service.dart';
import 'package:mindcoach/core/analytics/analytics_events.dart';
import 'package:mindcoach/core/analytics/funnel_analytics.dart';
import 'package:mindcoach/View/ProfileSetupView/constants/meeting_time_constants.dart';
import 'package:mindcoach/View/ProfileSetupView/domain/profile_models.dart';
import 'package:mindcoach/View/specialists_screen/specialist_detail_screen.dart';
import 'package:mindcoach/View/specialists_screen/specialists_notifier.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/feature_convert.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/models/consultant_model.dart';

class FindCoachScreen extends ConsumerWidget {
  const FindCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(AllControllers.profileSetupProvider);
    final specialistsState = ref.watch(specialistsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FindCoachStep(
            profileState: profileState,
            coaches: specialistsState.specialists ?? const [],
            loadFailed: specialistsState.loadFailed,
          ),
        ),
      ),
    );
  }
}

class FindCoachStep extends ConsumerStatefulWidget {
  const FindCoachStep({
    super.key,
    required this.profileState,
    required this.coaches,
    this.loadFailed = false,
  });

  final ProfileSetupState profileState;
  final List<ConsultantModel> coaches;

  /// Danışman listesi yüklenemediyse (bağlantı hatası) retry butonu gösterilir.
  final bool loadFailed;

  @override
  ConsumerState<FindCoachStep> createState() => _FindCoachStepState();
}

class _FindCoachStepState extends ConsumerState<FindCoachStep> {
  int _index = 0;
  bool _isSubmitting = false;
  bool _matchesViewTracked = false;
  Offset _dragOffset = Offset.zero;
  static const double _horizontalSwipeThreshold = 90;
  static const int _maxDisplayCoaches = 3;

  /// Filtre / koç listesi değişince yeniden 3 rastgele koç üretmek için.
  int? _displayPoolCacheKey;
  List<ConsultantModel>? _displayCoaches;

  void _maybeTrackMatchesViewed() {
    if (_matchesViewTracked) return;
    final matched = _matchedCoaches();
    if (matched.isEmpty) return;
    _matchesViewTracked = true;
    final props = FunnelAnalytics.coachMatchesViewedProps(widget.profileState);
    props['match_count'] = matched.length;
    unawaited(
      AnalyticsService.instance.capture(
        AnalyticsEvents.coachMatchesViewed,
        properties: props,
      ),
    );
  }

  void _trackCoachCardSwiped() {
    final matched = _matchedCoaches();
    if (matched.isEmpty) return;
    final coach = matched[_index % matched.length];
    unawaited(
      AnalyticsService.instance.capture(
        AnalyticsEvents.coachCardSwiped,
        properties: {
          'coach_id': coach.id.toString(),
          'position': _index,
        },
      ),
    );
  }

  void _trackCoachSkipped() {
    final matched = _matchedCoaches();
    if (matched.isEmpty) return;
    final coach = matched[_index % matched.length];
    unawaited(
      AnalyticsService.instance.capture(
        AnalyticsEvents.coachSkipped,
        properties: {
          'coach_id': coach.id.toString(),
          'position': _index,
        },
      ),
    );
  }

  void _trackCoachBookTapped() {
    final matched = _matchedCoaches();
    if (matched.isEmpty) return;
    final coach = matched[_index % matched.length];
    unawaited(
      AnalyticsService.instance.capture(
        AnalyticsEvents.coachBookTapped,
        properties: {
          'coach_id': coach.id.toString(),
          'position': _index,
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant FindCoachStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= _matchedCoaches().length && _matchedCoaches().isNotEmpty) {
      _index = 0;
    }
    _maybeTrackMatchesViewed();
  }

  /// Alan filtresi sonrası aday havuzu (henüz 3 ile sınırlı değil).
  List<ConsultantModel> _filteredPool() {
    final source = widget.coaches;
    if (source.isEmpty) return const [];
    final selectedArea = widget.profileState.supportArea;
    if (selectedArea == null) return source;
    final key = selectedArea.name.toLowerCase();
    final filtered = source.where((c) {
      final job = c.job.toLowerCase();
      final features = c.features
          .map((e) => e.toString().toLowerCase())
          .join(' ');
      return job.contains(key) || features.contains(key);
    }).toList();
    return filtered.isEmpty ? source : filtered;
  }

  /// En fazla [_maxDisplayCoaches] koç; havuz karıştırılıp rastgele seçilir (oturum içi sabit).
  List<ConsultantModel> _matchedCoaches() {
    final pool = _filteredPool();
    if (pool.isEmpty) return const [];

    final ids = pool.map((c) => c.id).toList()..sort();
    final cacheKey = Object.hash(
      ids.join(','),
      widget.profileState.supportArea?.index,
    );

    if (_displayPoolCacheKey != cacheKey) {
      _displayPoolCacheKey = cacheKey;
      final shuffled = List<ConsultantModel>.from(pool)..shuffle(Random());
      _displayCoaches = shuffled.take(_maxDisplayCoaches).toList();
    }
    return _displayCoaches ?? const [];
  }

  String _selectedDaysText() {
    final l10n = context.l10n;
    final dayShort = <Weekday, String>{
      Weekday.monday: l10n.dayMonday,
      Weekday.tuesday: l10n.dayTuesday,
      Weekday.wednesday: l10n.dayWednesday,
      Weekday.thursday: l10n.dayThursday,
      Weekday.friday: l10n.dayFriday,
      Weekday.saturday: l10n.daySaturday,
      Weekday.sunday: l10n.daySunday,
    };
    final days = widget.profileState.availableDays;
    if (days.isEmpty) return '';
    if (days.length == 1) return dayShort[days.first] ?? '';
    return '${dayShort[days.first] ?? ''} & ${dayShort[days[1]] ?? ''}';
  }

  int _ageForCoach(ConsultantModel coach) {
    // Koça göre stabil rastgele yaş (25-42)
    return 25 + ((coach.id * 7) % 18);
  }

  int _experienceForCoach(ConsultantModel coach) {
    // Koça göre stabil rastgele deneyim yılı (2-12)
    return 2 + ((coach.id * 5) % 11);
  }

  String _supportAreaLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (widget.profileState.supportArea) {
      case null:
        return l10n.supportAreaPersonalDevelopment;
      case SupportArea.individual:
        return l10n.supportAreaIndividual;
      case SupportArea.family:
        return l10n.supportAreaFamily;
      case SupportArea.career:
        return l10n.supportAreaCareer;
      case SupportArea.education:
        return l10n.supportAreaEducation;
      case SupportArea.personalDevelopment:
        return l10n.supportAreaPersonalDevelopment;
    }
  }

  void _skipToNextCoach({bool trackSkipEvent = false}) {
    final len = _matchedCoaches().length;
    if (len <= 1) return;
    if (trackSkipEvent) _trackCoachSkipped();
    setState(() => _index = (_index + 1) % len);
    _trackCoachCardSwiped();
  }

  void _goToPreviousCoach() {
    final len = _matchedCoaches().length;
    if (len <= 1) return;
    setState(() => _index = (_index - 1 + len) % len);
    _trackCoachCardSwiped();
  }

  Future<void> _selectCurrentCoach() async {
    if (_isSubmitting) return;
    final matched = _matchedCoaches();
    if (matched.isEmpty) return;
    final coach = matched[_index % matched.length];

    _trackCoachBookTapped();
    setState(() => _isSubmitting = true);
    try {
      // Riverpod state'inde secili kocu isaretle (UI tarafinda kullanilan
      // selectedId gibi yerler dogru calisabilsin diye)
      ref.read(specialistsProvider.notifier).selectSpecialist(coach.id);
      if (!mounted) return;

      // Onboarding'de henuz login olmamis kullanici icin SpecialistDetailScreen'i
      // 1 dakikalik trial modunda ac. Sure dolunca dialog gosterilip login'e
      // yonlendirilecek (SpecialistDetailScreen icinde).
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              SpecialistDetailScreen(
                specialist: coach,
                isTrial: true,
                profileSource: 'book_button',
              ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneral)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matched = _matchedCoaches();
    final hasCoach = matched.isNotEmpty;
    final coach = hasCoach ? matched[_index % matched.length] : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeTrackMatchesViewed();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, matched.length),
        const SizedBox(height: 18),
        Expanded(
          child: Padding(
            // Kartın dönüş sırasında kenarlarının kesilmemesi için boşlukları dengeledik
            padding: const EdgeInsets.only(bottom: 24, top: 4),
            child: hasCoach
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      setState(() {
                        _dragOffset += details.delta;
                      });
                    },
                    onPanCancel: () {
                      setState(() => _dragOffset = Offset.zero);
                    },
                    onPanEnd: (_) {
                      final dx = _dragOffset.dx;
                      if (dx >= _horizontalSwipeThreshold) {
                        _goToPreviousCoach();
                      } else if (dx <= -_horizontalSwipeThreshold) {
                        _skipToNextCoach(trackSkipEvent: true);
                      }
                      setState(() => _dragOffset = Offset.zero);
                    },
                    child: AnimatedContainer(
                      duration: Duration.zero,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey<int>(coach!.id),
                          child: _buildCoachCard(context, coach, _dragOffset),
                        ),
                      ),
                    ),
                  )
                : widget.loadFailed
                    ? _buildRetryState()
                    : const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: 12),
        if (hasCoach) _buildBottomActions(),
      ],
    );
  }

  /// Bağlantı hatası durumunda sonsuz spinner yerine gösterilir.
  Widget _buildRetryState() {
    final tr = Localizations.localeOf(context).languageCode == 'tr';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF96989C)),
          const SizedBox(height: 16),
          Text(
            tr ? 'Rehberler yüklenemedi' : 'Could not load coaches',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr
                ? 'İnternet bağlantını kontrol edip tekrar dene.'
                : 'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: Color(0xFF96989C),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF21BC87),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              ref.read(specialistsProvider.notifier).retry();
            },
            child: Text(tr ? 'Tekrar dene' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final meetingTimeLabel = MeetingTimeStrings.label(
      context,
      widget.profileState.meetingTime ?? MeetingTime.morning,
    );
    final daysText = _selectedDaysText();
    final scheduleText = daysText.isEmpty
        ? meetingTimeLabel
        : '$daysText - $meetingTimeLabel';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.findCoachMatchedFor(
                count,
                _supportAreaLabel(context),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF21BC87),
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
            TextButton(
              style: ButtonStyle(
                padding: WidgetStateProperty.all(EdgeInsets.zero),
              ),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(PageRoutes.login, (route) => false);
              },
              child: Text(
                context.l10n.findCoachSkip,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF96989C),
                ),
              ),
            ),
          ],
        ),
        Text(
          context.l10n.findCoachTitle,
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.0,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.findCoachSwipeToBrowse(scheduleText),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF96989C),
            height: 1.0,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildCoachCard(
    BuildContext context,
    ConsultantModel coach,
    Offset dragOffset,
  ) {
    final lang = context.langCode;
    final name =
        coach.names[lang] as String? ??
        coach.names['en'] as String? ??
        coach.names.values.first.toString();
    final age = _ageForCoach(coach);
    final experienceYears = _experienceForCoach(coach);
    final featureConvert = FeatureConvert(context);
    final features = coach.features
        .map((f) => featureConvert.call(f.toString()))
        .take(3)
        .toList();
    final originalUrl = coach.photoURL;
    String detailUrl = originalUrl;
    final dotIndex = originalUrl.lastIndexOf('.');
    if (dotIndex != -1) {
      detailUrl =
          '${originalUrl.substring(0, dotIndex)}_detail${originalUrl.substring(dotIndex)}';
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Arkadaki Açık Renkli Kart (Döndürülmüş ve Kaydırılmış)
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(0, 12), // Biraz sola ve aşağı kaydırıyoruz
            child: Transform.rotate(
              angle: 0.05,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2BD383).withValues(alpha: 0.4),
                      Color(0xFF11998E).withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),

        // 2. Ana Kart (Fotoğrafın olduğu yer)
        AnimatedContainer(
          duration: dragOffset == Offset.zero
              ? const Duration(milliseconds: 180)
              : Duration.zero,
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(dragOffset.dx, dragOffset.dy, 0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2BD383), Color(0xFF11998E)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: detailUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF11998E),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_rounded,
                          size: 90,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),

                // Kartın altındaki siyah karartma (gradient)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 220,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.95),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Sol Üst Rozet (Puan)
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildTopBadge(
                    icon: SvgPicture.asset('assets/icons/start.svg'),
                    iconColor: const Color(0xFFFFD700),
                    text: coach.rating.toStringAsFixed(2),
                  ),
                ),

                // Sağ Üst Rozet (Online Durumu)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildTopBadge(
                    icon: Icon(
                      Icons.circle,
                      color: const Color(0xFF2BD383),
                      size: 10,
                    ),
                    iconColor: Colors.white,
                    text: context.l10n.online,
                    iconSize: 10,
                  ),
                ),

                // Alt Metinler (İsim, Meslek ve Etiketler)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$name, $age',
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 28 / 32,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${JobConvert(coach.job, context).call()} | ${context.l10n.findCoachYearsExperience(experienceYears)}',
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF96989C),
                          height: 1.0,
                          letterSpacing: 0.16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final f in features) _buildTag(f)],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBadge({
    required Widget icon,
    required Color iconColor,
    required String text,
    double iconSize = 16,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Geist',
              color: iconColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Geist',
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 16 / 12,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/icons/larrow.svg"),
            const SizedBox(width: 8),
            Text(
              context.l10n.findCoachSkip,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF96989C),
                height: 1.0,
              ),
            ),
            const SizedBox(width: 48),
            Text(
              context.l10n.findCoachBook,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF96989C),
                height: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset("assets/icons/rarrow.svg"),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _skipToNextCoach(trackSkipEvent: true),
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4B4B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33FF4B4B),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  "assets/icons/ic_close2.svg",
                  fit: BoxFit.scaleDown,
                  width: 36,
                  height: 36,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: _selectCurrentCoach,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF2BD383),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x332BD383),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : SvgPicture.asset(
                        fit: BoxFit.scaleDown,
                        'assets/icons/ic_record.svg',
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
