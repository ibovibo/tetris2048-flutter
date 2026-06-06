import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n.dart';

class SeasonInfo {
  final String key;
  final String emoji;
  final String name;
  final Color color;
  const SeasonInfo({required this.key, required this.emoji, required this.name, required this.color});
}

const List<SeasonInfo> kSeasons = [
  SeasonInfo(key:'bomb',       emoji:'🔥', name:'BOMBA',       color:Color(0xFFFF4400)),
  SeasonInfo(key:'ice',        emoji:'❄',  name:'BUZ',         color:Color(0xFF88EEFF)),
  SeasonInfo(key:'gravity',    emoji:'🔄', name:'YERÇEKİMİ',   color:Color(0xFF8844FF)),
  SeasonInfo(key:'chaos',      emoji:'💥', name:'KAOS',        color:Color(0xFFFF4488)),
  SeasonInfo(key:'mystery',    emoji:'❓', name:'GİZEM',       color:Color(0xFF888888)),
  SeasonInfo(key:'darkness',   emoji:'🌑', name:'KARANLIK',    color:Color(0xFF222244)),
  SeasonInfo(key:'evolution',  emoji:'🧬', name:'EVRİM',       color:Color(0xFF44FF88)),
  SeasonInfo(key:'voltage',    emoji:'⚡', name:'VOLTAJ',      color:Color(0xFF00BFFF)),
  SeasonInfo(key:'volcano',    emoji:'🌋', name:'YANARDAĞ',    color:Color(0xFFFF5500)),
];

// ═══════════════════════════════════════════════════════════
// 3 AŞAMA:
//   PHASE 1 (0.0 - 2.5): Patlama + 100k sayaç
//   PHASE 2 (2.5 - 5.0): Slot animasyonu
//   PHASE 3 (5.0 - 6.2): Mevsim bildirimi + solma
// ═══════════════════════════════════════════════════════════
enum _Phase { explosion, slot, announce }

class MaxExplosion {
  _Phase phase = _Phase.explosion;
  double phaseTime = 0;
  bool done = false;
  double displayBonus = 0;
  static const int bonus = 100000;

  // Slot
  int selectedSeason;
  int _spinIndex = 0;
  double _spinTimer = 0;
  double _spinSpeed = 0.055;
  bool slotDone = false;
  static const double _slotDuration = 2.0;

  // Announce
  double _announceTime = 0;
  static const double _announceDuration = 1.2;

  final List<_ExpParticle> _particles = [];
  final math.Random _rng = math.Random();

  MaxExplosion({required this.selectedSeason}) {
    _spawnParticles();
  }

  String _seasonText(String key) => L10n.t('season_$key');

  void _spawnParticles() {
    final cols = [
      const Color(0xFFFFD700), const Color(0xFFFF6FA8),
      const Color(0xFFC87FFF), const Color(0xFF5CF5E0),
      Colors.white, const Color(0xFFFF8833), const Color(0xFF44FF99),
    ];
    for (int i = 0; i < 120; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 3 + _rng.nextDouble() * 9;
      _particles.add(_ExpParticle(
        x: 0.5 + (_rng.nextDouble()-0.5)*0.3,
        y: 0.5 + (_rng.nextDouble()-0.5)*0.3,
        vx: math.cos(angle)*speed*0.012,
        vy: math.sin(angle)*speed*0.012,
        color: cols[_rng.nextInt(cols.length)],
        size: 6 + _rng.nextDouble()*10,
        life: 0.7 + _rng.nextDouble()*0.8,
        isSquare: _rng.nextBool(),
      ));
    }
  }

