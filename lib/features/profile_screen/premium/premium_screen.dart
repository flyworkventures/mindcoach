import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // 0 = Annual, 1 = Monthly
  int _selectedPlan = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // BACKGROUND IMAGE
          Positioned.fill(
            top: 0,
            bottom: -10.h,
            child: Image.asset(
              'assets/images/get_premium.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xFF000000),
                    ],
                    stops: [0.0, 0.93],
                  ),
                ),
              ),
            ),
          ),
          // CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ÜST BAR: back + Mind Coach
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/svg/arrow_back.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Mind Coach',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: -0.1, // -10%
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 34),
                    ],
                  ),

                  SizedBox(height: 36.h),

                  // Başlık (2 satır)
                  Text(
                    'Try Mind Coach Premium\nfree for 1 week',
                    style: GoogleFonts.quicksand(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 30 / 24,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Alt açıklama
                  Text(
                    'Get unlimited access and take\nadvantage of opportunities',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 22 / 15,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Feature list
                  _FeatureRow(text: 'Skip Ads'),
                  _FeatureRow(text: 'Unlimited Character Selection'),
                  _FeatureRow(text: 'Expanded memory and context'),
                  _FeatureRow(text: 'With advanced reasoning capabilities'),
                  SizedBox(height: 32.h),

                  // Plan kartları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PlanCard(
                        title: 'Annual',
                        oldPrice: '\$107.88',
                        price: '\$79.99',
                        subtitle: 'per year after 7 days trial',
                        isSelected: _selectedPlan == 0,
                        showSaveBadge: true,
                        onTap: () {
                          setState(() => _selectedPlan = 0);
                        },
                      ),
                      SizedBox(width: 16.w),
                      _PlanCard(
                        title: 'Monthly',
                        oldPrice: null,
                        price: '\$8.99',
                        subtitle: 'per year after 7 days trial',
                        isSelected: _selectedPlan == 1,
                        showSaveBadge: false,
                        onTap: () {
                          setState(() => _selectedPlan = 1);
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Start trial button
                  GestureDetector(
                    onTap: () {
                      // TODO: purchase flow
                    },
                    child: Container(
                      width: double.infinity,
                      height: 44.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: const LinearGradient(
                          begin: Alignment(-0.3, 0),
                          end: Alignment(1.0, 0),
                          colors: [
                            Color(0xFF2BD383),
                            Color(0xFF11998E),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'start 1 week free trial',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Alttaki açıklama
                  Text(
                    "You’ll be charged \$8.99 per month after your 7 day free trial ends. You can cancel anytime.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 14 / 11,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Divider
                  Center(
                    child: Container(
                      width: 268.w,
                      height: 1,
                      color: const Color(0xFFBABABA),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Footer links
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8.w,
                      children: [
                        _FooterText('Restore purchase'),
                        _FooterDot(),
                        _FooterText('Terms of Use'),
                        _FooterDot(),
                        _FooterText('Privacy Policy'),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature satırı (check ikon + text)
class _FeatureRow extends StatelessWidget {
  final String text;

  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/svg/check_icon.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 30 / 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plan kartı (Annual / Monthly)
/// Plan kartı (Annual / Monthly)
class _PlanCard extends StatelessWidget {
  final String title;
  final String? oldPrice;
  final String price;
  final String subtitle;
  final bool isSelected;
  final bool showSaveBadge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.oldPrice,
    required this.price,
    required this.subtitle,
    required this.isSelected,
    required this.showSaveBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseWidth = 130.w;   // Figma ~125
    final baseHeight = 152.h;  // Figma ~152

    // Badge component (tek yerde kullanabilelim diye)
    Widget buildBadge() {
      return Container(
        height: 23.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: const LinearGradient(
            begin: Alignment(-0.3, 0),
            end: Alignment(1.0, 0),
            colors: [
              Color(0xFF2BD383),
              Color(0xFF11998E),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'SAVE 17%',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }

    final isMonthly = title.toLowerCase() == 'monthly';

    // İçerik (badge HARİÇ)
    Widget buildInnerContent() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 30 / 12,
              color: Colors.black,
            ),
          ),

          if (oldPrice != null) ...[
            SizedBox(height: 2.h),
            Text(
              oldPrice!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.lineThrough,
                height: 30 / 11,
                color: Colors.grey.shade600,
              ),
            ),
          ] else

          // Fiyat
          Text(
            price,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          // Alt açıklama
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 14 / 11,
              color: Colors.black87,
            ),
          ),

          // Badge için biraz boşluk (Annual kartta alttan taşıracağız)
          if (showSaveBadge) SizedBox(height: 18.h),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: isMonthly
      // ---------------- MONTHLY: GRADIENT BORDER ----------------
          ? Container(
        width: baseWidth,
        height: baseHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD8D8D8),
              Color(0xFF878787),
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2), // 2px border kalınlığı
          padding: EdgeInsets.symmetric(
            horizontal: 10.w,
            vertical: 10.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: buildInnerContent(),
        ),
      )

      // ---------------- ANNUAL: NORMAL BORDER + FLOATING BADGE ----------------
          : Container(
        width: baseWidth,
        height: baseHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2BD383)
                : Colors.white.withOpacity(0.6),
            width: 2,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none, // dışarı taşsın ama overflow hatası olmasın
          children: [
            // İçerik
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 10.h,
              ),
              child: buildInnerContent(),
            ),

            // SAVE 17% badge – alt çizgiye yapışık / biraz dışarı
            if (showSaveBadge)
              Positioned(
                left: 0,
                right: 0,
                bottom: -12.h, // 0 = tam içeride, negatif = dışarı taşır
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: buildBadge(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
/// Footer metni
class _FooterText extends StatelessWidget {
  final String label;

  const _FooterText(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 30 / 11,
        color: const Color(0xFF999797),
      ),
    );
  }
}

/// Footer arası küçük nokta
class _FooterDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFFD9D9D9),
        shape: BoxShape.circle,
      ),
    );
  }
}
