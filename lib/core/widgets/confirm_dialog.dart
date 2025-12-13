import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = '',
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Tasarım 267px genişlik → ekranda %80 civarı, ama çok da büyümesin
    final dialogWidth = (screenWidth * 0.7).clamp(260.0, 320.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          // Yükseklik sabit değil, içerik kadar
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20), // radius: 20px
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20, // Figma: 20
                  fontWeight: FontWeight.w700, // Bold
                  height: 34 / 20, // line-height: 34px
                  letterSpacing: 0,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),

              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14, // Figma: 14
                    fontWeight: FontWeight.w400, // Regular
                    height: 16 / 14, // line-height: 16px
                    letterSpacing: 0,
                    color: const Color(0xFF717171),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 32.h, // tasarım 32px
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9), // Cancel bg
                          borderRadius: BorderRadius.circular(20), // 20px
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cancelText,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: Container(
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: confirmColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          confirmText,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dışarıdan kolay çağırmak için helper
Future<void> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmText,
  String? cancelText,
  required Color confirmColor,
  required VoidCallback onConfirm,
}) {
  final l10n = context.l10n;
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText ?? l10n.cancel,
      confirmColor: confirmColor,
      onConfirm: onConfirm,
    ),
  );
}
