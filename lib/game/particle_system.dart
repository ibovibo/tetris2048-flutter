import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'constants.dart';

class Particle {
  double x, y, vx, vy, life, size;
  Color color;
  bool isSquare;
  Particle({required this.x, required this.y, required this.vx, required this.vy,
    required this.color, this.life = 1.0, this.size = 4.0, this.isSquare = false});
  void update(double dt) {
    x += vx*dt*60; y += vy*dt*60;
    vy += dt*0.18; vx *= 0.90; vy *= 0.90;
    life -= dt*1.4;
  }
}

// Uçan score yazısı — birleşme noktasından yukarı
class ScoreFloat {
  double x, y, vy, life, fontSize, alpha;
  String text;
  Color color;
  ScoreFloat({required this.x, required this.y, required this.text,
    required this.color, required this.fontSize, this.vy = -70})
      : life = 1.0, alpha = 1.0;
  void update(double dt) {
    y += vy*dt; vy *= 0.87;
    life -= dt*0.85;
    alpha = life.clamp(0.0, 1.0);
  }
}

// Sağ üst köşe bildirim şeridi (combo, streak)
class NotificationBanner {
  String text;
  Color color;
  double life, slideX;
  NotificationBanner({required this.text, required this.color})
      : life = 1.0, slideX = 1.0; // 1.0 = ekran dışı, 0.0 = tam içeride
  void update(double dt) {
    life -= dt*0.7;
    // Giriş animasyonu
    if (slideX > 0) slideX = (slideX - dt*6).clamp(0.0, 1.0);
    // Çıkış animasyonu
    if (life < 0.25) slideX = ((0.25-life)/0.25).clamp(0.0, 1.0);
  }
}

// Level geçiş — ortada büyük, şeffaf, renkli
class LevelTransition {
  int level;
  double life, scale, shinePos;
  Color color;
  LevelTransition({required this.level, required this.color})
      : life = 1.0, scale = 0.05, shinePos = -0.3;
  void update(double dt) {
    life -= dt*0.5;
    if (scale < 1.0) scale = (scale + dt*9).clamp(0.05, 1.0);
    shinePos += dt*1.6;
  }
}

// Milestone banner — ortada
class MilestoneBanner {
  int val; String msg; Color color;
  double life, scale;
  MilestoneBanner({required this.val, required this.msg, required this.color})
      : life = 1.0, scale = 0.05;
  void update(double dt) {
    life -= dt*0.42;
    if (scale < 1.0) scale = (scale + dt*9).clamp(0.05, 1.0);
  }
}

class MergeRing {
  double x, y, radius, life, maxRadius, thickness;
  Color color;
  MergeRing({required this.x, required this.y, required this.color,
    required this.maxRadius, this.thickness = 3.0}) : radius = 0, life = 1.0;
  void update(double dt) { radius += dt*maxRadius*4.2; life -= dt*2.6; }
}

class PopEffect {
  double x, y, scale, life; Color color;
  PopEffect({required this.x, required this.y, required this.color})
      : scale = 0.0, life = 1.0;
  void update(double dt) { life -= dt*3.8; scale = life > 0.5 ? (1.0-life)*2.6 : life*2.6; }
}

class ComboWave {
  double life; Color color; int comboCount;
  ComboWave({required this.color, required this.comboCount}) : life = 1.0;
  void update(double dt) { life -= dt*1.8; }
}

// ═══════════════════════════════════════════════════════════
class ParticleSystem {
  final List<Particle>          _particles  = [];
  final List<ScoreFloat>        _scores     = [];
  final List<NotificationBanner>_notifs     = [];
  final List<LevelTransition>   _levelTrans = [];
  final List<MilestoneBanner>   _banners    = [];
  final List<MergeRing>         _rings      = [];
  final List<PopEffect>         _pops       = [];
  final List<ComboWave>         _waves      = [];
  final math.Random _rng = math.Random();

