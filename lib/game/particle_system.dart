import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'constants.dart';

// ─── Parçacık ────────────────────────────────────────────────
class Particle {
  double x, y, vx, vy, life, size, rotation, rotSpeed;
  Color color;
  bool isSquare;
  Particle({required this.x, required this.y, required this.vx, required this.vy,
    required this.color, this.life = 1.0, this.size = 4.0, this.isSquare = false,
    this.rotation = 0, this.rotSpeed = 0});
  void update(double dt) {
    x += vx*dt*60; y += vy*dt*60;
    vy += dt*0.22; vx *= 0.88; vy *= 0.88;
    rotation += rotSpeed*dt;
    life -= dt*1.3;
  }
}

// ─── Işın parçacığı (birleşmede yayılan ışık huzmesi) ────────
class LightRay {
  double x, y, angle, length, life, width;
  Color color;
  LightRay({required this.x, required this.y, required this.angle,
    required this.length, required this.color, this.width = 2})
      : life = 1.0;
  void update(double dt) {
    life -= dt*3.5;
    length += dt*kCell*8;
  }
}

// ─── Şok dalgası ─────────────────────────────────────────────
class ShockWave {
  double x, y, radius, life, maxRadius, thickness;
  Color color;
  ShockWave({required this.x, required this.y, required this.color,
    required this.maxRadius, this.thickness = 3.0}) : radius = 0, life = 1.0;
  void update(double dt) {
    radius += dt*maxRadius*5;
    life -= dt*3.0;
    thickness = (thickness * (1 - dt*2)).clamp(0.5, 10);
  }
}

// ─── Kor parçacığı (patlama için) ────────────────────────────
class Ember {
  double x, y, vx, vy, life, size;
  Color color;
  Ember({required this.x, required this.y, required this.vx, required this.vy,
    required this.color, required this.size}) : life = 1.0;
  void update(double dt) {
    x += vx*dt*60; y += vy*dt*60;
    vy += dt*0.35;
    vx *= 0.95; vy *= 0.92;
    size = (size * (1 - dt*0.8)).clamp(0.5, 20);
    life -= dt*1.1;
  }
}

// ─── Uçan score yazısı ───────────────────────────────────────
class ScoreFloat {
  double x, y, vy, life, fontSize, alpha, scale;
  String text; Color color;
  ScoreFloat({required this.x, required this.y, required this.text,
    required this.color, required this.fontSize, this.vy = -70})
      : life = 1.0, alpha = 1.0, scale = 0.3;
  void update(double dt) {
    // Scale bounce – hızlı büyür
    if (scale < 1.15) {
      scale = (scale + dt * 9).clamp(0.3, 1.15);
    } else if (scale > 1.0) {
      scale = (scale - dt * 4).clamp(1.0, 1.15);
    }
    y += vy * dt; vy *= 0.85;
    life -= dt * 0.85;
    alpha = life.clamp(0.0, 1.0);
  }
}

// ─── Bildirim şeridi ─────────────────────────────────────────
class NotificationBanner {
  String text; Color color;
  double life, slideX;
  NotificationBanner({required this.text, required this.color})
      : life = 1.0, slideX = 1.0;
  void update(double dt) {
    life -= dt*0.7;
    if (slideX > 0) slideX = (slideX - dt*7).clamp(0.0, 1.0);
    if (life < 0.25) slideX = ((0.25-life)/0.25).clamp(0.0, 1.0);
  }
}

// ─── Level geçiş ─────────────────────────────────────────────
class LevelTransition {
  int level; double life, scale, shinePos; Color color;
  LevelTransition({required this.level, required this.color})
      : life = 1.0, scale = 0.05, shinePos = -0.3;
  void update(double dt) {
    life -= dt*0.5;
    if (scale < 1.0) scale = (scale + dt*9).clamp(0.05, 1.0);
    shinePos += dt*1.6;
  }
}

// ─── Milestone banner ────────────────────────────────────────
class MilestoneBanner {
  int val; String msg; Color color; double life, scale;
  MilestoneBanner({required this.val, required this.msg, required this.color})
      : life = 1.0, scale = 0.05;
  void update(double dt) {
    life -= dt*0.42;
    if (scale < 1.0) scale = (scale + dt*9).clamp(0.05, 1.0);
  }
}

// ─── Combo dalgası ───────────────────────────────────────────
class ComboWave {
  double life; Color color; int comboCount;
  ComboWave({required this.color, required this.comboCount}) : life = 1.0;
  void update(double dt) { life -= dt*1.8; }
}

// ─── Pop efekti ──────────────────────────────────────────────
class PopEffect {
  double x, y, scale, life, alpha; Color color;
  PopEffect({required this.x, required this.y, required this.color})
      : scale = 0.0, life = 1.0, alpha = 1.0;
  void update(double dt) {
    life -= dt * 3.5;
    // Bounce: hızlı büyür, biraz küçülür, tekrar büyür, solar
    if (life > 0.7) {
      scale = (1.0 - life) * 3.5; // 0→1.05
    } else if (life > 0.5) {
      scale = 1.05 - (0.7 - life) * 2.5; // 1.05→0.55
    } else if (life > 0.25) {
      scale = 0.55 + (0.5 - life) * 1.8; // 0.55→1.0
    } else {
      scale = life * 4; // 1.0→0
    }
    alpha = life.clamp(0.0, 1.0);
  }
}

// ─── Arkaplan yıldızı ────────────────────────────────────────
class BgStar {
  double x, y, size, phase, speed;
  Color color;
  BgStar({required this.x, required this.y, required this.size,
    required this.phase, required this.speed, required this.color});
}

// ═══════════════════════════════════════════════════════════
// ANA SİSTEM
// ═══════════════════════════════════════════════════════════
class ParticleSystem {
  final List<Particle>          _particles  = [];
  final List<LightRay>          _rays       = [];
  final List<ShockWave>         _shocks     = [];
  final List<Ember>             _embers     = [];
  final List<ScoreFloat>        _scores     = [];
  final List<NotificationBanner>_notifs     = [];
  final List<LevelTransition>   _levelTrans = [];
  final List<MilestoneBanner>   _banners    = [];
  final List<ComboWave>         _waves      = [];
  final List<PopEffect>         _pops       = [];
  final List<BgStar>            _bgStars    = [];
  final SeasonBgSystem          seasonBg    = SeasonBgSystem();
  final math.Random _rng = math.Random();
  double _time = 0;

  ParticleSystem() {
    _initBgStars();
  }

  void _initBgStars() {
    // Arkaplan yıldızları — 60 tane
    final cols = [
      const Color(0xFFC87FFF), const Color(0xFF5CF5E0),
      const Color(0xFF7777FF), const Color(0xFFFF88FF),
      Colors.white, const Color(0xFF44AAFF),
    ];
    for (int i = 0; i < 60; i++) {
      _bgStars.add(BgStar(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 0.5 + _rng.nextDouble() * 2.5,
        phase: _rng.nextDouble() * math.pi * 2,
        speed: 0.5 + _rng.nextDouble() * 2.0,
        color: cols[_rng.nextInt(cols.length)],
      ));
    }
  }

