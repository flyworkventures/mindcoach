import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/explanation_convert.dart';
import 'package:mindcoach/core/utils/feature_convert.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/models/consultant_model.dart';

class SpecialistDetailScreen extends ConsumerStatefulWidget {
  final ConsultantModel specialist;

  const SpecialistDetailScreen({super.key, required this.specialist});

  @override
  ConsumerState<SpecialistDetailScreen> createState() =>
      _SpecialistDetailScreenState();
}

class _SpecialistDetailScreenState
    extends ConsumerState<SpecialistDetailScreen> {
  int? _selectedSlotIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final langCode = context.langCode;
    final specialist = widget.specialist;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final specialistName =
        specialist.names[langCode] as String? ??
        specialist.names['en'] as String? ??
        specialist.names.values.first.toString();

    final jobTitle = JobConvert(specialist.job, context).call();
    final featureConvert = FeatureConvert(context);
    final explanationConvert = ExplanationConvert(context);
    final explanation = explanationConvert.call(specialist.explanation);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // Scrollable area
            Expanded(
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ======== TOP HERO SECTION ========
                    // Photo right, content left — stacked
                    SizedBox(
                      height: 420,
                      child: Stack(
                        children: [
                          // Coach photo — right aligned, clipped
                          // Coach photo — right aligned, clipped
                          Positioned(
                            top: 20,
                            right: -20,
                            bottom: 0,
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: Builder(
                              builder: (context) {
                                final url = specialist.photoURL;
                                final isSvg = url.toLowerCase().endsWith(
                                  '.svg',
                                );

                                Widget fallbackIcon() => Container(
                                  color: const Color(0xFFF5F5F5),
                                  child: const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Color(0xFF96989C),
                                  ),
                                );

                                if (isSvg) {
                                  return SvgPicture.network(
                                    url,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (_, _, _) => fallbackIcon(),
                                  );
                                } else {
                                  return Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (_, _, _) => fallbackIcon(),
                                  );
                                }
                              },
                            ),
                          ),

                          // Left content overlay
                          Positioned(
                            top: 20,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),

                                  // < Back
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.chevron_left,
                                          size: 24,
                                          color: Colors.black,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'Back',
                                          style: TextStyle(
                                            fontFamily: 'Geist',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Badges: Verified + Rating + Online
                                  Row(
                                    children: [
                                      // Verified badge
                                      SvgPicture.asset(
                                        "assets/icons/ic_coach_detail_tick.svg",
                                      ),
                                      const SizedBox(width: 4),

                                      // Rating pill
                                      if (specialist.rating > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFFFC107,
                                            ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SvgPicture.asset(
                                                "assets/icons/start.svg",
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                specialist.rating
                                                    .toStringAsFixed(2),
                                                style: const TextStyle(
                                                  fontFamily: 'Geist',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF333333),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(width: 4),

                                      // Online pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE2E2E2),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF21BC87),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              l10n.coachDetailOnline,
                                              style: const TextStyle(
                                                fontFamily: 'Geist',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Coach Name — big green
                                  Text(
                                    specialistName,
                                    style: const TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF21BC87),
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Job title
                                  Text(
                                    jobTitle,
                                    style: const TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF96989C),
                                      height: 20 / 14,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Feature tags — only left ~55% so they don't overlap photo
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.50,
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 8,
                                      children: specialist.features
                                          .map(
                                            (f) => _buildFeatureChip(
                                              featureConvert.call(f.toString()),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ======== INFORMATION SECTION ========
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Information heading
                          const Text(
                            'Information',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              height: 24 / 18,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Explanation text
                          _buildExplanationText(explanation, jobTitle),
                          const SizedBox(height: 24),

                          // Info cards row
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.all_inclusive,
                                  title: l10n.coachDetailUnlimitedMemory,
                                  subtitle: l10n.coachDetailMemory,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.translate_rounded,
                                  title: l10n.coachDetailMultilingual,
                                  subtitle: l10n.coachDetailLanguage,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.access_time_rounded,
                                  title: '08:00 - 18:00',
                                  subtitle: l10n.coachDetailAvailability,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // ======== APPOINTMENT SECTION ========
                          Text(
                            l10n.coachDetailAppointment,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              height: 24 / 18,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Appointment card
                          _buildAppointmentCard(),

                          // Bottom padding for floating button
                          SizedBox(height: 80 + bottomPadding),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ======== BOTTOM BAR ========
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: bottomPadding + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Chat icon
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/conversation_page',
                  arguments: specialist,
                );
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E2E2)),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF21BC87),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Start Video Call button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/conversation_page',
                    arguments: specialist,
                  );
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF21BC87),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.coachDetailStartVideoCall,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // HELPER WIDGETS
  // ====================================================================

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF898989).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF555555),
          height: 14 / 11,
        ),
      ),
    );
  }

  Widget _buildExplanationText(String explanation, String jobTitle) {
    // Bold the job title within the explanation
    final escapedJob = RegExp.escape(jobTitle);
    final regex = RegExp(escapedJob, caseSensitive: false);
    final match = regex.firstMatch(explanation);

    if (match != null) {
      final before = explanation.substring(0, match.start);
      final matched = explanation.substring(match.start, match.end);
      final after = explanation.substring(match.end);

      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Color(0xFF96989C),
            height: 18 / 12,
            letterSpacing: -0.12,
          ),
          children: [
            TextSpan(text: before),
            TextSpan(
              text: matched,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: after),
          ],
        ),
      );
    }

    return Text(
      explanation,
      style: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: Color(0xFF96989C),
        height: 18 / 12,
        letterSpacing: -0.12,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF333333)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF96989C),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard() {
    final now = DateTime.now();
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final slots = [
      '08:00',
      '09:40',
      '10:00',
      '12:00',
      '14:00',
      '14:30',
      '15:30',
      '16:00',
      '16:30',
      '17:00',
      '17:30',
      '18:00',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${now.day} ${monthNames[now.month - 1]}, ${dayNames[now.weekday - 1]}day',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time slots
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: List.generate(slots.length, (index) {
              final isSelected = _selectedSlotIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSlotIndex = isSelected ? null : index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF21BC87) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF21BC87)
                          : const Color(0xFFE2E2E2),
                    ),
                  ),
                  child: Text(
                    slots[index],
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF555555),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
