import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n.dart';
import '../life_manager.dart';

class NoLivesPopup extends StatefulWidget {
  final VoidCallback onWatchAd;
  final VoidCallback onBuyPremium;
  final VoidCallback onClose;

  const NoLivesPopup({
    required this.onWatchAd,
    required this.onBuyPremium,
    required this.onClose,
    super.key,
  });

  @override
  State<NoLivesPopup> createState() => _NoLivesPopupState();
}

class _NoLivesPopupState extends State<NoLivesPopup> {
  Timer? _timer;
  Duration? _timeLeft;

  @override
  void initState() {
    super.initState();
    _timeLeft = LifeManager.timeToNextLife();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (LifeManager.hasLife) {
        // Can yenilendi — artık oynanabilir, popup'ı otomatik kapat
        _timer?.cancel();
        Navigator.of(context).maybePop();
        return;
      }
      setState(() => _timeLeft = LifeManager.timeToNextLife());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeText {
    final t = _timeLeft;
    if (t == null) return '00:00';
    final totalSeconds = t.inSeconds.clamp(0, 999 * 60);
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  // 8 karakterden sonra her karakter için font boyutu %5 küçülür
  // (uzun çeviriler için taşmayı önler).
  double _scaledFontSize(
    String text,
    double baseFontSize, {
    int afterChars = 8,
    double perCharFactor = 0.95,
  }) {
    final extraChars = text.length > afterChars ? text.length - afterChars : 0;
    return extraChars > 0
        ? baseFontSize * pow(perCharFactor, extraChars).toDouble()
        : baseFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 783 / 1381,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/yetersizcann.png',
                  fit: BoxFit.fill,
                ),
              ),

              // X kapat butonu
              Positioned(
                left: w * 0.911 - h * 0.038,
                top: h * 0.144 - h * 0.038,
                width: h * 0.076,
                height: h * 0.076,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onClose,
                ),
              ),

              // "OPSSS!"
              _centeredText(
                w,
                h,
                xPct: 0.501,
                yPct: 0.218,
                text: L10n.t('no_lives_oops'),
                fontSize: h * 0.09108,
                color: Colors.white,
                boxWidthFactor: 0.7,
              ),

              // "CANIN BİTMİŞ!" — kırmızı-turuncu gradient
              _centeredText(
                w,
                h,
                xPct: 0.501,
                yPct: 0.314,
                text: L10n.t('no_lives_title'),
                fontSize: h * 0.060,
                color: Colors.white,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3D3D), Color(0xFFFF9138)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxWidthFactor: 0.86,
              ),

              // "ŞİMDİ HEMEN YENİLE!"
              _centeredText(
                w,
                h,
                xPct: 0.501,
                yPct: 0.379,
                text: L10n.t('no_lives_subtitle'),
                fontSize: h * 0.030,
                weight: FontWeight.w700,
                color: const Color(0xFFBEE3FF),
                boxWidthFactor: 0.8,
              ),

              // "Yeni can için:"
              _text(
                w,
                h,
                xPct: 0.84,
                yPct: 0.490,
                text: L10n.t('no_lives_next_life_label'),
                fontSize: _scaledFontSize(
                  L10n.t('no_lives_next_life_label'),
                  h * 0.023,
                  afterChars: 13,
                  perCharFactor: 0.98,
                ),
                weight: FontWeight.w600,
                color: const Color(0xFFBEE3FF),
                boxWidthFactor: 0.5,
              ),

              // "04:32" — canlı süre
              _text(
                w,
                h,
                xPct: 0.82,
                yPct: 0.537,
                text: _timeText,
                fontSize: h * 0.034,
                weight: FontWeight.w800,
                color: const Color(0xFFFDF6E3),
                boxWidthFactor: 0.4,
              ),

              // Reklam butonu (sarı) — tıklama alanı
              Positioned(
                left: w * 0.07,
                top: h * 0.585,
                width: w * 0.86,
                height: h * 0.165,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onWatchAd,
                ),
              ),
              _text(
                w,
                h,
                xPct: 0.691,
                yPct: 0.671,
                text: L10n.t('no_lives_watch_ad'),
                fontSize: _scaledFontSize(
                  L10n.t('no_lives_watch_ad'),
                  h * 0.034,
                ),
                weight: FontWeight.w800,
                color: Colors.white,
                boxWidthFactor: 0.55,
              ),
              _text(
                w,
                h,
                xPct: 0.616,
                yPct: 0.710,
                text: L10n.t('no_lives_plus_one'),
                fontSize: h * 0.022,
                weight: FontWeight.w700,
                color: Colors.white,
                boxWidthFactor: 0.4,
              ),

              // "VEYA"
              _centeredText(
                w,
                h,
                xPct: 0.501,
                yPct: 0.789,
                text: L10n.t('no_lives_or'),
                fontSize: h * 0.022,
                weight: FontWeight.w600,
                color: const Color(0xFFBEE3FF),
                boxWidthFactor: 0.4,
              ),

              // Premium butonu (mavi) — tıklama alanı
              Positioned(
                left: w * 0.07,
                top: h * 0.805,
                width: w * 0.86,
                height: h * 0.150,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onBuyPremium,
                ),
              ),
              _text(
                w,
                h,
                xPct: 0.70,
                yPct: 0.862,
                text: L10n.t('no_lives_premium'),
                fontSize: _scaledFontSize(
                  L10n.t('no_lives_premium'),
                  h * 0.034,
                ),
                weight: FontWeight.w800,
                color: const Color(0xFF1E3A5F),
                boxWidthFactor: 0.55,
                shadowColor: Colors.white.withValues(alpha: 0.35),
              ),
              _text(
                w,
                h,
                xPct: 0.558,
                yPct: 0.898,
                text: L10n.t('no_lives_unlimited'),
                fontSize: _scaledFontSize(
                  L10n.t('no_lives_unlimited'),
                  h * 0.020,
                  afterChars: 15,
                ),
                weight: FontWeight.w700,
                color: const Color(0xFFFFD54A),
                boxWidthFactor: 0.5,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _centeredText(
    double w,
    double h, {
    required double xPct,
    required double yPct,
    required String text,
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w900,
    Gradient? gradient,
    double boxWidthFactor = 0.8,
  }) {
    final content = Text(
      text,
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: weight,
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
          ),
        ],
      ),
    );

    return Positioned.fill(
      child: Align(
        alignment: Alignment(xPct * 2 - 1, yPct * 2 - 1),
        child: SizedBox(
          width: w * boxWidthFactor,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: gradient == null
                ? content
                : ShaderMask(
                    shaderCallback: (bounds) => gradient.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: content,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _text(
    double w,
    double h, {
    required double xPct,
    required double yPct,
    required String text,
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w700,
    double boxWidthFactor = 0.5,
    Color? shadowColor,
  }) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment(xPct * 2 - 1, yPct * 2 - 1),
        child: SizedBox(
          width: w * boxWidthFactor,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: weight,
                color: color,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: shadowColor ?? Colors.black.withValues(alpha: 0.4),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
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