  // ── Birleşme efekti ──────────────────────────────────────
  void spawnMerge(double cx, double cy, Color color, int val) {
    final count = val >= 2048 ? 30 : val >= 512 ? 20 : val >= 128 ? 12 : 8;
    final speed = val >= 1024 ? 9.0 : val >= 256 ? 6.5 : val >= 64 ? 4.5 : 2.8;

    // Ana parçacıklar
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final spd = speed * (0.3 + _rng.nextDouble() * 1.2);
      final baseColor = _vary(color);
      // Bazıları beyaz — parlama hissi
      final pColor = _rng.nextDouble() > 0.75 ? Colors.white : baseColor;
      _particles.add(Particle(
        x: cx, y: cy,
        vx: math.cos(angle)*spd, vy: math.sin(angle)*spd,
        color: pColor,
        size: 2 + _rng.nextDouble() * (val >= 512 ? 10 : val >= 128 ? 7 : 5),
        isSquare: _rng.nextDouble() > 0.4,
        rotation: _rng.nextDouble() * math.pi * 2,
        rotSpeed: (_rng.nextDouble() - 0.5) * 12,
      ));
    }

    // Merkeze çekilen parçacıklar — önce içe sonra dışa
    final inwardCount = val >= 128 ? 12 : 6;
    for (int i = 0; i < inwardCount; i++) {
      final angle = (math.pi * 2 / inwardCount) * i;
      final dist = kCell * (0.8 + _rng.nextDouble() * 0.5);
      _particles.add(Particle(
        x: cx + math.cos(angle)*dist,
        y: cy + math.sin(angle)*dist,
        vx: -math.cos(angle) * speed * 0.8,
        vy: -math.sin(angle) * speed * 0.8,
        color: _vary(color),
        size: 3 + _rng.nextDouble() * 5,
        isSquare: false,
        life: 0.5,
      ));
    }

    // Işın huzmesi
    if (val >= 32) {
      final rayCount = val >= 1024 ? 16 : val >= 256 ? 10 : 6;
      for (int i = 0; i < rayCount; i++) {
        final angle = (math.pi * 2 / rayCount) * i;
        _rays.add(LightRay(
          x: cx, y: cy, angle: angle,
          length: kCell * 0.2,
          color: _rng.nextDouble() > 0.5 ? Colors.white : _vary(color),
          width: 1.2 + _rng.nextDouble() * 2.5,
        ));
      }
    }

    // Şok dalgaları — daha fazla ve yoğun
    final r = val >= 2048 ? kCell*2.8 : val >= 512 ? kCell*2.0 : val >= 128 ? kCell*1.4 : kCell*1.0;
    _shocks.add(ShockWave(x:cx, y:cy, color:color, maxRadius:r, thickness:val>=512?7:4));
    _shocks.add(ShockWave(x:cx, y:cy, color:Colors.white, maxRadius:r*0.45, thickness:2));
    if (val >= 128) _shocks.add(ShockWave(x:cx, y:cy, color:_vary(color), maxRadius:r*1.4, thickness:2));
    if (val >= 512) _shocks.add(ShockWave(x:cx, y:cy, color:Colors.white, maxRadius:r*1.8, thickness:1.5));