  void update(double dt) {
    if (done) return;
    phaseTime += dt;
    for (final p in _particles) {
      p.update(dt);
    }

    switch (phase) {
      case _Phase.explosion:
        // Sayaç animasyonu
        final progress = (phaseTime / 2.0).clamp(0.0, 1.0);
        final eased = 1 - math.pow(1 - progress, 3).toDouble();
        displayBonus = bonus * eased;

        if (phaseTime >= 2.5) {
          phase = _Phase.slot;
          phaseTime = 0;
          _spinIndex = _rng.nextInt(kSeasons.length);
        }

      case _Phase.slot:
        _spinTimer += dt;
        final progress = (phaseTime / _slotDuration).clamp(0.0, 1.0);
        // Yavaşlayan spin
        _spinSpeed = (0.055 - progress * 0.050).clamp(0.005, 0.055);
        if (_spinTimer >= _spinSpeed) {
          _spinTimer = 0;
          _spinIndex = (_spinIndex + 1) % kSeasons.length;
        }
        if (phaseTime >= _slotDuration) {
          slotDone = true;
          _spinIndex = selectedSeason;
          phase = _Phase.announce;
          phaseTime = 0;
        }

      case _Phase.announce:
        _announceTime += dt;
        if (_announceTime >= _announceDuration) {
          done = true;
        }
    }
  }

  void render(Canvas canvas, double screenW, double screenH) {
    if (done) return;

    switch (phase) {
      case _Phase.explosion:
        _renderExplosion(canvas, screenW, screenH);
      case _Phase.slot:
        _renderSlot(canvas, screenW, screenH);
      case _Phase.announce:
        _renderAnnounce(canvas, screenW, screenH);
    }
  }

  // ─── PHASE 1: Patlama + 100k sayaç ───────────────────────
  void _renderExplosion(Canvas canvas, double sw, double sh) {
    final t = phaseTime;
    final a = t < 0.2
        ? (t / 0.2).clamp(0.0, 1.0)
        : t > 2.0
            ? (1 - (t-2.0)/0.5).clamp(0.0, 1.0)
            : 1.0;

    final cx = sw/2, cy = sh/2;

    // Arka plan: koyu siyah-mor
    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=const Color(0xFF05020F).withValues(alpha:a*0.95));