  // ── Spawn fonksiyonları ───────────────────────────────────
  void spawnMerge(double cx, double cy, Color color, int val) {
    final count = val >= 2048 ? 55 : val >= 512 ? 35 : val >= 128 ? 22 : 14;
    final speed = val >= 1024 ? 7.0 : val >= 256 ? 5.0 : val >= 64 ? 3.2 : 2.0;
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble()*math.pi*2;
      final s = speed*(0.4+_rng.nextDouble());
      _particles.add(Particle(x:cx,y:cy,vx:math.cos(a)*s,vy:math.sin(a)*s,
        color:_vary(color),size:2.5+_rng.nextDouble()*(val>=256?7:5),
        isSquare:_rng.nextDouble()>0.5));
    }
    final r = val>=2048?kCell*2.2:val>=512?kCell*1.6:kCell*1.0;
    _rings.add(MergeRing(x:cx,y:cy,color:color,maxRadius:r,thickness:val>=512?5.5:3.0));
    if (val>=64)  _rings.add(MergeRing(x:cx,y:cy,color:Colors.white,maxRadius:r*0.5,thickness:1.5));
    if (val>=512) _rings.add(MergeRing(x:cx,y:cy,color:_vary(color),maxRadius:r*1.6,thickness:2.5));
    _pops.add(PopEffect(x:cx,y:cy,color:color));
  }

  void spawnExplosion(double cx, double cy) {
    final cols = [Colors.orange,Colors.yellow,Colors.red,Colors.white,Colors.deepOrange];
    for (int i = 0; i < 65; i++) {
      final a = _rng.nextDouble()*math.pi*2;
      final s = 3.5+_rng.nextDouble()*10;
      _particles.add(Particle(x:cx,y:cy,vx:math.cos(a)*s,vy:math.sin(a)*s-2,
        color:cols[_rng.nextInt(cols.length)],size:4+_rng.nextDouble()*9,isSquare:_rng.nextBool()));
    }
    _rings.add(MergeRing(x:cx,y:cy,color:Colors.white,maxRadius:kCell*3.2,thickness:7));
    _rings.add(MergeRing(x:cx,y:cy,color:Colors.orange,maxRadius:kCell*5.0,thickness:3.5));
  }

  void spawnConfetti(double cx, double cy) {
    final cols = [const Color(0xFFC87FFF),const Color(0xFF5CF5E0),const Color(0xFFF5E05C),
      const Color(0xFFFF6FA8),Colors.white,const Color(0xFF44FF99),const Color(0xFFFF8833)];
    for (int i = 0; i < 100; i++) {
      final a = -math.pi*0.5+(_rng.nextDouble()-0.5)*math.pi*2.2;
      final s = 1.5+_rng.nextDouble()*11;
      _particles.add(Particle(x:cx,y:cy,vx:math.cos(a)*s,vy:math.sin(a)*s,
        color:cols[_rng.nextInt(cols.length)],size:4+_rng.nextDouble()*7,
        isSquare:_rng.nextDouble()>0.35,life:2.0));
    }
  }

  // Score popup — birleşme noktasında, yukarı uçar
  void addScoreFloat(double cx, double cy, String text, Color color, double fontSize) {
    final ox = (_rng.nextDouble()-0.5)*kCell*2;
    _scores.add(ScoreFloat(x:cx+ox, y:cy-10, text:text, color:color,
      fontSize:fontSize, vy:-75-_rng.nextDouble()*30));
  }

  // Sağ üst köşe bildirim şeridi — combo, streak
  void addNotification(String text, Color color) {
    // Eski aynı tip bildirim varsa kaldır
    if (_notifs.length >= 3) _notifs.removeAt(0);
    _notifs.add(NotificationBanner(text:text, color:color));
  }

  void addLevelTransition(int level, Color color) {
    _levelTrans.clear();
    _levelTrans.add(LevelTransition(level:level, color:color));
  }

  void addMilestoneBanner(int val, String msg, Color color) {
    _banners.clear();
    _banners.add(MilestoneBanner(val:val, msg:msg, color:color));
  }

  void addComboWave(Color color, int combo) =>
      _waves.add(ComboWave(color:color, comboCount:combo));

  void addBounce(double cx, double cy, Color color) =>
      _pops.add(PopEffect(x:cx, y:cy, color:color));

  // Eski uyumluluk
  void addFloat(double x, double y, String text, Color color,
      {double fontSize=16, double vy=-60, bool big=false}) {
    if (big) {
      addNotification(text, color);
    } else {
      addScoreFloat(x, y, text, color, fontSize);
    }
  }
  void addCenterFloat(double x, double y, String text, Color color, double fontSize) =>
      addNotification(text, color);

  Color _vary(Color base) {
    final h = HSVColor.fromColor(base);
    return h.withSaturation((h.saturation+(_rng.nextDouble()-0.5)*0.25).clamp(0,1))
            .withValue((h.value+(_rng.nextDouble()-0.5)*0.2).clamp(0.3,1)).toColor();
  }

  void update(double dt) {
    _particles.removeWhere((p)=>p.life<=0); for (final p in _particles) {
      p.update(dt);
    }
    _scores.removeWhere((s)=>s.life<=0);    for (final s in _scores) {
      s.update(dt);
    }
    _notifs.removeWhere((n)=>n.life<=0);    for (final n in _notifs) {
      n.update(dt);
    }
    _levelTrans.removeWhere((l)=>l.life<=0);for (final l in _levelTrans) {
      l.update(dt);
    }
    _banners.removeWhere((b)=>b.life<=0);   for (final b in _banners) {
      b.update(dt);
    }
    _rings.removeWhere((r)=>r.life<=0);     for (final r in _rings) {
      r.update(dt);
    }
    _pops.removeWhere((p)=>p.life<=0);      for (final p in _pops) {
      p.update(dt);
    }
    _waves.removeWhere((w)=>w.life<=0);     for (final w in _waves) {
      w.update(dt);
    }
  }

  void render(Canvas canvas, double boardX, double boardY,
      {double screenW = 480, double screenH = 780}) {
    final bw = kCols*kCell, bh = kRows*kCell;

    // 1. Combo dalgası
    for (final w in _waves) {
      final a = w.life.clamp(0.0,1.0);
      final pulse = math.sin(w.life*math.pi);
      canvas.drawRect(Rect.fromLTWH(boardX-4,boardY-4,bw+8,bh+8),
        Paint()..color=w.color.withValues(alpha:a*0.95)
               ..style=PaintingStyle.stroke..strokeWidth=(5.0+w.comboCount*2.8)*pulse);
      canvas.drawRect(Rect.fromLTWH(boardX+3,boardY+3,bw-6,bh-6),
        Paint()..color=w.color.withValues(alpha:a*0.08));
    }

    // 2. Merge halkaları
    for (final r in _rings) {
      final a = r.life.clamp(0.0,1.0);
      if (r.radius<=0) continue;
      canvas.drawCircle(Offset(boardX+r.x,boardY+r.y), r.radius,
        Paint()..color=r.color.withValues(alpha:a*0.88)
               ..style=PaintingStyle.stroke..strokeWidth=(r.thickness*a).clamp(0.5,10));
    }

    // 3. Pop
    for (final p in _pops) {
      if (p.scale<=0) continue;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(boardX+p.x-kCell*p.scale/2,boardY+p.y-kCell*p.scale/2,
          kCell*p.scale,kCell*p.scale), const Radius.circular(9)),
        Paint()..color=p.color.withValues(alpha:p.life.clamp(0,1)*0.65)
               ..style=PaintingStyle.stroke..strokeWidth=2.5);
    }

    // 4. Parçacıklar
    for (final p in _particles) {
      final a = (p.life*p.life).clamp(0.0,1.0);
      final sz = (p.size*math.sqrt(p.life)).clamp(0.5,15.0);
      final cx = boardX+p.x, cy = boardY+p.y;
      final paint = Paint()..color=p.color.withValues(alpha:a);
      if (p.isSquare) {
        canvas.drawRect(Rect.fromCenter(center:Offset(cx,cy),width:sz,height:sz),paint);
      } else {
        canvas.drawCircle(Offset(cx,cy),sz/2,paint);
      }
      if (sz>5&&a>0.35) {
        canvas.drawCircle(Offset(cx,cy),sz*0.9,
        Paint()..color=p.color.withValues(alpha:a*0.22)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,5));
      }
    }

    // 5. Score popup'lar — birleşme noktasında
    for (final s in _scores) {
      if (s.alpha<=0) continue;
      // Glow
      canvas.drawCircle(Offset(boardX+s.x,boardY+s.y), s.fontSize*0.85,
        Paint()..color=s.color.withValues(alpha:s.alpha*0.20)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,10));
      _txt(canvas, s.text, boardX+s.x, boardY+s.y, s.fontSize,
        s.color.withValues(alpha:s.alpha), shadow:s.color, bold:true);
    }

    // 6. Milestone banner — ortada
    for (final b in _banners) {
      _drawMilestoneBanner(canvas, boardX, boardY, bw, bh, b);
    }

    // 7. Sağ üst bildirim şeritleri (combo, streak) — level banner'ın altında
    _drawNotifications(canvas, boardX, boardY, bw);

    // 8. Level geçiş — EN ÜSTTE
    for (final l in _levelTrans) {
      _drawLevelBanner(canvas, boardX, boardY, bw, bh, l);
    }
  }

  // ─── Sağ üst köşe bildirim şeritleri ─────────────────────
  void _drawNotifications(Canvas canvas, double boardX, double boardY, double bw) {
    const bannerH = 38.0;
    const bannerW = 200.0;
    final baseX = boardX + bw; // board'un sağ kenarı

    for (int i = 0; i < _notifs.length; i++) {
      final n = _notifs[_notifs.length-1-i]; // en yeni üstte
      final a = n.life.clamp(0.0,1.0);
      final slide = n.slideX; // 0=içeride, 1=dışarıda
      final x = baseX - bannerW*(1-slide) + bannerW*slide;
      final y = boardY + 8 + i*(bannerH+6);

      // Şerit arka planı — renkli, yarı saydam, ok şekli
      final path = Path();
      const tip = 12.0;
      path.moveTo(x+tip, y);
      path.lineTo(x+bannerW, y);
      path.lineTo(x+bannerW, y+bannerH);
      path.lineTo(x+tip, y+bannerH);
      path.lineTo(x, y+bannerH/2);
      path.close();

      // Arka plan dolgu
      canvas.drawPath(path, Paint()..color=n.color.withValues(alpha:a*0.85));
      // Üst parlaklık
      final shinePath = Path();
      shinePath.moveTo(x+tip, y);
      shinePath.lineTo(x+bannerW, y);
      shinePath.lineTo(x+bannerW, y+bannerH*0.45);
      shinePath.lineTo(x+tip, y+bannerH*0.45);
      shinePath.lineTo(x+tip*0.5, y+bannerH*0.225);
      shinePath.close();
      canvas.drawPath(shinePath, Paint()..color=Colors.white.withValues(alpha:a*0.25));
      // Kenarlık
      canvas.drawPath(path, Paint()..color=Colors.white.withValues(alpha:a*0.35)
        ..style=PaintingStyle.stroke..strokeWidth=1.5);

      // Yazı
      _txt(canvas, n.text, x+tip+8+(bannerW-tip-8)/2, y+bannerH/2,
        13, Colors.white.withValues(alpha:a), bold:true);
    }
  }

  // ─── Level Banner — ortada, şeffaf, renkli, modern ────────
  void _drawLevelBanner(Canvas canvas, double bx, double by,
      double bw, double bh, LevelTransition l) {
    final a  = (l.life*2.0).clamp(0.0,1.0);
    final sc = l.scale;
    const w = 280.0, h = 140.0;
    final px = bx+bw/2-w*sc/2;
    final py = by+bh/2-h*sc/2;

    // Dış halka glow
    canvas.drawCircle(Offset(bx+bw/2,by+bh/2), 180*sc,
      Paint()..color=l.color.withValues(alpha:a*0.15)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,50));

    // Ana panel — yarı saydam, renkli gradyan hissi
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(px,py,w*sc,h*sc), const Radius.circular(18));

    // Arka plan — koyu ama renk geçişi var
    canvas.drawRRect(rr, Paint()..color=const Color(0xFF04031A).withValues(alpha:a*0.92));

    // Renkli kenar glow katmanı
    canvas.drawRRect(rr, Paint()..color=l.color.withValues(alpha:a*0.18));

    // Üst renkli şerit
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(px,py,w*sc,7*sc), const Radius.circular(18)),
      Paint()..color=l.color.withValues(alpha:a));
    // Alt şerit
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(px,py+h*sc-7*sc,w*sc,7*sc), const Radius.circular(18)),
      Paint()..color=l.color.withValues(alpha:a*0.6));

    // Kenarlık
    canvas.drawRRect(rr, Paint()..color=l.color.withValues(alpha:a)
      ..style=PaintingStyle.stroke..strokeWidth=2.5);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(px-4,py-4,w*sc+8,h*sc+8), const Radius.circular(21)),
      Paint()..color=l.color.withValues(alpha:a*0.3)
             ..style=PaintingStyle.stroke..strokeWidth=6);

    // Işıltı efekti
    if (l.shinePos > 0 && l.shinePos < 1.2) {
      canvas.save();
      canvas.clipRRect(rr);
      final sx = px + w*sc*(l.shinePos/1.2);
      canvas.drawRect(Rect.fromLTWH(sx-35,py,70,h*sc),
        Paint()..color=Colors.white.withValues(alpha:a*0.18)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,15));
      canvas.restore();
    }

    // İçerik
    _txt(canvas, 'S E V İ Y E', bx+bw/2, py+26*sc, 10*sc,
      Colors.white.withValues(alpha:a*0.6), letterSpacing:10);

    // Büyük sayı
    canvas.drawCircle(Offset(bx+bw/2,py+80*sc), 55*sc,
      Paint()..color=l.color.withValues(alpha:a*0.22)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,22));
    _txt(canvas, l.level.toString(), bx+bw/2, py+80*sc, 52*sc,
      l.color.withValues(alpha:a), shadow:l.color, bold:true, extraGlow:32);

    _txt(canvas, '— YENİ SEVİYE —', bx+bw/2, py+122*sc, 9*sc,
      Colors.white.withValues(alpha:a*0.45), letterSpacing:6);
  }

  // ─── Milestone Banner ─────────────────────────────────────
  void _drawMilestoneBanner(Canvas canvas, double bx, double by,
      double bw, double bh, MilestoneBanner b) {
    final a  = (b.life*2.0).clamp(0.0,1.0);
    final sc = b.scale;
    const w = 240.0, h = 100.0;
    final px = bx+bw/2-w*sc/2;
    final py = by+bh*0.28-h*sc/2;

    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(px,py,w*sc,h*sc), const Radius.circular(14));
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(px-14,py-14,w*sc+28,h*sc+28), const Radius.circular(20)),
      Paint()..color=b.color.withValues(alpha:a*0.20)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,30));
    canvas.drawRRect(rr, Paint()..color=const Color(0xFF02010C).withValues(alpha:a*0.94));
    canvas.drawRRect(rr, Paint()..color=b.color.withValues(alpha:a*0.15));
    canvas.drawRRect(rr, Paint()..color=b.color.withValues(alpha:a)
      ..style=PaintingStyle.stroke..strokeWidth=2.5);

    _txt(canvas, b.val.toString(), bx+bw/2, py+34*sc, 34*sc,
      b.color.withValues(alpha:a), shadow:b.color, bold:true, extraGlow:24);
    _txt(canvas, b.msg, bx+bw/2, py+76*sc, 12*sc,
      Colors.white.withValues(alpha:a*0.88));
  }

  void _txt(Canvas canvas, String text, double cx, double cy,
      double size, Color color, {Color? shadow, bool bold=false,
      double letterSpacing=0, double extraGlow=0}) {
    if (size < 1) return;
    final shadows = <Shadow>[
      Shadow(color:Colors.black.withValues(alpha:0.95),blurRadius:6,offset:const Offset(0,2)),
    ];
    if (shadow!=null) {
      shadows.add(Shadow(color:shadow,blurRadius:16));
      if (extraGlow>0) shadows.add(Shadow(color:shadow,blurRadius:extraGlow));
    }
    final tp = TextPainter(
      text:TextSpan(text:text,style:TextStyle(fontFamily:'monospace',fontSize:size,
        fontWeight:bold?FontWeight.bold:FontWeight.w600,
        color:color,letterSpacing:letterSpacing,shadows:shadows)),
      textDirection:TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx-tp.width/2, cy-tp.height/2));
  }
}