    _pops.add(PopEffect(x:cx, y:cy, color:color));
  }

  // ── Patlama efekti ───────────────────────────────────────
  void spawnExplosion(double cx, double cy) {
    final fireCols = [
      Colors.white, const Color(0xFFFFFFAA),
      Colors.yellow, const Color(0xFFFFCC00),
      const Color(0xFFFF8800), Colors.orange,
      Colors.deepOrange, Colors.red,
      const Color(0xFFFF4400),
    ];
    for (int i = 0; i < 50; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final spd = 1.5 + _rng.nextDouble() * 13;
      final t = i / 100.0;
      final colIdx = (t * (fireCols.length-1)).floor().clamp(0, fireCols.length-1);
      _embers.add(Ember(
        x: cx, y: cy,
        vx: math.cos(angle)*spd, vy: math.sin(angle)*spd - 2,
        color: fireCols[colIdx],
        size: 4 + _rng.nextDouble() * 12,
      ));
    }
    for (int i = 0; i < 25; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final spd = 5 + _rng.nextDouble() * 10;
      _particles.add(Particle(
        x: cx, y: cy,
        vx: math.cos(angle)*spd, vy: math.sin(angle)*spd - 3,
        color: _rng.nextDouble() > 0.5 ? Colors.white : Colors.yellow,
        size: 1.5 + _rng.nextDouble() * 4,
      ));
    }
    _shocks.add(ShockWave(x:cx, y:cy, color:Colors.white,             maxRadius:kCell*4.0, thickness:9));
    _shocks.add(ShockWave(x:cx, y:cy, color:const Color(0xFFFFAA00), maxRadius:kCell*6.5, thickness:5));
    _shocks.add(ShockWave(x:cx, y:cy, color:const Color(0xFFFF3300), maxRadius:kCell*9.0, thickness:3));
    _shocks.add(ShockWave(x:cx, y:cy, color:Colors.white,             maxRadius:kCell*2.0, thickness:5));
  }

  // ── Konfeti ──────────────────────────────────────────────
  void spawnConfetti(double cx, double cy) {
    final cols = [
      const Color(0xFFC87FFF), const Color(0xFF5CF5E0),
      const Color(0xFFF5E05C), const Color(0xFFFF6FA8),
      Colors.white, const Color(0xFF44FF99),
      const Color(0xFFFF8833), const Color(0xFF3399FF),
    ];
    for (int i = 0; i < 110; i++) {
      final angle = -math.pi*0.5 + (_rng.nextDouble()-0.5)*math.pi*2.2;
      final spd = 1.5 + _rng.nextDouble() * 12;
      _particles.add(Particle(
        x: cx, y: cy,
        vx: math.cos(angle)*spd, vy: math.sin(angle)*spd,
        color: cols[_rng.nextInt(cols.length)],
        size: 4 + _rng.nextDouble() * 7,
        isSquare: _rng.nextDouble() > 0.35,
        life: 1.8,
        rotation: _rng.nextDouble() * math.pi * 2,
        rotSpeed: (_rng.nextDouble() - 0.5) * 10,
      ));
    }
  }

  void addScoreFloat(double cx, double cy, String text, Color color, double fontSize) {
    final ox = (_rng.nextDouble()-0.5)*kCell*2;
    _scores.add(ScoreFloat(x:cx+ox, y:cy-10, text:text, color:color,
      fontSize:fontSize, vy:-80-_rng.nextDouble()*30));
  }

  void addNotification(String text, Color color) {
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

  void addComboWave(Color color, int combo) {
    // Devre dışı: combo dalgası artık çizilmiyor
    return;
  }

  void addBounce(double cx, double cy, Color color) =>
      _pops.add(PopEffect(x:cx, y:cy, color:color));

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
    return h.withSaturation((h.saturation+(_rng.nextDouble()-0.5)*0.3).clamp(0,1))
            .withValue((h.value+(_rng.nextDouble()-0.5)*0.25).clamp(0.25,1)).toColor();
  }

  // ── Update ───────────────────────────────────────────────
  void update(double dt) {
    _time += dt;
    _particles.removeWhere((p) => p.life <= 0); for (final p in _particles) {
      p.update(dt);
    }
    _rays.removeWhere((r) => r.life <= 0);       for (final r in _rays) {
      r.update(dt);
    }
    _shocks.removeWhere((s) => s.life <= 0);     for (final s in _shocks) {
      s.update(dt);
    }
    _embers.removeWhere((e) => e.life <= 0);     for (final e in _embers) {
      e.update(dt);
    }
    _scores.removeWhere((s) => s.life <= 0);     for (final s in _scores) {
      s.update(dt);
    }
    _notifs.removeWhere((n) => n.life <= 0);     for (final n in _notifs) {
      n.update(dt);
    }
    _levelTrans.removeWhere((l) => l.life <= 0); for (final l in _levelTrans) {
      l.update(dt);
    }
    _banners.removeWhere((b) => b.life <= 0);    for (final b in _banners) {
      b.update(dt);
    }
    _waves.removeWhere((w) => w.life <= 0);      for (final w in _waves) {
      w.update(dt);
    }
    _pops.removeWhere((p) => p.life <= 0);       for (final p in _pops) {
      p.update(dt);
    }
  }

  // ── Render ───────────────────────────────────────────────
  void render(Canvas canvas, double boardX, double boardY,
      {double screenW = 480, double screenH = 780}) {
    final bw = kCols*kCell, bh = kRows*kCell;

    // Board ici efektler — kirpilmis
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(boardX, boardY, bw, bh));

    // 0. Arkaplan yıldızları
    _renderBgStars(canvas, screenW, screenH);
    seasonBg.render(canvas, boardX, boardY, bw, bh);

    // 1. Combo dalgası — devre dışı

    // 2. Şok dalgaları
    for (final s in _shocks) {
      final a = s.life.clamp(0.0,1.0);
      if (s.radius <= 0) continue;
      canvas.drawCircle(Offset(boardX+s.x, boardY+s.y), s.radius,
        Paint()..color=s.color.withValues(alpha:a*0.85)
               ..style=PaintingStyle.stroke
               ..strokeWidth=(s.thickness*a).clamp(0.3, 12));
    }

    // 3. Işın huzmesi
    for (final r in _rays) {
      final a = r.life.clamp(0.0,1.0);
      final ex = boardX + r.x + math.cos(r.angle)*r.length;
      final ey = boardY + r.y + math.sin(r.angle)*r.length;
      canvas.drawLine(
        Offset(boardX+r.x, boardY+r.y), Offset(ex, ey),
        Paint()..color=r.color.withValues(alpha:a*0.7)
               ..strokeWidth=r.width*a
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,3),
      );
    }

    // 4. Pop efektleri
    for (final p in _pops) {
      if (p.scale <= 0) continue;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(boardX+p.x-kCell*p.scale/2, boardY+p.y-kCell*p.scale/2,
          kCell*p.scale, kCell*p.scale), const Radius.circular(9)),
        Paint()..color=p.color.withValues(alpha:p.life.clamp(0,1)*0.60)
               ..style=PaintingStyle.stroke..strokeWidth=2.5);
    }

    // 5. Kor parçacıkları (patlama)
    for (final e in _embers) {
      final a = (e.life * e.life).clamp(0.0, 1.0);
      final sz = e.size.clamp(0.5, 20.0);
      final cx = boardX+e.x, cy = boardY+e.y;
      // İç parlak nokta
      canvas.drawCircle(Offset(cx,cy), sz/2,
        Paint()..color=e.color.withValues(alpha:a));
      // Dış glow
      canvas.drawCircle(Offset(cx,cy), sz,
        Paint()..color=e.color.withValues(alpha:a*0.35)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal, 6));
    }

    // 6. Ana parçacıklar
    for (final p in _particles) {
      final a = (p.life*p.life).clamp(0.0, 1.0);
      final sz = (p.size*math.sqrt(p.life)).clamp(0.5, 16.0);
      final cx = boardX+p.x, cy = boardY+p.y;
      if (p.isSquare) {
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(p.rotation);
        canvas.drawRect(Rect.fromCenter(center:Offset.zero, width:sz, height:sz),
          Paint()..color=p.color.withValues(alpha:a));
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(cx,cy), sz/2,
          Paint()..color=p.color.withValues(alpha:a));
      }
      if (sz > 4 && a > 0.3) {
        canvas.drawCircle(Offset(cx,cy), sz*0.85,
          Paint()..color=p.color.withValues(alpha:a*0.20)
                 ..maskFilter=const MaskFilter.blur(BlurStyle.normal,4));
      }
    }

    // 7. Score popuplar
    for (final s in _scores) {
      if (s.alpha <= 0) continue;
      canvas.drawCircle(Offset(boardX+s.x, boardY+s.y), s.fontSize*0.9,
        Paint()..color=s.color.withValues(alpha:s.alpha*0.18)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,6));
      _txt(canvas, s.text, boardX+s.x, boardY+s.y, s.fontSize,
        s.color.withValues(alpha:s.alpha), shadow:s.color, bold:true);
    }

    // 8. Milestone banner
    for (final b in _banners) {
      _drawMilestoneBanner(canvas, boardX, boardY, bw, bh, b);
    }

    // 10. Level banner — EN ÜSTTE
    for (final l in _levelTrans) {
      _drawLevelBanner(canvas, boardX, boardY, bw, bh, l);
    }

    canvas.restore(); // kirpmayi kaldir
  }

  // ─── Arkaplan yıldızları ──────────────────────────────────
  void _renderBgStars(Canvas canvas, double sw, double sh) {
    for (final s in _bgStars) {
      final pulse = 0.3 + math.sin(_time*s.speed + s.phase)*0.7;
      final alpha = pulse.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(s.x*sw, s.y*sh),
        s.size * pulse,
        Paint()..color=s.color.withValues(alpha:alpha*0.6),
      );
      // Küçük glow
      if (s.size > 1.5) {
        canvas.drawCircle(
          Offset(s.x*sw, s.y*sh),
          s.size * 2.5 * pulse,
          Paint()..color=s.color.withValues(alpha:alpha*0.12)
                 ..maskFilter=const MaskFilter.blur(BlurStyle.normal,3),
        );
      }
    }
  }

  // ─── Bildirim şeritleri ───────────────────────────────────
  void _drawNotifications(Canvas canvas, double boardX, double boardY, double bw) {
    const bannerH = 40.0, bannerW = 210.0;
    final baseX = boardX + bw;

    for (int i = 0; i < _notifs.length; i++) {
      final n = _notifs[_notifs.length-1-i];
      final a = n.life.clamp(0.0,1.0);
      final slide = n.slideX;
      final x = baseX - bannerW*(1-slide) + bannerW*slide;
      final y = boardY + 8 + i*(bannerH+6);

      final path = Path();
      const tip = 14.0;
      path.moveTo(x+tip, y);
      path.lineTo(x+bannerW, y);
      path.lineTo(x+bannerW, y+bannerH);
      path.lineTo(x+tip, y+bannerH);
      path.lineTo(x, y+bannerH/2);
      path.close();

      // Glow arka plan
      canvas.drawPath(path, Paint()
        ..color=n.color.withValues(alpha:a*0.25)
        ..maskFilter=const MaskFilter.blur(BlurStyle.normal,4));

      // Ana dolgu
      canvas.drawPath(path, Paint()..color=n.color.withValues(alpha:a*0.88));

      // Üst parlama
      final shinePath = Path();
      shinePath.moveTo(x+tip, y);
      shinePath.lineTo(x+bannerW, y);
      shinePath.lineTo(x+bannerW, y+bannerH*0.42);
      shinePath.lineTo(x+tip, y+bannerH*0.42);
      shinePath.lineTo(x+tip*0.5, y+bannerH*0.21);
      shinePath.close();
      canvas.drawPath(shinePath, Paint()..color=Colors.white.withValues(alpha:a*0.28));

      // Kenarlık
      canvas.drawPath(path, Paint()..color=Colors.white.withValues(alpha:a*0.35)
        ..style=PaintingStyle.stroke..strokeWidth=1.5);

      _txt(canvas, n.text, x+tip+8+(bannerW-tip-8)/2, y+bannerH/2,
        13, Colors.white.withValues(alpha:a), bold:true);
    }
  }

  // ─── Level Banner ─────────────────────────────────────────
  void _drawLevelBanner(Canvas canvas, double bx, double by,
      double bw, double bh, LevelTransition l) {
    final a = (l.life * 2.0).clamp(0.0, 1.0);
    final sc = l.scale;
    const w = 300.0, h = 160.0;
    final px = bx + bw / 2 - w * sc / 2;
    final py = by + bh / 2 - h * sc / 2;
    final cx = bx + bw / 2;
    final cy = by + bh / 2;

    // Dış büyük glow — neon casino havası
    canvas.drawCircle(
      Offset(cx, cy),
      220 * sc,
      Paint()
        ..color = l.color.withValues(alpha: a * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      140 * sc,
      Paint()
        ..color = l.color.withValues(alpha: a * 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Ana panel
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(px, py, w * sc, h * sc),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      rr,
      Paint()..color = const Color(0xFF06041C).withValues(alpha: a * 0.96),
    );
    canvas.drawRRect(rr, Paint()..color = l.color.withValues(alpha: a * 0.08));

    // Üst/alt neon bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px, py, w * sc, 5 * sc),
        const Radius.circular(16),
      ),
      Paint()..color = l.color.withValues(alpha: a),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px, py + h * sc - 5 * sc, w * sc, 5 * sc),
        const Radius.circular(16),
      ),
      Paint()..color = l.color.withValues(alpha: a * 0.7),
    );

    // Çift kenarlık
    canvas.drawRRect(
      rr,
      Paint()
        ..color = l.color.withValues(alpha: a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px - 5, py - 5, w * sc + 10, h * sc + 10),
        const Radius.circular(20),
      ),
      Paint()
        ..color = l.color.withValues(alpha: a * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Işıltı geçişi
    if (l.shinePos > -0.2 && l.shinePos < 1.3) {
      canvas.save();
      canvas.clipRRect(rr);
      final sx = px + w * sc * (l.shinePos / 1.2);
      canvas.drawRect(
        Rect.fromLTWH(sx - 50, py, 100, h * sc),
        Paint()
          ..color = Colors.white.withValues(alpha: a * 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.restore();
    }

    // Sol/sağ dekoratif çizgiler
    final linePaint = Paint()
      ..color = l.color.withValues(alpha: a * 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(px + 12 * sc, py + h * sc * 0.35),
      Offset(px + 45 * sc, py + h * sc * 0.35),
      linePaint,
    );
    canvas.drawLine(
      Offset(px + 12 * sc, py + h * sc * 0.65),
      Offset(px + 45 * sc, py + h * sc * 0.65),
      linePaint,
    );
    canvas.drawLine(
      Offset(px + w * sc - 45 * sc, py + h * sc * 0.35),
      Offset(px + w * sc - 12 * sc, py + h * sc * 0.35),
      linePaint,
    );
    canvas.drawLine(
      Offset(px + w * sc - 45 * sc, py + h * sc * 0.65),
      Offset(px + w * sc - 12 * sc, py + h * sc * 0.65),
      linePaint,
    );

    // İçerik
    _txt(
      canvas,
      'S E V İ Y E',
      cx,
      py + 24 * sc,
      10 * sc,
      Colors.white.withValues(alpha: a * 0.55),
      letterSpacing: 10,
    );

    // Büyük sayı
    canvas.drawCircle(
      Offset(cx, py + 90 * sc),
      50 * sc,
      Paint()
        ..color = l.color.withValues(alpha: a * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    _txt(
      canvas,
      l.level.toString(),
      cx,
      py + 90 * sc,
      58 * sc,
      l.color.withValues(alpha: a),
      shadow: l.color,
      bold: true,
      extraGlow: 40,
    );

    _txt(
      canvas,
      '✦  Y E N İ  S E V İ Y E  ✦',
      cx,
      py + 138 * sc,
      9 * sc,
      l.color.withValues(alpha: a * 0.65),
      letterSpacing: 4,
    );
  }

  // ─── Milestone Banner ─────────────────────────────────────
  void _drawMilestoneBanner(Canvas canvas, double bx, double by,
      double bw, double bh, MilestoneBanner b) {
    final a = (b.life*2.0).clamp(0.0,1.0);
    final sc = b.scale;
    const w = 240.0, h = 100.0;
    final px = bx+bw/2-w*sc/2, py = by+bh*0.28-h*sc/2;
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(px,py,w*sc,h*sc), const Radius.circular(14));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px-14,py-14,w*sc+28,h*sc+28), const Radius.circular(20)),
      Paint()..color=b.color.withValues(alpha:a*0.20)..maskFilter=const MaskFilter.blur(BlurStyle.normal,15));
    canvas.drawRRect(rr, Paint()..color=const Color(0xFF02010C).withValues(alpha:a*0.94));
    canvas.drawRRect(rr, Paint()..color=b.color.withValues(alpha:a*0.15));
    canvas.drawRRect(rr, Paint()..color=b.color.withValues(alpha:a)..style=PaintingStyle.stroke..strokeWidth=2.5);
    _txt(canvas,b.val.toString(),bx+bw/2,py+34*sc,34*sc,b.color.withValues(alpha:a),shadow:b.color,bold:true,extraGlow:24);
    _txt(canvas,b.msg,bx+bw/2,py+76*sc,12*sc,Colors.white.withValues(alpha:a*0.88));
  }

  void _txt(Canvas canvas, String text, double cx, double cy,
      double size, Color color, {Color? shadow, bool bold=false,
      double letterSpacing=0, double extraGlow=0}) {
    if (size < 1) return;
    final shadows = <Shadow>[
      Shadow(color:Colors.black.withValues(alpha:0.95),blurRadius:6,offset:const Offset(0,2)),
    ];
    if (shadow != null) {
      shadows.add(Shadow(color:shadow, blurRadius:16));
      if (extraGlow > 0) shadows.add(Shadow(color:shadow, blurRadius:extraGlow));
    }
    final tp = TextPainter(
      text:TextSpan(text:text, style:TextStyle(
        fontFamily:'monospace', fontSize:size,
        fontWeight:bold?FontWeight.bold:FontWeight.w600,
        color:color, letterSpacing:letterSpacing, shadows:shadows,
      )),
      textDirection:TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx-tp.width/2, cy-tp.height/2));
  }
}

