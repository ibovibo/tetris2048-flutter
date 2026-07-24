import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../daily_quest_data.dart';
import '../daily_quest_manager.dart';
import '../l10n.dart';

class DailyQuestScreen extends StatefulWidget {
  const DailyQuestScreen({super.key});

  @override
  State<DailyQuestScreen> createState() => _DailyQuestScreenState();
}

class _DailyQuestScreenState extends State<DailyQuestScreen> {
  Timer? _tickTimer;
  bool _watchingAd = false;
  late Set<String> _completedIds;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _completedIds = DailyQuestManager.todaysQuests
        .where((q) => q.completed)
        .map((q) => q.template.id)
        .toSet();
    _timeLeft = _timeUntilReset();
    // Görev ilerlemeleri arka planda değişebilir (aktif süre vb.) ve
    // yenilenme sayacının canlı akması gerekir — saniyede bir tazele.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft = _timeUntilReset());
      _checkNewlyCompleted();
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Duration _timeUntilReset() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    return nextMidnight.difference(now);
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // Arka planda (aktif süre vb.) tamamlanan görevleri yakalayıp altın efektini gösterir.
  void _checkNewlyCompleted() {
    for (final q in DailyQuestManager.todaysQuests) {
      if (q.completed && !_completedIds.contains(q.template.id)) {
        _completedIds.add(q.template.id);
        _showGoldToast(q.template.goldReward);
      }
    }
  }

  void _showGoldToast(int amount) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E3A8A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              '+$amount',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _watchAd() async {
    setState(() => _watchingAd = true);
    // TODO: gerçek rewarded reklam SDK entegrasyonu (AdMob/AppLovin)
    await Future<void>.delayed(const Duration(seconds: 1));
    await DailyQuestManager.completeWatchAd();
    _checkNewlyCompleted();
    if (mounted) setState(() => _watchingAd = false);
  }

  // ── Görev kartı ───────────────────────────────────────────────────────────

  Widget _buildQuestCard(DailyQuest q) {
    final isAd = q.template.type == QuestType.watchAd;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questDescription(q.template),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 6),
                if (!isAd) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (q.progress / q.template.target).clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: q.completed
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    q.template.type == QuestType.reachScore
                        ? '${formatShortNumber(q.progress > q.template.target ? q.template.target : q.progress)}/${formatShortNumber(q.template.target)}'
                        : '${formatQuestNumber(q.progress > q.template.target ? q.template.target : q.progress)}/${formatQuestNumber(q.template.target)}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isAd && !q.completed)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: _watchingAd ? null : _watchAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: _watchingAd
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          L10n.t('watch_button'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                ),
              ),
            )
          else
            _goldBadge(q.template.goldReward),
        ],
      ),
    );
  }

  Widget _goldBadge(int amount) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/altın.png', width: 20, height: 20),
          const SizedBox(width: 5),
          Text(
            '$amount',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  // ── Asset üzerine bindirilen içerik ─────────────────────────────────────────

  Widget _buildPopupContent(double w, double h) {
    final quests = DailyQuestManager.todaysQuests;
    final realQuests = quests.where((q) => q.template.type != QuestType.watchAd).toList();
    final completed = realQuests.where((q) => q.completed).length;
    final total = realQuests.length;
    final barProgress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

    // Ölçülen asset koordinatları (1024x1536 kaynak görsel üzerinden yüzdesel).
    const barLeft = 0.114, barRight = 0.798, barCenterY = 0.229, barHeight = 0.046;
    const whiteLeft = 0.07, whiteRight = 0.93, whiteTop = 0.295, whiteBottom = 0.91;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/gunlukgorev.png', fit: BoxFit.fill),
        ),

        // Başlık
        Positioned(
          left: w * 0.18,
          right: w * 0.18,
          top: h * 0.085 - h * 0.019,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              L10n.t('daily_quests_title'),
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
              style: GoogleFonts.poppins(
                fontSize: h * 0.030,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.3,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2))],
              ),
            ),
          ),
        ),

        // Sarı ilerleme barı: doldurulmamış kısım karartılır + ortasında sayaç
        Positioned(
          left: w * barLeft,
          right: w * (1 - barRight),
          top: h * (barCenterY - barHeight / 2),
          height: h * barHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(h * barHeight / 2),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 1 - barProgress,
                    heightFactor: 1,
                    child: Container(color: Colors.black.withValues(alpha: 0.40)),
                  ),
                ),
                Center(
                  child: Text(
                    '$completed/$total',
                    textScaler: TextScaler.noScaling,
                    style: GoogleFonts.poppins(
                      fontSize: h * 0.016,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1))],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Görev listesi (beyaz alan)
        Positioned(
          left: w * whiteLeft,
          right: w * (1 - whiteRight),
          top: h * whiteTop,
          bottom: h * (1 - whiteBottom),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: h * 0.01),
            children: [for (final q in quests) _buildQuestCard(q)],
          ),
        ),

        // Yenilenme süresi (alt saat ikonunun sağı)
        Positioned(
          left: w * 0.30,
          right: w * 0.06,
          top: h * 0.944 - h * 0.021,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              L10n.t('quest_resets_in').replaceAll('{time}', _formatCountdown(_timeLeft)),
              textScaler: TextScaler.noScaling,
              style: GoogleFonts.poppins(
                fontSize: h * 0.021,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ),

        // Kapat (X) — sağ üst, dokunma alanı genişletilmiş
        Positioned(
          left: w * 0.862 - w * 0.075,
          top: h * 0.090 - w * 0.075,
          width: w * 0.15,
          height: w * 0.15,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.6),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // popup üstüne tıklama dışarı sızmasın
            child: FractionallySizedBox(
              widthFactor: 0.86,
              child: AspectRatio(
                aspectRatio: 1024 / 1536,
                child: LayoutBuilder(
                  builder: (context, constraints) =>
                      _buildPopupContent(constraints.maxWidth, constraints.maxHeight),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
