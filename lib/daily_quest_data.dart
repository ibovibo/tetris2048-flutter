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

  const QuestTemplate({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.target,
    this.isTotal = false,
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

String questDescription(QuestTemplate t) {
  final target = formatQuestNumber(t.target);
  switch (t.type) {
    case QuestType.reachScore:
      return L10n.t('quest_reach_score').replaceAll('{target}', target);
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
  QuestTemplate(id: 'reachScore_easy_1', type: QuestType.reachScore, difficulty: QuestDifficulty.easy, target: 100000),
  QuestTemplate(id: 'reachScore_easy_2', type: QuestType.reachScore, difficulty: QuestDifficulty.easy, target: 500000),
  QuestTemplate(id: 'reachScore_medium_1', type: QuestType.reachScore, difficulty: QuestDifficulty.medium, target: 1000000),
  QuestTemplate(id: 'reachScore_medium_2', type: QuestType.reachScore, difficulty: QuestDifficulty.medium, target: 5000000),
  QuestTemplate(id: 'reachScore_hard_1', type: QuestType.reachScore, difficulty: QuestDifficulty.hard, target: 10000000),
  QuestTemplate(id: 'reachScore_hard_2', type: QuestType.reachScore, difficulty: QuestDifficulty.hard, target: 50000000),

  // reachBlock — tek maçta X bloğuna ulaş
  QuestTemplate(id: 'reachBlock_easy_1', type: QuestType.reachBlock, difficulty: QuestDifficulty.easy, target: 2048),
  QuestTemplate(id: 'reachBlock_easy_2', type: QuestType.reachBlock, difficulty: QuestDifficulty.easy, target: 16384),
  QuestTemplate(id: 'reachBlock_medium_1', type: QuestType.reachBlock, difficulty: QuestDifficulty.medium, target: 262144),
  QuestTemplate(id: 'reachBlock_medium_2', type: QuestType.reachBlock, difficulty: QuestDifficulty.medium, target: 4194304),
  QuestTemplate(id: 'reachBlock_hard_1', type: QuestType.reachBlock, difficulty: QuestDifficulty.hard, target: 67108864),
  QuestTemplate(id: 'reachBlock_hard_2', type: QuestType.reachBlock, difficulty: QuestDifficulty.hard, target: 536870912),

  // playMatches — X maç oyna (gün boyu birikir)
  QuestTemplate(id: 'playMatches_easy', type: QuestType.playMatches, difficulty: QuestDifficulty.easy, target: 1),
  QuestTemplate(id: 'playMatches_medium', type: QuestType.playMatches, difficulty: QuestDifficulty.medium, target: 3),
  QuestTemplate(id: 'playMatches_hard', type: QuestType.playMatches, difficulty: QuestDifficulty.hard, target: 5),

  // seasons — her kademede 2 ayrı görev: "tek maçta" ve "o gün toplam"
  QuestTemplate(id: 'seasons_single_easy', type: QuestType.seasons, difficulty: QuestDifficulty.easy, target: 2, isTotal: false),
  QuestTemplate(id: 'seasons_total_easy', type: QuestType.seasons, difficulty: QuestDifficulty.easy, target: 3, isTotal: true),
  QuestTemplate(id: 'seasons_single_medium', type: QuestType.seasons, difficulty: QuestDifficulty.medium, target: 4, isTotal: false),
  QuestTemplate(id: 'seasons_total_medium', type: QuestType.seasons, difficulty: QuestDifficulty.medium, target: 6, isTotal: true),
  QuestTemplate(id: 'seasons_single_hard', type: QuestType.seasons, difficulty: QuestDifficulty.hard, target: 5, isTotal: false),
  QuestTemplate(id: 'seasons_total_hard', type: QuestType.seasons, difficulty: QuestDifficulty.hard, target: 8, isTotal: true),

  // activeTime — uygulama açık kalma süresi (dakika, gün boyu birikir)
  QuestTemplate(id: 'activeTime_easy', type: QuestType.activeTime, difficulty: QuestDifficulty.easy, target: 10),
  QuestTemplate(id: 'activeTime_medium', type: QuestType.activeTime, difficulty: QuestDifficulty.medium, target: 20),
  QuestTemplate(id: 'activeTime_hard', type: QuestType.activeTime, difficulty: QuestDifficulty.hard, target: 30),

  // watchAd — sabit, her gün eklenir
  QuestTemplate(id: 'watchAd', type: QuestType.watchAd, difficulty: QuestDifficulty.easy, target: 1),
];