// ─── Mevsim arkaplan efektleri ───────────────────────────────
class SnowFlake {
  double x, y, speed, size, wobble, wobbleSpeed, life;
  SnowFlake({required this.x, required this.y, required this.speed,
    required this.size, required this.wobble, required this.wobbleSpeed})
      : life = 1.0;
  void update(double dt) {
    y += speed * dt * 60; // sadece aşağı
    x += math.sin(wobble) * 0.0015; // çok az yatay salınım
    wobble += wobbleSpeed * dt * 0.3;
    if (y > 1.0) { y = -0.05; }
  }
}

class Lightning {
  double x, life, width;
  List<Offset> points;
  Color color;
  Lightning({required this.x, required this.points,
    required this.color, required this.width}) : life = 1.0;
  void update(double dt) { life -= dt * 4.0; }
}

class SeasonBgSystem {
  String? season;
  final math.Random _rng = math.Random();
  double _time = 0;

  final List<SnowFlake> _flakes = [];
  final List<Lightning> _lightnings = [];
  double _lightningTimer = 0;
  final List<_BgParticle> _bgParticles = [];
  final List<_ShuffleSymbol> _shuffleSymbols = [];
  final List<_BombDrop> _bombDrops = [];
  final List<_MultiplierDrop> _multiplierDrops = [];

