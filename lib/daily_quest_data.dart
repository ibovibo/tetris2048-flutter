import 'l10n.dart';

enum QuestType { reachScore, reachBlock, playMatches, seasons, activeTime, watchAd }

enum QuestDifficulty { easy, medium, hard }

class QuestTemplate {
  final String id;
  final QuestType type;
  final QuestDifficulty difficulty;
  final int target;
  // seasons için: true = o gün toplam, false = tek maçta. Diğer tiplerde kullanılmaz.
  final bool isTotal;
  final int goldReward;

  const QuestTemplate({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.target,
    this.isTotal = false,
    required this.goldReward,
  });
}

/// Sayıyı Türkçe biçiminde binlik ayraçla gösterir (100000 -> "100.000").
String formatQuestNumber(int value) {
  final str = value.toString();
  final buf = StringBuffer();
  final len = str.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return buf.toString();
}

/// Skor gibi büyük sayıları kısaltır (100000 -> "100K", 1000000 -> "1M").
String formatShortNumber(int value) {
  double v;
  String suffix;
  if (value >= 1000000000) {
    v = value / 1000000000;
    suffix = 'B';
  } else if (value >= 1000000) {
    v = value / 1000000;
    suffix = 'M';
  } else if (value >= 1000) {
    v = value / 1000;
    suffix = 'K';
  } else {
    return value.toString();
  }
  var s = v.toStringAsFixed(1);
  if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
  return '$s$suffix';
}

String questDescription(QuestTemplate t) {
  final target = formatQuestNumber(t.target);
  switch (t.type) {
    case QuestType.reachScore:
      return L10n.t('quest_reach_score').replaceAll('{target}', formatShortNumber(t.target));
    case QuestType.reachBlock:
      return L10n.t('quest_reach_block').replaceAll('{target}', target);
    case QuestType.playMatches:
      return L10n.t('quest_play_matches').replaceAll('{target}', target);
    case QuestType.seasons:
      final key = t.isTotal ? 'quest_seasons_total' : 'quest_seasons_single';
      return L10n.t(key).replaceAll('{target}', target);
    case QuestType.activeTime:
      return L10n.t('quest_active_time').replaceAll('{target}', target);
    case QuestType.watchAd:
      return L10n.t('quest_watch_ad');
  }
}

// ── Havuz ────────────────────────────────────────────────────────────────
// Her kademede 2 seçenekli tipler (reachScore, reachBlock, seasons) için 2 template.
const List<QuestTemplate> kQuestPool = [
  // reachScore — tek maçta X skora ulaş
  QuestTemplate(id: 'reachScore_easy_1', type: QuestType.reachScore, difficulty: QuestDifficulty.easy, target: 100000, goldReward: 1),
  QuestTemplate(id: 'reachScore_easy_2', type: QuestType.reachScore, difficulty: QuestDifficulty.easy, target: 500000, goldReward: 2),
  QuestTemplate(id: 'reachScore_medium_1', type: QuestType.reachScore, difficulty: QuestDifficulty.medium, target: 1000000, goldReward: 3),
  QuestTemplate(id: 'reachScore_medium_2', type: QuestType.reachScore, difficulty: QuestDifficulty.medium, target: 5000000, goldReward: 4),
  QuestTemplate(id: 'reachScore_hard_1', type: QuestType.reachScore, difficulty: QuestDifficulty.hard, target: 10000000, goldReward: 5),
  QuestTemplate(id: 'reachScore_hard_2', type: QuestType.reachScore, difficulty: QuestDifficulty.hard, target: 50000000, goldReward: 6),

  // reachBlock — tek maçta X bloğuna ulaş
  QuestTemplate(id: 'reachBlock_easy_1', type: QuestType.reachBlock, difficulty: QuestDifficulty.easy, target: 2048, goldReward: 1),
  QuestTemplate(id: 'reachBlock_easy_2', type: QuestType.reachBlock, difficulty: QuestDifficulty.easy, target: 16384, goldReward: 2),
  QuestTemplate(id: 'reachBlock_medium_1', type: QuestType.reachBlock, difficulty: QuestDifficulty.medium, target: 262144, goldReward: 3),
  QuestTemplate(id: 'reachBlock_medium_2', type: QuestType.reachBlock, difficulty: QuestDifficulty.medium, target: 4194304, goldReward: 4),
  QuestTemplate(id: 'reachBlock_hard_1', type: QuestType.reachBlock, difficulty: QuestDifficulty.hard, target: 67108864, goldReward: 5),
  QuestTemplate(id: 'reachBlock_hard_2', type: QuestType.reachBlock, difficulty: QuestDifficulty.hard, target: 536870912, goldReward: 6),

  // playMatches — X maç oyna (gün boyu birikir)
  QuestTemplate(id: 'playMatches_easy', type: QuestType.playMatches, difficulty: QuestDifficulty.easy, target: 1, goldReward: 1),
  QuestTemplate(id: 'playMatches_medium', type: QuestType.playMatches, difficulty: QuestDifficulty.medium, target: 3, goldReward: 2),
  QuestTemplate(id: 'playMatches_hard', type: QuestType.playMatches, difficulty: QuestDifficulty.hard, target: 5, goldReward: 3),

  // seasons — her kademede 2 ayrı görev: "tek maçta" ve "o gün toplam"
  QuestTemplate(id: 'seasons_single_easy', type: QuestType.seasons, difficulty: QuestDifficulty.easy, target: 2, isTotal: false, goldReward: 2),
  QuestTemplate(id: 'seasons_total_easy', type: QuestType.seasons, difficulty: QuestDifficulty.easy, target: 3, isTotal: true, goldReward: 2),
  QuestTemplate(id: 'seasons_single_medium', type: QuestType.seasons, difficulty: QuestDifficulty.medium, target: 4, isTotal: false, goldReward: 4),
  QuestTemplate(id: 'seasons_total_medium', type: QuestType.seasons, difficulty: QuestDifficulty.medium, target: 6, isTotal: true, goldReward: 4),
  QuestTemplate(id: 'seasons_single_hard', type: QuestType.seasons, difficulty: QuestDifficulty.hard, target: 5, isTotal: false, goldReward: 10),
  QuestTemplate(id: 'seasons_total_hard', type: QuestType.seasons, difficulty: QuestDifficulty.hard, target: 8, isTotal: true, goldReward: 8),

  // activeTime — uygulama açık kalma süresi (dakika, gün boyu birikir)
  QuestTemplate(id: 'activeTime_easy', type: QuestType.activeTime, difficulty: QuestDifficulty.easy, target: 10, goldReward: 2),
  QuestTemplate(id: 'activeTime_medium', type: QuestType.activeTime, difficulty: QuestDifficulty.medium, target: 20, goldReward: 4),
  QuestTemplate(id: 'activeTime_hard', type: QuestType.activeTime, difficulty: QuestDifficulty.hard, target: 30, goldReward: 6),

  // watchAd — sabit, her gün eklenir
  QuestTemplate(id: 'watchAd', type: QuestType.watchAd, difficulty: QuestDifficulty.easy, target: 1, goldReward: 10),
];
