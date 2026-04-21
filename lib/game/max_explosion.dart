import 'dart:math' as math;
import 'package:flutter/material.dart';

class SeasonInfo {
  final String key;
  final String emoji;
  final String name;
  final Color color;
  const SeasonInfo({required this.key, required this.emoji, required this.name, required this.color});
}

const List<SeasonInfo> kSeasons = [
  SeasonInfo(key:'bomb',       emoji:'🔥', name:'BOMBA',       color:Color(0xFFFF4400)),
  SeasonInfo(key:'speed',      emoji:'⚡', name:'HIZ',         color:Color(0xFFFFCC00)),
  SeasonInfo(key:'ice',        emoji:'❄',  name:'BUZ',         color:Color(0xFF88EEFF)),
  SeasonInfo(key:'multiplier', emoji:'✖',  name:'ÇARPAN',      color:Color(0xFFC87FFF)),
  SeasonInfo(key:'shuffle',    emoji:'🔀', name:'DEĞİŞ TOKUŞ', color:Color(0xFFFF88FF)),
  SeasonInfo(key:'mystery',    emoji:'❓', name:'GİZEM',       color:Color(0xFF888888)),
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
    final a = phaseTime < 0.2
        ? (phaseTime / 0.2).clamp(0.0, 1.0)
        : phaseTime > 2.0
            ? (1 - (phaseTime-2.0)/0.5).clamp(0.0, 1.0)
            : 1.0;

    // Karartma
    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=const Color(0xFF04031A).withValues(alpha:a*0.88));

    // Flash
    if (phaseTime < 0.35) {
      canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
        Paint()..color=Colors.white.withValues(alpha:(1-phaseTime/0.35)*0.6));
    }

    // Parçacıklar
    _renderParticles(canvas, sw, sh, a);

    final cx = sw/2, cy = sh/2;

    // Daire glow
    canvas.drawCircle(Offset(cx,cy), 180,
      Paint()..color=const Color(0xFFFFD700).withValues(alpha:a*0.15)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,50));

    // Başlık
    _txt(canvas, '⚡ SÜPER PATLAMA ⚡', cx, cy-90,
      30, const Color(0xFFFFD700).withValues(alpha:a), glow:const Color(0xFFFFD700));

    // Büyük sayaç
    _txt(canvas, '+${displayBonus.toInt()}', cx, cy-20,
      52, const Color(0xFF5CF5E0).withValues(alpha:a), glow:const Color(0xFF5CF5E0));

    _txt(canvas, 'BONUS PUAN', cx, cy+42,
      13, Colors.white.withValues(alpha:a*0.65), letterSpacing:5);

    _txt(canvas, '🏆 OYUNUN TANRISI! 🏆', cx, cy+78,
      17, const Color(0xFFC87FFF).withValues(alpha:a), glow:const Color(0xFFC87FFF));

    // Çerçeve
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center:Offset(cx,cy), width:420, height:220),
      const Radius.circular(18)),
      Paint()..color=const Color(0xFFFFD700).withValues(alpha:a*0.4)
             ..style=PaintingStyle.stroke..strokeWidth=2.5);
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
    _txt(canvas, 'MEVSİM SEÇİLİYOR...', cx, cy-145,
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
    _txt(canvas, season.name, cx+28, my+machineH/2,
      24, season.color.withValues(alpha:a), bold:true);

    // Hız göstergesi (dönüyor mu?)
    if (!slotDone) {
      final spinA = 0.3 + (1-progress)*0.5;
      _txt(canvas, '▼ SEÇİLİYOR ▼', cx, my+machineH+22,
        11, Colors.white.withValues(alpha:a*spinA), letterSpacing:4);
    }

    // Kilitlendi göstergesi
    if (slotDone) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(mx, my, machineW, machineH), const Radius.circular(16)),
        Paint()..color=season.color.withValues(alpha:a*0.12));
      _txt(canvas, '✓ KİLİTLENDİ', cx, my+machineH+22,
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
    final a = _announceTime < 0.2
        ? (_announceTime/0.2).clamp(0.0,1.0)
        : _announceTime > 0.9
            ? (1-(_announceTime-0.9)/0.3).clamp(0.0,1.0)
            : 1.0;

    canvas.drawRect(Rect.fromLTWH(0,0,sw,sh),
      Paint()..color=const Color(0xFF04031A).withValues(alpha:a*0.85));

    final cx = sw/2, cy = sh/2;
    final season = kSeasons[selectedSeason];

    // Büyük glow
    canvas.drawCircle(Offset(cx,cy), 200,
      Paint()..color=season.color.withValues(alpha:a*0.20)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,60));

    // Emoji büyük
    _txt(canvas, season.emoji, cx, cy-60, 64, season.color.withValues(alpha:a));

    // Mevsim adı
    _txt(canvas, '${season.name} MEVSİMİ', cx, cy+20,
      28, season.color.withValues(alpha:a), bold:true, glow:season.color);

    _txt(canvas, 'B A Ş L I Y O R !', cx, cy+60,
      14, Colors.white.withValues(alpha:a*0.8), letterSpacing:8);

    // Çerçeve
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center:Offset(cx,cy), width:340, height:200),
      const Radius.circular(18)),
      Paint()..color=season.color.withValues(alpha:a*0.5)
             ..style=PaintingStyle.stroke..strokeWidth=2.5);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center:Offset(cx,cy), width:348, height:208),
      const Radius.circular(20)),
      Paint()..color=season.color.withValues(alpha:a*0.2)
             ..style=PaintingStyle.stroke..strokeWidth=6);
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