  void setSeason(String? s) {
    if (season == s) return;
    season = s;
    _flakes.clear();
    _lightnings.clear();
    _bgParticles.clear();
    _shuffleSymbols.clear();
    _bombDrops.clear();
    _multiplierDrops.clear();
    _lightningTimer = 0;

    if (s == 'bomb') _initBombDrops();
    if (s == 'ice') _initSnow();
    if (s == 'multiplier') {
      _initMultiplierBg();
      _initMultiplierDrops();
    }
    if (s == 'shuffle') _initShuffleBg();
    if (s == 'mystery') _initShuffleBg(); // soru isaretleri icin sembol listesini override et

    if (s == 'mystery') {
      _shuffleSymbols.clear();
      for (int i = 0; i < 20; i++) {
        _shuffleSymbols.add(_ShuffleSymbol(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          symbol: '?',
          speed: 0.003 + _rng.nextDouble() * 0.005,
          phase: _rng.nextDouble() * math.pi * 2,
          size: 16 + _rng.nextDouble() * 20,
        ));
      }
    }
  }

  void _initSnow() {
    for (int i = 0; i < 100; i++) {
      _flakes.add(SnowFlake(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        speed: 0.00015 + _rng.nextDouble() * 0.0003,
        size: 4 + _rng.nextDouble() * 9,
        wobble: _rng.nextDouble() * math.pi * 2,
        wobbleSpeed: 0.2 + _rng.nextDouble() * 0.8,
      ));
    }
  }

  void _initMultiplierBg() {
    final cols = [
      const Color(0xFFC87FFF), const Color(0xFF5CF5E0),
      const Color(0xFFFF6FA8), const Color(0xFFF5E05C),
      const Color(0xFF44FF99), const Color(0xFFFF8833),
    ];
    for (int i = 0; i < 40; i++) {
      _bgParticles.add(_BgParticle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        vx: (_rng.nextDouble() - 0.5) * 0.002,
        vy: (_rng.nextDouble() - 0.5) * 0.002,
        size: 3 + _rng.nextDouble() * 8,
        color: cols[_rng.nextInt(cols.length)],
        phase: _rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _initShuffleBg() {
    const symbols = ['↔', '↕', '🔀', '⇄', '⇅'];
    for (int i = 0; i < 15; i++) {
      _shuffleSymbols.add(_ShuffleSymbol(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        symbol: symbols[_rng.nextInt(symbols.length)],
        speed: 0.004 + _rng.nextDouble() * 0.006,
        phase: _rng.nextDouble() * math.pi * 2,
        size: 14 + _rng.nextDouble() * 12,
      ));
    }
  }

  void _initBombDrops() {
    for (int i = 0; i < 12; i++) {
      _bombDrops.add(_BombDrop(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        speed: 0.003 + _rng.nextDouble() * 0.005,
        size: 14.4 + _rng.nextDouble() * 12,
        phase: _rng.nextDouble() * math.pi * 2,
        rotation: _rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _initMultiplierDrops() {
    final symbols = ['×2', '×4', '×8', '×16'];
    final colors = [
      const Color(0xFFFFD700), const Color(0xFFFF8C00),
      const Color(0xFFFF3CB4), const Color(0xFFC87FFF),
    ];
    for (int i = 0; i < 10; i++) {
      final idx = i % 4;
      _multiplierDrops.add(_MultiplierDrop(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        speed: 0.002 + _rng.nextDouble() * 0.004,
        symbol: symbols[idx],
        color: colors[idx],
        size: 13 + _rng.nextDouble() * 8,
        phase: _rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  Lightning _makeLightning(double boardX, double boardY, double bw, double bh) {
    final x = boardX + _rng.nextDouble() * bw;
    final points = <Offset>[];
    double cy = boardY;
    points.add(Offset(x, cy));
    while (cy < boardY + bh) {
      cy += 20 + _rng.nextDouble() * 40;
      final nx = x + (_rng.nextDouble() - 0.5) * 60;
      points.add(Offset(nx.clamp(boardX, boardX+bw), cy));
    }
    return Lightning(
      x: x,
      points: points,
      color: const Color(0xFFFF8800),
      width: 1.5 + _rng.nextDouble() * 2,
    );
  }

  void update(double dt, double boardX, double boardY, double bw, double bh) {
    _time += dt;
    if (season == null) return;

    if (season == 'ice') {
      for (final f in _flakes) {
        f.update(dt);
      }
    }

    if (season == 'bomb') {
      for (final b in _bombDrops) {
        b.y += b.speed;
        b.rotation += 0.02;
        b.phase += 0.05;
        if (b.y > 1.1) {
          b.y = -0.05;
          b.x = _rng.nextDouble();
        }
      }
    }

    if (season == 'speed') {
      _lightningTimer -= dt;
      if (_lightningTimer <= 0) {
        _lightningTimer = 0.15 + _rng.nextDouble() * 0.35;
        _lightnings.add(_makeLightning(boardX, boardY, bw, bh));
        if (_rng.nextDouble() > 0.5) {
          _lightnings.add(_makeLightning(boardX, boardY, bw, bh));
        }
      }
      _lightnings.removeWhere((l) => l.life <= 0);
      for (final l in _lightnings) {
        l.update(dt);
      }
    }

    if (season == 'multiplier') {
      for (final p in _bgParticles) {
        p.x += p.vx;
        p.y += p.vy;
        p.phase += dt * 2;
        if (p.x < 0) p.x = 1.0;
        if (p.x > 1) p.x = 0.0;
        if (p.y < 0) p.y = 1.0;
        if (p.y > 1) p.y = 0.0;
      }
      for (final d in _multiplierDrops) {
        d.y += d.speed;
        d.phase += dt * 1.5;
        if (d.y > 1.1) { d.y = -0.05; d.x = _rng.nextDouble(); }
      }
    }

    if (season == 'shuffle') {
      for (final s in _shuffleSymbols) {
        s.y += s.speed;
        s.phase += dt * 1.5;
        if (s.y > 1.1) s.y = -0.05;
      }
    }

    if (season == 'mystery') {
      for (final s in _shuffleSymbols) {
        s.y += s.speed;
        s.phase += dt * 1.2;
        if (s.y > 1.1) s.y = -0.05;
      }
    }
  }

  void render(Canvas canvas, double boardX, double boardY, double bw, double bh) {
    if (season == null) return;

    switch (season) {
      case 'ice':
        _renderIce(canvas, boardX, boardY, bw, bh);
        break;
      case 'bomb':
        _renderBomb(canvas, boardX, boardY, bw, bh);
        break;
      case 'speed':
        _renderSpeed(canvas, boardX, boardY, bw, bh);
        break;
      case 'multiplier':
        _renderMultiplier(canvas, boardX, boardY, bw, bh);
        break;
      case 'shuffle':
        _renderShuffle(canvas, boardX, boardY, bw, bh);
        break;
      case 'mystery':
        _renderMystery(canvas, boardX, boardY, bw, bh);
        break;
    }
  }

  void _renderIce(Canvas canvas, double bx, double by, double bw, double bh) {
    // Tüm ekran hafif buz tonu
    final pulse = 0.5 + math.sin(_time * 1.2) * 0.3;
    canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh),
      Paint()..color = const Color(0xFF88EEFF).withValues(alpha: 0.08 * pulse));

    // Tüm ekranı kaplayan buz dokusu — vignette tarzı
    canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh),
      Paint()..color = const Color(0xFFAADDFF).withValues(alpha: 0.05)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));

    // Kar taneleri — kristal şekil
    for (final f in _flakes) {
      final cx = bx + f.x * bw;
      final cy = by + f.y * bh;
      final a = (0.5 + math.sin(f.wobble) * 0.4).clamp(0.3, 1.0);
      final r = f.size;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(f.wobble * 0.3);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: a * 0.95)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final ex = math.cos(angle) * r;
        final ey = math.sin(angle) * r;
        canvas.drawLine(Offset.zero, Offset(ex, ey), paint);
        final mx = math.cos(angle) * r * 0.55;
        final my = math.sin(angle) * r * 0.55;
        final b1 = angle + math.pi / 6;
        final b2 = angle - math.pi / 6;
        canvas.drawLine(Offset(mx, my),
          Offset(mx + math.cos(b1)*r*0.35, my + math.sin(b1)*r*0.35), paint);
        canvas.drawLine(Offset(mx, my),
          Offset(mx + math.cos(b2)*r*0.35, my + math.sin(b2)*r*0.35), paint);
      }

      canvas.drawCircle(Offset.zero, r * 0.18,
        Paint()..color = Colors.white.withValues(alpha: a));
      canvas.drawCircle(Offset.zero, r,
        Paint()..color = const Color(0xFFBBEEFF).withValues(alpha: a * 0.12)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.restore();
    }

    // Buz çatlak çizgileri — dört köşede
    final crackPaint = Paint()
      ..color = const Color(0xFF88EEFF).withValues(alpha: 0.30)
      ..strokeWidth = 0.9;
    // Sol alt
    canvas.drawLine(Offset(bx, by+bh), Offset(bx+50, by+bh-80), crackPaint);
    canvas.drawLine(Offset(bx+50, by+bh-80), Offset(bx+25, by+bh-130), crackPaint);
    canvas.drawLine(Offset(bx+50, by+bh-80), Offset(bx+85, by+bh-100), crackPaint);
    // Sağ alt
    canvas.drawLine(Offset(bx+bw, by+bh), Offset(bx+bw-50, by+bh-80), crackPaint);
    canvas.drawLine(Offset(bx+bw-50, by+bh-80), Offset(bx+bw-25, by+bh-130), crackPaint);
    canvas.drawLine(Offset(bx+bw-50, by+bh-80), Offset(bx+bw-85, by+bh-100), crackPaint);
    // Sol üst
    canvas.drawLine(Offset(bx, by), Offset(bx+40, by+60), crackPaint);
    canvas.drawLine(Offset(bx+40, by+60), Offset(bx+70, by+40), crackPaint);
    // Sağ üst
    canvas.drawLine(Offset(bx+bw, by), Offset(bx+bw-40, by+60), crackPaint);
    canvas.drawLine(Offset(bx+bw-40, by+60), Offset(bx+bw-70, by+40), crackPaint);
  }

  void _renderBomb(Canvas canvas, double bx, double by, double bw, double bh) {
    // Guclu nabzeden kirmizi alarm
    final pulse = 0.5 + math.sin(_time * 4.0) * 0.5;
    final pulse2 = 0.5 + math.sin(_time * 4.0 + math.pi) * 0.5;

    canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh),
      Paint()..color = const Color(0xFFCC0000).withValues(alpha: pulse * 0.18));

    canvas.drawCircle(Offset(bx, by), bw * 0.7,
      Paint()..color = const Color(0xFFFF0000).withValues(alpha: pulse * 0.15)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35));
    canvas.drawCircle(Offset(bx+bw, by+bh), bw * 0.7,
      Paint()..color = const Color(0xFFFF0000).withValues(alpha: pulse2 * 0.15)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35));
    canvas.drawCircle(Offset(bx+bw, by), bw * 0.5,
      Paint()..color = const Color(0xFFFF4400).withValues(alpha: pulse2 * 0.12)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25));
    canvas.drawCircle(Offset(bx, by+bh), bw * 0.5,
      Paint()..color = const Color(0xFFFF4400).withValues(alpha: pulse * 0.12)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25));

