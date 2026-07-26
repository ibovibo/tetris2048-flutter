import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../daily_quest_data.dart' show formatShortNumber;

/// Alt sayaç görsellerinin (altınsayac.png / elmassayac.png) ortasındaki
/// bej kutuya sayı basan genel amaçlı saya widget'ı.
class CurrencyCounterWidget extends StatelessWidget {
  final String assetPath;
  final int value;
  final Color textColor;
  // Bej kutunun görsel içindeki konumu (0..1 aralığında, sol/üst/sağ/alt).
  final double boxLeft;
  final double boxTop;
  final double boxRight;
  final double boxBottom;
  // Sayının bej kutu içindeki hizalanışı (-1..1, sol/üst - sağ/alt).
  final Alignment textAlignment;
  // Sayı font boyutu çarpanı (1.0 = varsayılan).
  final double fontScale;

  const CurrencyCounterWidget({
    required this.assetPath,
    required this.value,
    required this.textColor,
    required this.boxLeft,
    required this.boxTop,
    required this.boxRight,
    required this.boxBottom,
    this.textAlignment = const Alignment(0.6, 0),
    this.fontScale = 1.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 700 / 294,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          // FittedBox(scaleDown) metni bu kutunun boyutuna sıkıştırır; fontScale
          // sadece fontSize'ı büyütürse kutu aynı kaldığı için görsel etkisi
          // olmaz — bu yüzden kutuyu da merkezi sabit kalacak şekilde büyütüyoruz.
          final centerXFrac = (boxLeft + boxRight) / 2;
          final centerYFrac = (boxTop + boxBottom) / 2;
          final scaledWFrac = (boxRight - boxLeft) * fontScale;
          final scaledHFrac = (boxBottom - boxTop) * fontScale;
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(assetPath, fit: BoxFit.fill),
              ),
              Positioned(
                left: w * (centerXFrac - scaledWFrac / 2),
                top: h * (centerYFrac - scaledHFrac / 2),
                width: w * scaledWFrac,
                height: h * scaledHFrac,
                // Not: Sayı kutunun genişliğini/yüksekliğini aştığında
                // scaleDown onu kutuya tam oturtuyor ve o eksende hiç boşluk
                // kalmıyor — bu yüzden "alignment" (Align/FittedBox.alignment)
                // taşma olan eksende asla iş görmez. Bunun yerine metni düz
                // bir piksel miktarıyla kaydırıyoruz (Transform.translate),
                // bu her durumda çalışır.
                child: Transform.translate(
                  offset: Offset(
                    w * scaledWFrac / 2 * textAlignment.x,
                    h * scaledHFrac / 2 * textAlignment.y,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatShortNumber(value),
                      textScaler: TextScaler.noScaling,
                      style: GoogleFonts.poppins(
                        fontSize: h * 0.4 * fontScale,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
