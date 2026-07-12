import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n.dart';

// ═══════════════════════════════════════════════════════════
// Bar bozulma animasyonu — oyuncu bir elde 1.000.000+ bloğa
// ulaştığında meter barının çatlayıp patlamasını canlandırır.
// AŞAMALAR: freeze → crack → shake → explode → announce → (done, kalıcı kalıntı)
// ═══════════════════════════════════════════════════════════
enum _Phase { freeze, crack, shake, explode, announce }

class _Shard {
  double ox, oy; // bar merkezine göre offset (px)
  double vx, vy;
  double rot, vrot;
  double life;
  final double size;
  final bool isSquare;
  _Shard({
    required this.ox,
    required this.oy,
    required this.vx,
    required this.vy,
    required this.rot,
    required this.vrot,
    required this.life,
    required this.size,
    required this.isSquare,
  });

  void update(double dt) {
    ox += vx * dt;
    oy += vy * dt;
    vy += 420 * dt; // yerçekimi
    vx *= 0.985;
    rot += vrot * dt;
    life -= dt * 0.6;
  }
}

class BarBreakEffect {
  _Phase phase = _Phase.freeze;
  double phaseTime = 0;
  bool done = false;

  final math.Random _rng = math.Random();
  final List<_Shard> _shards = [];
  double _pulseTime = 0;

  static const double _freezeDur = 0.5;
  static const double _crackDur = 1.3;
  static const double _shakeDur = 0.55;
  static const double _explodeDur = 0.35;
  static const double _announceDur = 2.4;