    canvas.drawRect(Rect.fromLTWH(bx, by, bw, 6),
      Paint()..color = const Color(0xFFFF0000).withValues(alpha: pulse * 0.9));
    canvas.drawRect(Rect.fromLTWH(bx, by+bh-6, bw, 6),
      Paint()..color = const Color(0xFFFF0000).withValues(alpha: pulse2 * 0.9));

    for (int i = 0; i < 12; i++) {
      final t = (_time * 2 + i * 0.25) % 1.0;
      final sx = bx + (i / 12.0) * bw;
      final sy = by + bh - t * bh * 0.6;
      final sa = math.sin(t * math.pi) * 0.8;
      canvas.drawCircle(Offset(sx, sy), 3 + math.sin(t * math.pi) * 4,
        Paint()..color = const Color(0xFFFF6600).withValues(alpha: sa)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    // Düşen bomba animasyonları
    for (final b in _bombDrops) {
      final bx2 = bx + b.x * bw;
      final by2 = by + b.y * bh;
      final a = (0.35 + math.sin(b.phase) * 0.15).clamp(0.1, 0.55);

      canvas.save();
      canvas.translate(bx2, by2);
      canvas.rotate(b.rotation);

      // Bomba gövdesi
      canvas.drawCircle(Offset.zero, b.size/2,
        Paint()..color = const Color(0xFF222222).withValues(alpha: a));
      canvas.drawCircle(Offset.zero, b.size/2,
        Paint()..color = const Color(0xFFFF2200).withValues(alpha: a * 0.3)
               ..style = PaintingStyle.stroke..strokeWidth = 1.5);

      // Fitil
      final fPaint = Paint()
        ..color = const Color(0xFF888888).withValues(alpha: a)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(0, -b.size/2);
      path.quadraticBezierTo(b.size*0.4, -b.size*0.9, b.size*0.2, -b.size*1.2);
      canvas.drawPath(path, fPaint);

      // Fitil kor - yanıp söner
      final sparkA = (math.sin(b.phase * 4) * 0.5 + 0.5).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(b.size*0.2, -b.size*1.2), 2.5,
        Paint()..color = const Color(0xFFFFAA00).withValues(alpha: a * sparkA)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

      // Parlama
      canvas.drawCircle(Offset(-b.size*0.15, -b.size*0.1), b.size*0.2,
        Paint()..color = Colors.white.withValues(alpha: a * 0.3));

      canvas.restore();
    }

    // ⚠ Danger sembolü — ortada yanıp söner
    final dangerPulse2 = (math.sin(_time * 5.0) > 0) ? 1.0 : 0.0;
    final dangerA = 0.4 + dangerPulse2 * 0.5;
    final tp = TextPainter(
      text: TextSpan(text: '⚠', style: TextStyle(
        fontSize: 72,
        color: const Color(0xFFFF2200).withValues(alpha: dangerA),
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(bx+bw/2-tp.width/2, by+bh/2-tp.height/2));
    // Glow
    canvas.drawCircle(Offset(bx+bw/2, by+bh/2), 55,
      Paint()..color = const Color(0xFFFF2200).withValues(alpha: dangerA * 0.25)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
  }

  void _renderSpeed(Canvas canvas, double bx, double by, double bw, double bh) {
    // Turuncu tonu
    canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh),
      Paint()..color = const Color(0xFFFF8800).withValues(alpha: 0.05));

    // Şimşekler
    for (final l in _lightnings) {
      final a = l.life.clamp(0.0, 1.0);
      final path = Path();
      for (int i = 0; i < l.points.length; i++) {
        if (i == 0) {
          path.moveTo(l.points[i].dx, l.points[i].dy);
        } else {
          path.lineTo(l.points[i].dx, l.points[i].dy);
        }
      }
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFFFF8800).withValues(alpha: a * 0.4)
        ..strokeWidth = l.width * 6
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFFFFEE00).withValues(alpha: a * 0.9)
        ..strokeWidth = l.width
        ..style = PaintingStyle.stroke);
      canvas.drawPath(path, Paint()
        ..color = Colors.white.withValues(alpha: a * 0.8)
        ..strokeWidth = l.width * 0.4
        ..style = PaintingStyle.stroke);
    }

