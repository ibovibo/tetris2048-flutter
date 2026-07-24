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
  Timer? _refreshTimer;
  bool _watchingAd = false;

  @override
  void initState() {
    super.initState();
    // activeTime görevi arka planda ilerleyebilir — ekran açıkken düzenli tazele.
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _watchAd() async {
    setState(() => _watchingAd = true);
    // TODO: gerçek rewarded reklam SDK entegrasyonu (AdMob/AppLovin)
    await Future<void>.delayed(const Duration(seconds: 1));
    await DailyQuestManager.completeWatchAd();
    if (mounted) setState(() => _watchingAd = false);
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildQuestCard(DailyQuest q) {
    final isAd = q.template.type == QuestType.watchAd;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _glassCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isAd) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (q.progress / q.template.target).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: q.completed
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatQuestNumber(q.progress > q.template.target ? q.template.target : q.progress)}/${formatQuestNumber(q.template.target)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isAd)
                q.completed
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 32)
                    : SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _watchingAd ? null : _watchAd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _watchingAd
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  L10n.t('watch_button'),
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                        ),
                      )
              else if (q.completed)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 32)
              else
                const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFF94A3B8), size: 28),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quests = DailyQuestManager.todaysQuests;
    return Scaffold(
      backgroundColor: Colors.black,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1230), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      iconSize: 28,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                    Expanded(
                      child: Text(
                        L10n.t('daily_quests_title'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  L10n.t('quests_completed_label')
                      .replaceAll('{count}', '${DailyQuestManager.completedCount}')
                      .replaceAll('{total}', '${quests.length}'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [for (final q in quests) _buildQuestCard(q)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