  double get shakeIntensity {
    switch (phase) {
      case _Phase.shake:
        return 0.5 + (phaseTime / _shakeDur) * 1.0;
      case _Phase.explode:
        return 1.4 * (1 - (phaseTime / _explodeDur)).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  Offset shakeOffset = Offset.zero;

  void update(double dt) {
    _pulseTime += dt;
    if (done) {
      shakeOffset = Offset.zero;
      return;
    }
    phaseTime += dt;
    for (final s in _shards) {
      s.update(dt);
    }
    final shakeAmt = shakeIntensity;
    shakeOffset = shakeAmt > 0
        ? Offset(
            (_rng.nextDouble() - 0.5) * shakeAmt * 5,
            (_rng.nextDouble() - 0.5) * shakeAmt * 5,
          )
        : Offset.zero;
    switch (phase) {
      case _Phase.freeze:
        if (phaseTime >= _freezeDur) {
          phase = _Phase.crack;
          phaseTime = 0;
        }
      case _Phase.crack:
        if (phaseTime >= _crackDur) {
          phase = _Phase.shake;
          phaseTime = 0;
        }
      case _Phase.shake:
        if (phaseTime >= _shakeDur) {
          phase = _Phase.explode;
          phaseTime = 0;
          _spawnShards();
        }
      case _Phase.explode:
        if (phaseTime >= _explodeDur) {
          phase = _Phase.announce;
          phaseTime = 0;
        }
      case _Phase.announce:
        if (phaseTime >= _announceDur) {
          done = true;
        }
    }
  }

  void _spawnShards() {
    final cols = [
      const Color(0xFFFFD54A),
      const Color(0xFFFFB300),
      const Color(0xFF5A3A00),
      Colors.white,
    ];
    for (int i = 0; i < 30; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 70 + _rng.nextDouble() * 240;
      _shards.add(_Shard(
        ox: (_rng.nextDouble() - 0.5) * 20,
        oy: (_rng.nextDouble() - 0.5) * 10,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 90,
        rot: _rng.nextDouble() * math.pi * 2,
        vrot: (_rng.nextDouble() - 0.5) * 10,
        life: 1.0,
        size: 4 + _rng.nextDouble() * 8,
        isSquare: _rng.nextBool(),
      ));
      _shardColors.add(cols[_rng.nextInt(cols.length)]);
    }
  }

  final List<Color> _shardColors = [];

  // Barın ÜZERİNE çizilir — orijinal bar görseli her zaman altta kalır ve
  // asla kaldırılmaz; bu katman çizik/çatlak yerine dijital bir "BOZULDU"
  // uyarısı (tarama çizgileri + tehlike şeridi + titreşen yazı) ekler.
  // uiScale ile ölçeklenmiş dünya koordinatında, çağıran tarafın uyguladığı
  // `shakeOffset` ile aynı hizada olması için kendi çevirisini de yapar.
  void renderBar(Canvas canvas, Rect barRect) {
    canvas.save();
    canvas.translate(shakeOffset.dx, shakeOffset.dy);

    // Uyarı belirme ilerlemesi — crack aşamasında yavaşça belirir, sonrasında kalıcı kalır.
    final progress = switch (phase) {
      _Phase.freeze => 0.0,
      _Phase.crack => (phaseTime / _crackDur).clamp(0.0, 1.0),
      _ => 1.0,
    };
    if (progress > 0) {
      final glitchIntensity = switch (phase) {
        _Phase.shake => (phaseTime / _shakeDur).clamp(0.0, 1.0),
        _Phase.explode => 1.0,
        _ => 0.0,
      };
      _renderDigitalWarning(canvas, barRect, progress, glitchIntensity);
    }

    if (phase == _Phase.explode || done || phase == _Phase.announce) {
      _renderShards(canvas, barRect);
    }

    canvas.restore();
  }

  void _renderDigitalWarning(
    Canvas canvas,
    Rect r,
    double progress,
    double glitchIntensity,
  ) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)));

    // Karanlık kırmızı dijital taban
    canvas.drawRect(
      r,
      Paint()..color = const Color(0xFF1A0000).withValues(alpha: progress * 0.6),
    );

    // Tarama çizgileri (scanline)
    for (double y = r.top + 2; y < r.bottom; y += 3.5) {
      canvas.drawLine(
        Offset(r.left, y),
        Offset(r.right, y),
        Paint()
          ..color = Colors.black.withValues(alpha: progress * 0.22)
          ..strokeWidth = 1,
      );
    }

    // Tehlike şeridi — üst ve alt ince sarı/siyah şerit
    _renderHazardStripe(
      canvas,
      Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.14),
      progress,
    );
    _renderHazardStripe(
      canvas,
      Rect.fromLTWH(r.left, r.bottom - r.height * 0.14, r.width, r.height * 0.14),
      progress,
    );

    // Glitch blokları — sadece titreşim yoğunken (shake/explode)
    if (glitchIntensity > 0) {
      final blocks = 2 + (glitchIntensity * 4).round();
      for (int i = 0; i < blocks; i++) {
        final gy = r.top + _rng.nextDouble() * r.height;
        final gh = 1.5 + _rng.nextDouble() * 3.5;
        final gx = r.left + (_rng.nextDouble() - 0.5) * 14 * glitchIntensity;
        final gw = r.width * (0.2 + _rng.nextDouble() * 0.5);
        canvas.drawRect(
          Rect.fromLTWH(gx, gy, gw, gh),
          Paint()
            ..color = (_rng.nextBool()
                    ? const Color(0xFF00FFFF)
                    : const Color(0xFFFF0033))
                .withValues(alpha: 0.3 + glitchIntensity * 0.25),
        );
      }
    }

    canvas.restore();

    // "BOZULDU" yazısı — dijital titreşim/blink
    final blink = glitchIntensity > 0
        ? (0.55 + math.sin(phaseTime * 45) * 0.45).clamp(0.0, 1.0)
        : (0.7 + math.sin(_pulseTime * 2.4) * 0.3);
    final jitterX = glitchIntensity > 0
        ? (_rng.nextDouble() - 0.5) * 3 * glitchIntensity
        : 0.0;
    _txt(
      canvas,
      L10n.t('bar_broken_label'),
      r.center.dx + jitterX,
      r.center.dy,
      math.min(r.height * 0.55, 16.0),
      const Color(0xFFFF3B30).withValues(alpha: progress * blink),
      glow: const Color(0xFFFF0000),
      letterSpacing: 3,
    );
  }

  void _renderHazardStripe(Canvas canvas, Rect r, double alpha) {
    const stripeW = 10.0;
    final count = (r.width / stripeW).ceil();
    for (int i = 0; i < count; i++) {
      final x = r.left + i * stripeW;
      canvas.drawRect(
        Rect.fromLTWH(x, r.top, stripeW, r.height),
        Paint()
          ..color = (i.isEven ? const Color(0xFFFFCC00) : const Color(0xFF1A1A1A))
              .withValues(alpha: alpha * 0.85),
      );
    }
  }

  void _renderShards(Canvas canvas, Rect r) {
    final cx = r.center.dx, cy = r.center.dy;
    for (int i = 0; i < _shards.length; i++) {
      final s = _shards[i];
      if (s.life <= 0) continue;
      final a = s.life.clamp(0.0, 1.0);
      final col = _shardColors[i % _shardColors.length].withValues(alpha: a);
      canvas.save();
      canvas.translate(cx + s.ox, cy + s.oy);
      canvas.rotate(s.rot);
      final sz = s.size * (0.5 + a * 0.5);
      if (s.isSquare) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: sz, height: sz),
          Paint()..color = col,
        );
      } else {
        canvas.drawCircle(Offset.zero, sz / 2, Paint()..color = col);
      }
      canvas.restore();
    }
  }

  // Tam ekran efektler (flash + "BAR BOZULDU!" yazısı) — ölçeklenmemiş ekran koordinatında.
  void renderFullScreen(Canvas canvas, double sw, double sh) {
    if (done) return;
    if (phase == _Phase.explode) {
      _renderFlash(canvas, sw, sh);
    } else if (phase == _Phase.announce) {
      _renderAnnounce(canvas, sw, sh);
    }
  }

  void _renderFlash(Canvas canvas, double sw, double sh) {
    final p = (phaseTime / _explodeDur).clamp(0.0, 1.0);
    final a = p < 0.5 ? p * 2 : (1 - (p - 0.5) * 2);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sw, sh),
      Paint()..color = Colors.white.withValues(alpha: a * 0.85),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sw, sh),
      Paint()..color = const Color(0xFF66CCFF).withValues(alpha: a * 0.25),
    );
  }

  void _renderAnnounce(Canvas canvas, double sw, double sh) {
    final t = phaseTime;
    final cx = sw / 2, cy = sh / 2;

    final bgA = t < 0.25
        ? (t / 0.25).clamp(0.0, 1.0)
        : t > _announceDur - 0.5
            ? (1 - (t - (_announceDur - 0.5)) / 0.5).clamp(0.0, 1.0)
            : 1.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sw, sh),
      Paint()..color = const Color(0xFF15080A).withValues(alpha: bgA * 0.55),
    );

    // Başlık — scale up + glow (overshoot)
    final titleT = (t / 0.45).clamp(0.0, 1.0);
    final eased = titleT < 1.0
        ? 1 - math.pow(1 - titleT, 3).toDouble()
        : 1.0;
    final overshoot = titleT < 1.0 ? 1.0 + math.sin(titleT * math.pi) * 0.18 : 1.0;
    final titleA = bgA * eased;

    canvas.save();
    canvas.translate(cx, cy - 26);
    canvas.scale(0.5 + eased * 0.5 * overshoot);
    canvas.translate(-cx, -(cy - 26));
    _txt(
      canvas,
      L10n.t('bar_broken_title'),
      cx,
      cy - 26,
      34,
      const Color(0xFFFF5040).withValues(alpha: titleA),
      glow: const Color(0xFFFF2000),
      letterSpacing: 2,
    );
    canvas.restore();

    // Alt yazı — fade in
    if (t > 0.35) {
      final subA = bgA * ((t - 0.35) / 0.35).clamp(0.0, 1.0);
      _txt(
        canvas,
        L10n.t('bar_broken_subtitle'),
        cx,
        cy + 26,
        15,
        const Color(0xFFFFC24A).withValues(alpha: subA),
        letterSpacing: 1,
      );
    }
  }

  void _txt(
    Canvas canvas,
    String text,
    double cx,
    double cy,
    double size,
    Color color, {
    Color? glow,
    bool bold = true,
    double letterSpacing = 0,
  }) {
    final shadows = <Shadow>[
      Shadow(color: Colors.black.withValues(alpha: 0.95), blurRadius: 6, offset: const Offset(0, 3)),
    ];
    if (glow != null) {
      shadows.add(Shadow(color: glow, blurRadius: 16));
      shadows.add(Shadow(color: glow, blurRadius: 32));
    }
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
          letterSpacing: letterSpacing,
          shadows: shadows,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: cx * 1.8);
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }
}