    // Küçük chevronlar — ekrana dağılmış
    for (int col = 0; col < 3; col++) {
      for (int layer = 0; layer < 4; layer++) {
        final t = (_time * 1.8 + layer * 0.28 + col * 0.15) % 1.0;
        final a = math.sin(t * math.pi) * 0.30;
        if (a <= 0) continue;

        final colX = bx + (col + 0.5) * (bw / 3);
        final offsetY = by + t * bh;
        const arrowW = 22.0;
        const arrowH = 12.0;

        final color = layer % 2 == 0
            ? const Color(0xFFFFCC00)
            : const Color(0xFFFF8800);

        final path = Path();
        path.moveTo(colX - arrowW / 2, offsetY - arrowH / 2);
        path.lineTo(colX, offsetY + arrowH / 2);
        path.lineTo(colX + arrowW / 2, offsetY - arrowH / 2);

        canvas.drawPath(path, Paint()
          ..color = color.withValues(alpha: a * 0.25)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawPath(path, Paint()
          ..color = color.withValues(alpha: a)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);
      }
    }

    // Enerji dalgası
    final energyR = ((_time * 1.5) % 1.0);
    canvas.drawCircle(Offset(bx+bw/2, by+bh/2), energyR * bw,
      Paint()..color = const Color(0xFFFF8800).withValues(alpha: (1-energyR) * 0.10)
             ..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _renderMultiplier(Canvas canvas, double bx, double by, double bw, double bh) {
    final cx = bx + bw/2, cy = by + bh/2;

    // Dönen gökkuşağı arka plan — sektörler halinde
    for (int i = 0; i < 8; i++) {
      final angle = _time * 0.5 + i * math.pi / 4;
      final hue = (_time * 60 + i * 45) % 360;
      final color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: bw*3, height: bh*3);
      canvas.drawArc(rect, angle, math.pi/4, true,
        Paint()..color = color.withValues(alpha: 0.06));
    }

    // Köşe glow — sürekli renk değişimi
    final cols = List.generate(4, (i) {
      final hue = (_time * 80 + i * 90) % 360;
      return HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
    });
    final corners = [
      Offset(bx, by), Offset(bx+bw, by),
      Offset(bx, by+bh), Offset(bx+bw, by+bh),
    ];
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(corners[i], bw * 0.65,
        Paint()..color = cols[i].withValues(alpha: 0.12)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
    }

    // Parlayan nokta parçacıkları
    for (final p in _bgParticles) {
      final px = bx + p.x * bw;
      final py = by + p.y * bh;
      final pulse = (0.3 + math.sin(p.phase + _time * 4) * 0.7).clamp(0.0, 1.0);
      final hue = (p.phase * 57 + _time * 60) % 360;
      final pColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

      // Büyük glow
      canvas.drawCircle(Offset(px, py), p.size * 2.5 * pulse,
        Paint()..color = pColor.withValues(alpha: pulse * 0.15)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      // Parlak merkez
      canvas.drawCircle(Offset(px, py), p.size * 0.4,
        Paint()..color = Colors.white.withValues(alpha: pulse * 0.9));
      // Renkli halka
      canvas.drawCircle(Offset(px, py), p.size * pulse,
        Paint()..color = pColor.withValues(alpha: pulse * 0.6)
               ..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // Yıldız parıltıları — rastgele
    for (int i = 0; i < 8; i++) {
      final t = (_time * 2 + i * 0.4) % 1.0;
      final starX = bx + ((math.sin(i * 1.7 + _time * 0.3) + 1) / 2) * bw;
      final starY = by + ((math.cos(i * 2.1 + _time * 0.2) + 1) / 2) * bh;
      final starA = math.sin(t * math.pi) * 0.7;
      final hue2 = (_time * 120 + i * 45) % 360;
      final starColor = HSVColor.fromAHSV(1.0, hue2, 1.0, 1.0).toColor();

      // Yıldız çizgileri
      final sp = Paint()..color = starColor.withValues(alpha: starA)..strokeWidth = 1.5;
      canvas.drawLine(Offset(starX-8, starY), Offset(starX+8, starY), sp);
      canvas.drawLine(Offset(starX, starY-8), Offset(starX, starY+8), sp);
      canvas.drawLine(Offset(starX-5, starY-5), Offset(starX+5, starY+5), sp);
      canvas.drawLine(Offset(starX+5, starY-5), Offset(starX-5, starY+5), sp);
      canvas.drawCircle(Offset(starX, starY), 3,
        Paint()..color = Colors.white.withValues(alpha: starA));
    }

    // Gökten yağan çarpan blokları
    for (final d in _multiplierDrops) {
      final dx = bx + d.x * bw;
      final dy = by + d.y * bh;
      final a = (0.4 + math.sin(d.phase) * 0.25).clamp(0.15, 0.7);
      const s = 28.0;

      // Renkli blok arka planı
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(dx-s/2, dy-s/2, s, s), const Radius.circular(6)),
        Paint()..color = d.color.withValues(alpha: a * 0.85));

      // Üst parlaklık
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(dx-s/2+2, dy-s/2+2, s-4, s*0.4), const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: a * 0.35));

      // Kenarlık
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(dx-s/2, dy-s/2, s, s), const Radius.circular(6)),
        Paint()..color = Colors.white.withValues(alpha: a * 0.3)
               ..style = PaintingStyle.stroke..strokeWidth = 1.2);

      // Dış glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(dx-s/2-3, dy-s/2-3, s+6, s+6), const Radius.circular(8)),
        Paint()..color = d.color.withValues(alpha: a * 0.25)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

