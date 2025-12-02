import 'package:flutter/material.dart';

class ReusableGradientButton extends StatelessWidget {
  // Dışarıdan alınacak zorunlu parametreler
  final String buttonText;
  final VoidCallback onPressed; // Tıklama işlevi için standart tip

  const ReusableGradientButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Gradient Renkleri
    const Color startColor = Color(0xFF2cd283); // Açık yeşil/mavi
    const Color endColor = Color(0xFF139c8d);   // Koyu yeşil/mavi

    // Butonun Genişliği (Resimdeki butona daha yakın olması için)
    const double horizontalPadding = 100.0;
    const double verticalPadding = 6.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: endColor.withValues(alpha: 0.5),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Dışarıdan alınan tıklama işlevi atanır
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Text(
              buttonText, // Dışarıdan alınan metin kullanılır
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

