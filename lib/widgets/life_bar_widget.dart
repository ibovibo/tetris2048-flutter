import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n.dart';

class LifeBarWidget extends StatelessWidget {
  final int currentLives; // mevcut can (0-3)
  final int maxLives; // maksimum can (3)
  final Duration? timeToNext; // sonraki cana kalan süre (max ise null)

  const LifeBarWidget({
    required this.currentLives,
    this.maxLives = 3,
    this.timeToNext,
    super.key,
  });

  bool get _isMax => currentLives >= maxLives;

  String get _timeText {
    final t = timeToNext;
    if (_isMax || t == null) return '';
    final totalSeconds = t.inSeconds.clamp(0, 999 * 60);
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1223 / 597,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/canbari.png',
                  fit: BoxFit.fill,
                ),
              ),

              // Can sayısı (üst kutu, hafif sağ üste kaydırılmış)
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(
                    0.78 * 2 - 1,
                    0.28 * 2 - 1,
                  ),
                  child: _isMax
                      ? SizedBox(
                          width: h * 0.75,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _outlinedText(
                              L10n.t('life_max'),
                              fontSize: h * 0.20,
                              color: const Color(0xFFFFD54A),
                            ),
                          ),
                        )
                      : RichText(
                          textScaler: TextScaler.noScaling,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '×',
                                style: _numberStyle(
                                  fontSize: h * 0.20,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: '$currentLives',
                                style: _numberStyle(
                                  fontSize: h * 0.20,
                                  color: const Color(0xFFFFD54A),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // Yenilenme süresi (alt kutu, saat ikonunun sağı) — dolu iken "FULL"
              Positioned.fill(
                child: Align(
                  alignment: _isMax
                      ? const Alignment(
                          0.83 * 2 - 1,
                          0.71 * 2 - 1,
                        )
                      : const Alignment(
                          0.777 * 2 - 1,
                          0.685 * 2 - 1,
                        ),
                  child: SizedBox(
                    width: h * (_isMax ? 0.55 : 0.75),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _isMax ? L10n.t('life_full') : _timeText,
                        textScaler: TextScaler.noScaling,
                        style: GoogleFonts.poppins(
                          fontSize: _isMax ? h * 0.1265 : h * 0.115,
                          fontWeight:
                              _isMax ? FontWeight.w900 : FontWeight.w700,
                          color: const Color(0xFFFDF6E3),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
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

  TextStyle _numberStyle({required double fontSize, required Color color}) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: color,
      height: 1.0,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
        Shadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  Widget _outlinedText(
    String text, {
    required double fontSize,
    required Color color,
  }) {
    return Text(
      text,
      textScaler: TextScaler.noScaling,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: color,
        height: 1.0,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }
}