      // Sembol yazısı
      final tp = TextPainter(
        text: TextSpan(text: d.symbol, style: TextStyle(
          fontFamily: 'monospace', fontSize: d.size * 0.7,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: a),
          shadows: [Shadow(color: d.color, blurRadius: 8)],
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(dx - tp.width/2, dy - tp.height/2));
    }
  }

  void _renderShuffle(Canvas canvas, double bx, double by, double bw, double bh) {
    final cx = bx + bw/2;
    final cy = by + bh/2;

    final cols = [
      const Color(0xFFFF88FF), const Color(0xFF8844FF),
      const Color(0xFFFF44AA), const Color(0xFF4488FF),
      const Color(0xFFFF8844), const Color(0xFF44FFAA),
    ];
    for (int i = 0; i < 6; i++) {
      final angle = _time * 0.8 + i * math.pi / 3;
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: bw*2, height: bh*2);
      canvas.drawArc(rect, angle, math.pi/3, true,
        Paint()..color = cols[i % cols.length].withValues(alpha: 0.04));
    }

    canvas.drawCircle(Offset(cx, cy), bw * 0.7,
      Paint()..color = const Color(0xFFFF88FF).withValues(alpha: 0.06)
             ..style = PaintingStyle.stroke..strokeWidth = 8);

    for (final s in _shuffleSymbols) {
      final sx = bx + s.x * bw;
      final sy = by + s.y * bh;
      final a = (0.2 + math.sin(s.phase + _time) * 0.15).clamp(0.05, 0.4);
      canvas.save();
      canvas.translate(sx, sy);
      canvas.rotate(math.sin(s.phase + _time * 0.5) * 0.5);
      final tp = TextPainter(
        text: TextSpan(text: s.symbol, style: TextStyle(
          fontSize: s.size,
          color: const Color(0xFFFF88FF).withValues(alpha: a),
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width/2, -tp.height/2));
      canvas.restore();
    }

    for (int i = 0; i < 6; i++) {
      final t = (_time * 1.2 + i * 0.2) % 1.0;
      final startX = bx + (i % 2 == 0 ? t * bw : bw - t * bw);
      final startY = by + (i / 6.0) * bh;
      final endX = bx + ((i % 2 == 0 ? t + 0.2 : 0.8 - t).clamp(0.0, 1.0)) * bw;
      canvas.drawLine(Offset(startX, startY), Offset(endX, startY + 20),
        Paint()..color = const Color(0xFFAA44FF).withValues(
            alpha: math.sin(t * math.pi) * 0.25)
               ..strokeWidth = 1.5);
    }
  }

  void _renderMystery(Canvas canvas, double bx, double by, double bw, double bh) {
    final pulse = 0.5 + math.sin(_time * 1.8) * 0.5;
    final cx = bx + bw/2, cy = by + bh/2;

    // Koyu dedektif arka plani
    canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh),
      Paint()..color = const Color(0xFF080808).withValues(alpha: 0.35));

    // Merkez spot isigi - dedektif lambasi hissi
    canvas.drawCircle(Offset(cx, by + bh*0.3), bw * 0.8,
      Paint()..color = Colors.white.withValues(alpha: 0.04 * pulse)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50));

    // Donen buyutec sembolleri
    for (int i = 0; i < 4; i++) {
      final angle = _time * 0.4 + i * math.pi / 2;
      final r = bw * 0.35;
      final mx = cx + math.cos(angle) * r;
      final my = cy + math.sin(angle) * r;
      final a = (0.08 + math.sin(_time * 1.5 + i) * 0.05).clamp(0.03, 0.15);

      final tp = TextPainter(
        text: TextSpan(text: '🔍', style: TextStyle(fontSize: 18 + math.sin(_time + i).abs() * 6)),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(mx, my);
      canvas.rotate(angle + math.pi/4);
      canvas.drawRect(Rect.fromLTWH(-tp.width/2, -tp.height/2, tp.width, tp.height),
        Paint()..color = Colors.transparent);
      canvas.restore();

      // Buyutec cam efekti - daire
      canvas.drawCircle(Offset(mx, my), 14 + math.sin(_time + i) * 3,
        Paint()..color = Colors.white.withValues(alpha: a * 0.6)
               ..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.drawCircle(Offset(mx, my), 14 + math.sin(_time + i) * 3,
        Paint()..color = const Color(0xFF8888FF).withValues(alpha: a * 0.2));
      // Buyutec sapi
      final handleAngle = angle + math.pi * 0.75;
      canvas.drawLine(
        Offset(mx + math.cos(handleAngle)*12, my + math.sin(handleAngle)*12),
        Offset(mx + math.cos(handleAngle)*22, my + math.sin(handleAngle)*22),
        Paint()..color = Colors.white.withValues(alpha: a)..strokeWidth = 2.5,
      );
    }

    // Soru isaretleri yagiyor - buyuk ve gizemli
    for (final s in _shuffleSymbols) {
      final sx = bx + s.x * bw;
      final sy = by + s.y * bh;
      final a = (0.08 + math.sin(s.phase + _time * 0.8) * 0.06).clamp(0.02, 0.18);

      canvas.save();
      canvas.translate(sx, sy);
      canvas.rotate(math.sin(s.phase) * 0.3);
      final tp = TextPainter(
        text: TextSpan(text: '?', style: TextStyle(
          fontSize: s.size,
          color: Colors.white.withValues(alpha: a),
          fontWeight: FontWeight.bold,
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width/2, -tp.height/2));
      canvas.restore();

      // Glow
      canvas.drawCircle(Offset(sx, sy), s.size * 0.6,
        Paint()..color = Colors.white.withValues(alpha: a * 0.3)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    // Dedektif ipucu cizgileri - ince baglanti cizgileri
    for (int i = 0; i < 5; i++) {
      final t = (_time * 0.5 + i * 0.3) % 1.0;
      final x1 = bx + (math.sin(i * 1.3 + _time * 0.2) + 1) / 2 * bw;
      final y1 = by + (math.cos(i * 1.7 + _time * 0.15) + 1) / 2 * bh;
      final x2 = bx + (math.sin(i * 2.1 + _time * 0.3) + 1) / 2 * bw;
      final y2 = by + (math.cos(i * 0.9 + _time * 0.25) + 1) / 2 * bh;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2),
        Paint()..color = Colors.white.withValues(alpha: 0.04 + math.sin(t * math.pi) * 0.04)
               ..strokeWidth = 0.8);
    }

    // Nabzeden beyaz kenar
    canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh),
      Paint()..color = Colors.white.withValues(alpha: pulse * 0.05)
             ..style = PaintingStyle.stroke..strokeWidth = 2);
  }
}

class _BgParticle {
  double x, y, vx, vy, size, phase;
  Color color;
  _BgParticle({required this.x, required this.y, required this.vx,
    required this.vy, required this.size, required this.color,
    required this.phase});
}

class _ShuffleSymbol {
  double x, y, speed, phase, size;
  String symbol;
  _ShuffleSymbol({required this.x, required this.y, required this.speed,
    required this.phase, required this.size, required this.symbol});
}

class _BombDrop {
  double x, y, speed, size, phase, rotation;
  _BombDrop({required this.x, required this.y, required this.speed,
    required this.size, required this.phase, required this.rotation});
}

class _MultiplierDrop {
  double x, y, speed, size, phase;
  String symbol;
  Color color;
  _MultiplierDrop({required this.x, required this.y, required this.speed,
    required this.size, required this.phase,
    required this.symbol, required this.color});
}