import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../achievement_data.dart';
import '../achievement_manager.dart';
import '../l10n.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final List<Object> _items = [];

  @override
  void initState() {
    super.initState();
    _buildItems();
  }

  void _buildItems() {
    final catList = <MapEntry<AchievementCategory, String>>[
      MapEntry(AchievementCategory.skor,   L10n.t('ach_cat_skor')),
      MapEntry(AchievementCategory.blok,   L10n.t('ach_cat_blok')),
      MapEntry(AchievementCategory.oyun,   L10n.t('ach_cat_oyun')),
      MapEntry(AchievementCategory.gun,    L10n.t('ach_cat_gun')),
      MapEntry(AchievementCategory.mevsim, L10n.t('ach_cat_mevsim')),
      MapEntry(AchievementCategory.level,  L10n.t('ach_cat_level')),
    ];
    for (final entry in catList) {
      final all = kAchievements.where((a) => a.category == entry.key).toList();
      // Tamamlanmayanlar önce, tamamlananlar sona
      all.sort((a, b) {
        final aDone = AchievementManager.isCompleted(a) ? 1 : 0;
        final bDone = AchievementManager.isCompleted(b) ? 1 : 0;
        return aDone - bDone;
      });
      _items.add(entry.value);
      _items.addAll(all);
    }
  }

  // ── Sayı formatlayıcı ────────────────────────────────────────────────────

  String _fmt(int v) {
    if (v >= 1000000000) {
      final d = v / 1000000000;
      return '${d == d.truncateToDouble() ? d.toInt() : d.toStringAsFixed(1)}B';
    }
    if (v >= 1000000) {
      final d = v / 1000000;
      return '${d == d.truncateToDouble() ? d.toInt() : d.toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      final d = v / 1000;
      return '${d == d.truncateToDouble() ? d.toInt() : d.toStringAsFixed(1)}K';
    }
    return v.toString();
  }

  String _progressText(Achievement ach) {
    final raw = AchievementManager.progress[ach.id] ?? 0;
    final clamped = raw > ach.target ? ach.target : raw;
    return '${_fmt(clamped)}/${_fmt(ach.target)}';
  }

  double _progressValue(Achievement ach) {
    final raw = AchievementManager.progress[ach.id] ?? 0;
    if (raw >= ach.target) return 1.0;
    return raw / ach.target;
  }

  // ── Kategori renk / ikon ─────────────────────────────────────────────────

  Color _catColor(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.skor:   return const Color(0xFFF59E0B);
      case AchievementCategory.blok:   return const Color(0xFF3B82F6);
      case AchievementCategory.oyun:   return const Color(0xFF10B981);
      case AchievementCategory.gun:    return const Color(0xFF06B6D4);
      case AchievementCategory.mevsim: return const Color(0xFF8B5CF6);
      case AchievementCategory.level:  return const Color(0xFFEF4444);
    }
  }

  IconData _catIcon(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.skor:   return Icons.star_rounded;
      case AchievementCategory.blok:   return Icons.grid_view_rounded;
      case AchievementCategory.oyun:   return Icons.sports_esports_rounded;
      case AchievementCategory.gun:    return Icons.calendar_today_rounded;
      case AchievementCategory.mevsim: return Icons.ac_unit_rounded;
      case AchievementCategory.level:  return Icons.military_tech_rounded;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final completed = AchievementManager.completedCount;
    final total = kAchievements.length;
    final prog = AchievementManager.totalProgress;
    final pct = (prog * 100).round();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka plan
          Positioned.fill(
            child: Image.asset('assets/images/basarim_arka.png', fit: BoxFit.fill),
          ),

          SafeArea(
            child: LayoutBuilder(builder: (_, sc) {
              final sw = sc.maxWidth;
              final sh = sc.maxHeight;

              // Kart boyutu (bağımsız konumlandırma için)
              final cardW = sw * 0.869;
              final cardH = cardW * 610 / 1619;
              const cardTop = 26.0;

              // Liste: orijinal konumu (kart top:6, widthFactor:0.75 iken)
              final origCardH = sw * 0.75 * 610 / 1619;
              final listTop = 6.0 + origCardH + 8.0;

              // Slot hesabı
              final navH = MediaQuery.of(context).size.height * 0.18;
              const topPad = 28.0;
              final availH = sh - listTop - navH;
              // 96: _buildCard içeriği (ikon + başlık/açıklama/progress + dikey padding)
              // bu yükseklikten azına sığmıyor; daha düşük bir taban Column'un
              // RenderFlex overflow vermesine yol açıyor (dar ekranlarda gözlendi).
              final slotH = ((availH - topPad) / 5).clamp(96.0, double.infinity);
              final renderH = topPad + slotH * 5;
              final hPad = 28.0 + sw * 0.10;

              return Stack(
                children: [
                  // ── Başarım listesi — kart altında ──
                  Positioned(
                    top: listTop,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: SizedBox(
                        height: renderH,
                        child: ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(hPad - 16, topPad, hPad + 16, 0),
                          itemCount: _items.length,
                          itemBuilder: (ctx2, index) {
                            final item = _items[index];
                            if (item is String) return _buildHeader(item, slotH: slotH);
                            if (item is Achievement) {
                              return SizedBox(height: slotH, child: _buildCard(item, slotH: slotH));
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ),

                  // ── basarim.png kartı — listenin üzerinde ──
                  Positioned(
                    top: cardTop,
                    left: 12,
                    right: 12,
                    height: cardH,
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.869,
                        child: AspectRatio(
                          aspectRatio: 1619 / 610,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: LayoutBuilder(builder: (_, c) {
                              final w = c.maxWidth;
                              final h = c.maxHeight;
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset('assets/images/basarim.png', fit: BoxFit.fill),
                                  Positioned(
                                    left: w * 0.36, top: h * 0.10, right: w * 0.04,
                                    child: Text(L10n.t('ach_total_progress'),
                                      textScaler: TextScaler.noScaling,
                                      style: GoogleFonts.poppins(fontSize: h * 0.133, fontWeight: FontWeight.w800, color: const Color(0xFF1E3A8A)),
                                    ),
                                  ),
                                  Positioned(
                                    left: w * 0.37, top: h * 0.35, right: w * 0.18, height: h * 0.12,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(children: [
                                        Container(color: Colors.black12),
                                        FractionallySizedBox(
                                          widthFactor: prog.clamp(0.0, 1.0),
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)]),
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ),
                                  Positioned(
                                    right: w * 0.04, top: h * 0.30,
                                    child: Text('%$pct',
                                      textScaler: TextScaler.noScaling,
                                      style: GoogleFonts.poppins(fontSize: h * 0.137, fontWeight: FontWeight.w800, color: const Color(0xFF1E3A8A)),
                                    ),
                                  ),
                                  Positioned(
                                    left: w * 0.46, bottom: h * 0.23,
                                    child: Text('$completed/$total',
                                      textScaler: TextScaler.noScaling,
                                      style: GoogleFonts.poppins(fontSize: h * 0.153, fontWeight: FontWeight.w800, color: const Color(0xFF1E3A8A)),
                                    ),
                                  ),
                                  Positioned(
                                    left: w * 0.46, bottom: h * 0.10,
                                    child: Text(L10n.t('ach_achieved_label'),
                                      textScaler: TextScaler.noScaling,
                                      style: GoogleFonts.poppins(fontSize: h * 0.095, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Kategori başlığı ─────────────────────────────────────────────────────

  Widget _buildHeader(String label, {double slotH = 60}) {
    return SizedBox(
      height: slotH * 0.45,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            textScaler: TextScaler.noScaling,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  // ── Başarım kartı ─────────────────────────────────────────────────────────

  Widget _buildCard(Achievement ach, {double slotH = 80}) {
    final done = AchievementManager.isCompleted(ach);
    final prog = _progressValue(ach);
    final color = _catColor(ach.category);
    final gap = slotH * 0.15;

    return Opacity(
      opacity: done ? 0.65 : 1.0,
      child: Container(
      margin: EdgeInsets.only(bottom: gap),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            // İkon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ach.iconAsset.isNotEmpty
                  ? Image.asset(ach.iconAsset, fit: BoxFit.contain)
                  : Icon(_catIcon(ach.category), color: color, size: 22),
            ),
            const SizedBox(width: 10),

            // Orta: isim + açıklama + progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ach.localTitle,
                    textScaler: TextScaler.noScaling,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    ach.localDesc,
                    textScaler: TextScaler.noScaling,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Progress bar + metin
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 14,
                          child: Stack(
                            children: [
                              Container(color: const Color(0xFFE2E8F0)),
                              FractionallySizedBox(
                                widthFactor: prog,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: done
                                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                          : [const Color(0xFF22C55E), const Color(0xFF16A34A)],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        _progressText(ach),
                        textScaler: TextScaler.noScaling,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Color(0x66000000), blurRadius: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Sağ: tamamlandı / devam
            done
                ? Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18),
                  )
                : CustomPaint(
                    size: const Size(28, 28),
                    painter: _DashedCirclePainter(),
                  ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Kesikli çember (devam eden başarım) ──────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    const dashCount = 10;
    final dashAngle = 2 * math.pi / dashCount;
    const gapRatio = 0.38;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapRatio);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}