    // İlk beyaz flash
    if (t < 0.25) {
      canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
        Paint()..color=Colors.white.withValues(alpha:(1-t/0.25)*0.65));
    }

    // Enerji dalgaları (3 farklı faz)
    for (int i = 0; i < 3; i++) {
      final wave = (t * 0.75 + i * 0.333) % 1.0;
      final r = wave * 290;
      final wA = (1 - wave) * a * 0.55;
      canvas.drawCircle(Offset(cx,cy), r,
        Paint()..color=const Color(0xFF8844FF).withValues(alpha:wA)
               ..style=PaintingStyle.stroke..strokeWidth=2.5);
    }

    // Köşe dönen kristal parçacıkları
    final corners = [Offset(55,105), Offset(sw-55,105), Offset(55,sh-105), Offset(sw-55,sh-105)];
    for (int ci = 0; ci < corners.length; ci++) {
      canvas.save();
      canvas.translate(corners[ci].dx, corners[ci].dy);
      canvas.rotate(t * 1.6 + ci * math.pi / 2);
      canvas.drawRect(Rect.fromCenter(center:Offset.zero, width:20, height:20),
        Paint()..color=const Color(0xFFAA66FF).withValues(alpha:a*0.55)
               ..style=PaintingStyle.stroke..strokeWidth=1.5);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(Rect.fromCenter(center:Offset.zero, width:14, height:14),
        Paint()..color=const Color(0xFFFFD700).withValues(alpha:a*0.45)
               ..style=PaintingStyle.stroke..strokeWidth=1.2);
      canvas.restore();
    }

    // İç içe enerji topu: mor → altın → beyaz
    final pulseR = 1.0 + math.sin(t * math.pi * 3) * 0.08;
    canvas.drawCircle(Offset(cx,cy), 145 * pulseR,
      Paint()..color=const Color(0xFF6600CC).withValues(alpha:a*0.22)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,65));
    canvas.drawCircle(Offset(cx,cy), 88 * pulseR,
      Paint()..color=const Color(0xFFFFD700).withValues(alpha:a*0.32)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,38));
    canvas.drawCircle(Offset(cx,cy), 40 * pulseR,
      Paint()..color=Colors.white.withValues(alpha:a*0.55)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,20));

    // Parçacıklar
    _renderParticles(canvas, sw, sh, a * 0.75);

    // Üst yazı: büyük ödül
    _txt(canvas, L10n.t('big_reward'), cx, cy-100,
      18, const Color(0xFFFFD700).withValues(alpha:a*0.95),
      letterSpacing:5, glow:const Color(0xFFFFAA00));

    // 100k sayaç — her 10k geçişinde nabzeden scale
    final scalePulse = 1.0 + math.exp(-((displayBonus % 10000) / 1500)) * 0.18;
    canvas.save();
    canvas.translate(cx, cy - 12);
    canvas.scale(scalePulse, scalePulse);
    canvas.translate(-cx, -(cy - 12));
    _txt(canvas, '+${displayBonus.toInt()}', cx, cy-12,
      56, const Color(0xFFFFD700).withValues(alpha:a), glow:const Color(0xFFFFBB00));
    canvas.restore();

    // Alt yazı: çark dönüyor (t > 1.75 = 70% of 2.5)
    if (t > 1.75) {
      final fadeIn = ((t - 1.75) / 0.35).clamp(0.0, 1.0);
      _txt(canvas, L10n.t('wheel_spinning'), cx, cy+52,
        13, Colors.white.withValues(alpha:a*fadeIn*0.75), letterSpacing:4);
    }

    // Son an beyaz flash (t >= 2.25 = 90% of 2.5)
    if (t >= 2.25) {
      final flashP = ((t - 2.25) / 0.25).clamp(0.0, 1.0);
      final flashA = flashP < 0.5 ? flashP * 2 : (1 - (flashP-0.5)*2);
      canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
        Paint()..color=Colors.white.withValues(alpha:flashA*0.7));
    }
  }

  // ─── PHASE 2: Slot animasyonu ─────────────────────────────
  void _renderSlot(Canvas canvas, double sw, double sh) {
    final a = phaseTime < 0.25
        ? (phaseTime/0.25).clamp(0.0,1.0)
        : phaseTime > 1.7
            ? (1-(phaseTime-1.7)/0.3).clamp(0.0,1.0)
            : 1.0;

    // Karartma
    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=const Color(0xFF04031A).withValues(alpha:a*0.92));

    _renderParticles(canvas, sw, sh, a*0.4);

    final cx = sw/2, cy = sh/2;
    final season = kSeasons[_spinIndex];
    final progress = (phaseTime / _slotDuration).clamp(0.0, 1.0);

    // Üst başlık
    _txt(canvas, L10n.t('season_selecting'), cx, cy-145,
      13, Colors.white.withValues(alpha:a*0.6), letterSpacing:6);

    // Slot makinesi çerçevesi
    const machineW = 280.0, machineH = 110.0;
    final mx = cx - machineW/2, my = cy - machineH/2 - 10;

    // Dış glow
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(mx-12, my-12, machineW+24, machineH+24),
      const Radius.circular(22)),
      Paint()..color=season.color.withValues(alpha:a*0.25)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,25));

    // Makine arka plan
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(mx, my, machineW, machineH), const Radius.circular(16)),
      Paint()..color=const Color(0xFF06041E).withValues(alpha:a*0.97));

    // Üst/alt renkli bar
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(mx, my, machineW, 6), const Radius.circular(16)),
      Paint()..color=season.color.withValues(alpha:a));
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(mx, my+machineH-6, machineW, 6), const Radius.circular(16)),
      Paint()..color=season.color.withValues(alpha:a*0.7));

    // Makine kenarlık
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(mx, my, machineW, machineH), const Radius.circular(16)),
      Paint()..color=season.color.withValues(alpha:a)
             ..style=PaintingStyle.stroke
             ..strokeWidth=slotDone?3.5:2.0);

    // Dönüş hizalama çizgileri
    if (!slotDone) {
      final lineY = my + machineH/2;
      canvas.drawLine(Offset(mx+8, lineY), Offset(mx+28, lineY),
        Paint()..color=Colors.white.withValues(alpha:a*0.5)..strokeWidth=2);
      canvas.drawLine(Offset(mx+machineW-28, lineY), Offset(mx+machineW-8, lineY),
        Paint()..color=Colors.white.withValues(alpha:a*0.5)..strokeWidth=2);
    }

    // Üst/alt gölge (slot derinlik hissi)
    if (!slotDone) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(mx, my, machineW, machineH*0.22), const Radius.circular(16)),
        Paint()..color=Colors.black.withValues(alpha:0.55));
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(mx, my+machineH*0.78, machineW, machineH*0.22), const Radius.circular(16)),
        Paint()..color=Colors.black.withValues(alpha:0.55));
    }

    // Emoji — büyük
    _txt(canvas, season.emoji, cx-50, my+machineH/2,
      38, season.color.withValues(alpha:a));

    // İsim
    _txt(canvas, _seasonText(season.key), cx+28, my+machineH/2,
      24, season.color.withValues(alpha:a), bold:true);

    // Hız göstergesi (dönüyor mu?)
    if (!slotDone) {
      final spinA = 0.3 + (1-progress)*0.5;
      _txt(canvas, L10n.t('selecting'), cx, my+machineH+22,
        11, Colors.white.withValues(alpha:a*spinA), letterSpacing:4);
    }

    // Kilitlendi göstergesi
    if (slotDone) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(mx, my, machineW, machineH), const Radius.circular(16)),
        Paint()..color=season.color.withValues(alpha:a*0.12));
      _txt(canvas, L10n.t('locked'), cx, my+machineH+22,
        13, season.color.withValues(alpha:a), glow:season.color);
    }

    // Ilerleme çubuğu
    canvas.drawRect(Rect.fromLTWH(cx-110, my-28, 220, 4),
      Paint()..color=Colors.white.withValues(alpha:a*0.15));
    canvas.drawRect(Rect.fromLTWH(cx-110, my-28, 220*progress, 4),
      Paint()..color=season.color.withValues(alpha:a*0.8));
  }

  // ─── PHASE 3: Mevsim bildirimi ────────────────────────────
  void _renderAnnounce(Canvas canvas, double sw, double sh) {
    final t = _announceTime;
    final a = t < 0.2
        ? (t/0.2).clamp(0.0,1.0)
        : t > 0.9
            ? (1-(t-0.9)/0.3).clamp(0.0,1.0)
            : 1.0;

    final season = kSeasons[selectedSeason];
    switch (season.key) {
      case 'bomb':    _renderAnnounceBomb(canvas, sw, sh, a);
      case 'ice':     _renderAnnounceIce(canvas, sw, sh, a);
      case 'gravity': _renderAnnounceGravity(canvas, sw, sh, a);
      case 'double_vision': _renderAnnounceDoubleVision(canvas, sw, sh, a);
      case 'chaos':   _renderAnnounceChaos(canvas, sw, sh, a);
      case 'mystery': _renderAnnounceMystery(canvas, sw, sh, a);
      default:        _renderAnnounceDefault(canvas, sw, sh, a);
    }
  }

  void _renderAnnounceBomb(Canvas canvas, double sw, double sh, double a) {
    final cx = sw/2, cy = sh/2;
    final t = _announceTime;
    final pulse = math.sin(t * math.pi * 8) * 0.5 + 0.5;

    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=const Color(0xFF1A0000).withValues(alpha:a*0.95));

    for (final corner in [Offset(0,0), Offset(sw,0), Offset(0,sh), Offset(sw,sh)]) {
      canvas.drawCircle(corner, 200,
        Paint()..color=const Color(0xFFFF2200).withValues(alpha:a*0.18)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,80));
    }

    final alarmA = a * (0.4 + pulse * 0.6);
    canvas.drawRect(Rect.fromLTWH(0, 0, sw, 8),
      Paint()..color=const Color(0xFFFF0000).withValues(alpha:alarmA));
    canvas.drawRect(Rect.fromLTWH(0, sh-8, sw, 8),
      Paint()..color=const Color(0xFFFF0000).withValues(alpha:alarmA));

    canvas.drawCircle(Offset(cx,cy), 160,
      Paint()..color=const Color(0xFFFF4400).withValues(alpha:a*0.25)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,55));

    for (int i = 0; i < 8; i++) {
      final angle = t * 2.0 + i * math.pi / 4;
      final fx = cx + math.cos(angle) * 90;
      final fy = cy + math.sin(angle) * 90;
      canvas.drawCircle(Offset(fx, fy), 6,
        Paint()..color=const Color(0xFFFF6600).withValues(alpha:a*0.9));
      canvas.drawCircle(Offset(fx, fy), 10,
        Paint()..color=const Color(0xFFFF2200).withValues(alpha:a*0.3)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
    }

    _txt(canvas, '💣', cx, cy-40, 72, Colors.white.withValues(alpha:a));

    final textA = a * (0.7 + pulse * 0.3);
    _txt(canvas, L10n.t('season_bomb'), cx, cy+52,
      26, const Color(0xFFFF4400).withValues(alpha:textA), bold:true, glow:const Color(0xFFFF2200));
    _txt(canvas, L10n.t('season_starting'), cx, cy+90,
      14, const Color(0xFFFF8800).withValues(alpha:textA*0.9), letterSpacing:8);
  }

  void _renderAnnounceIce(Canvas canvas, double sw, double sh, double a) {
    final cx = sw/2, cy = sh/2;
    final t = _announceTime;

    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=const Color(0xFF00071A).withValues(alpha:a*0.95));

    canvas.drawCircle(Offset(cx,cy), 180,
      Paint()..color=const Color(0xFF0088CC).withValues(alpha:a*0.18)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,60));

    final icicleRng = math.Random(42);
    for (int i = 0; i < 12; i++) {
      final x = (sw / 11) * i + 10.0;
      final h = 20.0 + icicleRng.nextDouble() * 50.0;
      final w = 6.0 + icicleRng.nextDouble() * 8.0;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w/2, 0, w, h), const Radius.circular(3)),
        Paint()..color=const Color(0xFF88EEFF).withValues(alpha:a*0.7));
    }

    final crystalPaint = Paint()
      ..color=const Color(0xFF88EEFF).withValues(alpha:a*0.6)
      ..strokeWidth=1.5..style=PaintingStyle.stroke;
    for (final corner in [Offset(60,80), Offset(sw-60,80), Offset(60,sh-80), Offset(sw-60,sh-80)]) {
      canvas.save();
      canvas.translate(corner.dx, corner.dy);
      for (int k = 0; k < 6; k++) {
        final angle = k * math.pi / 3;
        canvas.drawLine(Offset.zero, Offset(math.cos(angle)*28, math.sin(angle)*28), crystalPaint);
      }
      canvas.restore();
    }

    canvas.save();
    canvas.translate(cx, cy-40);
    canvas.rotate(t * 0.8);
    canvas.translate(-cx, -(cy-40));
    _txt(canvas, '❄', cx, cy-40, 72, const Color(0xFF88EEFF).withValues(alpha:a),
      glow:const Color(0xFF44AAFF));
    canvas.restore();

    _txt(canvas, L10n.t('season_ice'), cx, cy+50,
      26, const Color(0xFF88EEFF).withValues(alpha:a), bold:true, glow:const Color(0xFF44AAFF));
    _txt(canvas, L10n.t('season_starting'), cx, cy+88,
      14, Colors.white.withValues(alpha:a*0.8), letterSpacing:8);
  }

  void _renderAnnounceGravity(Canvas canvas, double sw, double sh, double a) {
    final cx = sw/2, cy = sh/2;
    final t = _announceTime;
    final pulse = math.sin(t * math.pi * 5) * 0.5 + 0.5;

    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=const Color(0xFF0A0015).withValues(alpha:a*0.95));

    final starRng = math.Random(17);
    for (int i = 0; i < 40; i++) {
      final sx = starRng.nextDouble() * sw;
      final sy = starRng.nextDouble() * sh;
      final sr = 1.0 + starRng.nextDouble() * 2.0;
      canvas.drawCircle(Offset(sx,sy), sr,
        Paint()..color=Colors.white.withValues(alpha:a*(0.3+starRng.nextDouble()*0.5)));
    }

    canvas.drawCircle(Offset(cx,cy), 170,
      Paint()..color=const Color(0xFF8844FF).withValues(alpha:a*0.20)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,55));

    canvas.save();
    canvas.translate(cx, cy-20);
    canvas.rotate(t * 0.6);
    canvas.translate(-cx, -(cy-20));
    canvas.drawOval(Rect.fromCenter(center:Offset(cx,cy-20), width:220, height:80),
      Paint()..color=const Color(0xFF8844FF).withValues(alpha:a*0.5)
             ..style=PaintingStyle.stroke..strokeWidth=1.5);
    canvas.restore();

    _txt(canvas, '▲', cx, cy-118,
      22, const Color(0xFF8844FF).withValues(alpha:a*(0.5+pulse*0.5)));
    _txt(canvas, '🔄', cx, cy-42, 68, Colors.white.withValues(alpha:a));
    _txt(canvas, '▼', cx, cy+48,
      22, const Color(0xFF8844FF).withValues(alpha:a*(0.5+pulse*0.5)));

    _txt(canvas, L10n.t('season_gravity'), cx, cy+78,
      22, const Color(0xFFAA88FF).withValues(alpha:a), bold:true, glow:const Color(0xFF8844FF));
    _txt(canvas, L10n.t('season_starting'), cx, cy+112,
      14, Colors.white.withValues(alpha:a*0.8), letterSpacing:8);
  }

  void _renderAnnounceDoubleVision(Canvas canvas, double sw, double sh, double a) {
    final cx = sw/2, cy = sh/2;
    final t = _announceTime;

    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=const Color(0xFF0A000F).withValues(alpha:a*0.95));

    // Çift göz arka ışıması — sol ve sağ
    for (final sign in [-1.0, 1.0]) {
      final ex = cx + sign * 60;
      canvas.drawCircle(Offset(ex,cy-36), 80,
        Paint()..color=const Color(0xFFFF44FF).withValues(alpha:a*0.14)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,40));
    }

    // Titreşen / çift-görme tarama çizgileri
    for (int i = 0; i < 7; i++) {
      final lineY = cy - 90 + i * 32.0;
      final hShift = math.sin(t * 6.0 + i * 0.8) * 4.0;
      canvas.drawLine(
        Offset(cx - 100 + hShift, lineY),
        Offset(cx + 100 + hShift, lineY),
        Paint()..color = const Color(0xFFFF88FF).withValues(alpha: a * 0.18)
               ..strokeWidth = 1.2,
      );
    }

    // Gölge/ikiz göz ikonu — hafif kaymış
    final shift = math.sin(t * 4.0) * 5.0;
    _txt(canvas, '👁', cx - shift, cy-42, 68,
      const Color(0xFFFF44FF).withValues(alpha:a*0.55));
    _txt(canvas, '👁', cx + shift, cy-42, 68,
      Colors.white.withValues(alpha:a));

    _txt(canvas, L10n.t('season_double_vision'), cx, cy+50,
      24, const Color(0xFFFF88FF).withValues(alpha:a), bold:true, glow:const Color(0xFFDD00DD));
    _txt(canvas, L10n.t('season_starting'), cx, cy+88,
      14, Colors.white.withValues(alpha:a*0.8), letterSpacing:8);
  }

  void _renderAnnounceChaos(Canvas canvas, double sw, double sh, double a) {
    final cx = sw/2, cy = sh/2;
    final t = _announceTime;

    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=Colors.black.withValues(alpha:a*0.95));

    final blockRng = math.Random(99);
    final blockColors = [
      const Color(0xFFFF0066), const Color(0xFF00FFAA), const Color(0xFFFFFF00),
      const Color(0xFF0088FF), const Color(0xFFFF8800), const Color(0xFFCC00FF),
    ];
    for (int i = 0; i < 18; i++) {
      final bx = blockRng.nextDouble() * sw;
      final by = blockRng.nextDouble() * sh;
      final bw = 14.0 + blockRng.nextDouble() * 22.0;
      final col = blockColors[blockRng.nextInt(blockColors.length)];
      canvas.drawRect(Rect.fromCenter(center:Offset(bx,by), width:bw, height:bw),
        Paint()..color=col.withValues(alpha:a*0.25));
      canvas.drawRect(Rect.fromCenter(center:Offset(bx,by), width:bw, height:bw),
        Paint()..color=col.withValues(alpha:a*0.4)
               ..style=PaintingStyle.stroke..strokeWidth=1);
    }

    final waveColors = [const Color(0xFFFF0044), const Color(0xFF00FFAA), const Color(0xFFFFFF00)];
    for (int i = 0; i < 3; i++) {
      final phase = (t * 1.5 + i * 0.33) % 1.0;
      final waveA = (1 - phase) * a * 0.6;
      canvas.drawCircle(Offset(cx,cy), phase * 200,
        Paint()..color=waveColors[i].withValues(alpha:waveA)
               ..style=PaintingStyle.stroke..strokeWidth=3);
    }

    _txt(canvas, '💥', cx, cy-42, 72, Colors.white.withValues(alpha:a));

    final label = L10n.t('season_chaos');
    final rainbowCols = [
      const Color(0xFFFF0000), const Color(0xFFFF8800), const Color(0xFFFFFF00),
      const Color(0xFF00FF00), const Color(0xFF00FFFF), const Color(0xFF0088FF),
      const Color(0xFFCC00FF), const Color(0xFFFF0088),
    ];
    final measureTp = TextPainter(
      text:TextSpan(text:label, style:const TextStyle(fontFamily:'monospace', fontSize:26, fontWeight:FontWeight.bold)),
      textDirection:TextDirection.ltr,
    )..layout();
    double lx = cx - measureTp.width / 2;
    for (int i = 0; i < label.length; i++) {
      final col = rainbowCols[i % rainbowCols.length];
      final ltp = TextPainter(
        text:TextSpan(text:label[i], style:TextStyle(
          fontFamily:'monospace', fontSize:26, fontWeight:FontWeight.bold,
          color:col.withValues(alpha:a),
          shadows:[Shadow(color:col.withValues(alpha:a*0.8), blurRadius:14)],
        )),
        textDirection:TextDirection.ltr,
      )..layout();
      ltp.paint(canvas, Offset(lx, cy+48 - ltp.height/2));
      lx += ltp.width;
    }

    _txt(canvas, L10n.t('season_starting'), cx, cy+88,
      14, Colors.white.withValues(alpha:a*0.8), letterSpacing:8);
  }

  void _renderAnnounceMystery(Canvas canvas, double sw, double sh, double a) {
    final cx = sw/2, cy = sh/2;
    final t = _announceTime;

    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=const Color(0xFF08000F).withValues(alpha:a*0.95));

    canvas.drawRect(Rect.fromLTWH(cx-80, 0, 160, sh*0.7),
      Paint()..color=Colors.white.withValues(alpha:a*0.03)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,40));

    canvas.drawCircle(Offset(cx,cy), 160,
      Paint()..color=const Color(0xFF8800CC).withValues(alpha:a*0.20)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,55));

    final qRng = math.Random(55);
    for (int i = 0; i < 12; i++) {
      final qx = qRng.nextDouble() * sw;
      final qy = qRng.nextDouble() * sh;
      final qA = 0.15 + qRng.nextDouble() * 0.35;
      _txt(canvas, '?', qx, qy, 16,
        const Color(0xFF9944FF).withValues(alpha:a*qA), bold:false);
    }

    _txt(canvas, '❓', cx, cy-40, 72, Colors.white.withValues(alpha:a));

    canvas.save();
    canvas.translate(cx+45, cy-35);
    canvas.rotate(t * 1.2);
    final glassPaint = Paint()
      ..color=const Color(0xFF9944FF).withValues(alpha:a*0.7)
      ..style=PaintingStyle.stroke..strokeWidth=2.5;
    canvas.drawCircle(Offset.zero, 20, glassPaint);
    canvas.drawLine(const Offset(14, 14), const Offset(26, 26),
      glassPaint..strokeWidth=3);
    canvas.restore();

    _txt(canvas, L10n.t('season_mystery'), cx, cy+50,
      26, const Color(0xFFAA44FF).withValues(alpha:a), bold:true, glow:const Color(0xFF8800CC));
    _txt(canvas, L10n.t('season_starting'), cx, cy+88,
      14, Colors.white.withValues(alpha:a*0.8), letterSpacing:8);
  }

  void _renderAnnounceDefault(Canvas canvas, double sw, double sh, double a) {
    final cx = sw/2, cy = sh/2;
    final season = kSeasons[selectedSeason];
    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=const Color(0xFF04031A).withValues(alpha:a*0.85));
    canvas.drawCircle(Offset(cx,cy), 200,
      Paint()..color=season.color.withValues(alpha:a*0.20)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,60));
    _txt(canvas, season.emoji, cx, cy-60, 64, season.color.withValues(alpha:a));
    _txt(canvas, _seasonText(season.key), cx, cy+20,
      28, season.color.withValues(alpha:a), bold:true, glow:season.color);
    _txt(canvas, L10n.t('season_starting'), cx, cy+60,
      14, Colors.white.withValues(alpha:a*0.8), letterSpacing:8);
  }

  void _renderParticles(Canvas canvas, double sw, double sh, double alpha) {
    for (final p in _particles) {
      if (p.life <= 0) continue;
      final a = (p.life * alpha).clamp(0.0, 1.0);
      final sz = p.size * p.life.clamp(0.3, 1.0);
      final cx = sw*p.x, cy = sh*p.y;
      final paint = Paint()..color=p.color.withValues(alpha:a);
      if (p.isSquare) {
        canvas.drawRect(Rect.fromCenter(center:Offset(cx,cy),width:sz,height:sz),paint);
      } else {
        canvas.drawCircle(Offset(cx,cy),sz/2,paint);
      }
      if (sz > 5) {
        canvas.drawCircle(Offset(cx,cy),sz,
        Paint()..color=p.color.withValues(alpha:a*0.22)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,6));
      }
    }
  }

  void _txt(Canvas canvas, String text, double cx, double cy,
      double size, Color color, {Color? glow, bool bold=true, double letterSpacing=0}) {
    final shadows = <Shadow>[
      Shadow(color:Colors.black.withValues(alpha:0.95), blurRadius:6, offset:const Offset(0,3)),
    ];
    if (glow != null) {
      shadows.add(Shadow(color:glow, blurRadius:16));
      shadows.add(Shadow(color:glow, blurRadius:32));
    }
    final tp = TextPainter(
      text:TextSpan(text:text, style:TextStyle(
        fontFamily:'monospace', fontSize:size,
        fontWeight:bold?FontWeight.bold:FontWeight.normal,
        color:color, letterSpacing:letterSpacing, shadows:shadows,
      )),
      textDirection:TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx-tp.width/2, cy-tp.height/2));
  }
}

class _ExpParticle {
  double x, y, vx, vy, life, size;
  Color color; bool isSquare;
  _ExpParticle({required this.x, required this.y, required this.vx, required this.vy,
    required this.color, required this.size, required this.life, required this.isSquare});
  void update(double dt) {
    x+=vx; y+=vy; vy+=0.0002;
    vx*=0.97; vy*=0.97; life-=dt*0.65;
  }
}