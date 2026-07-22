import 'package:shared_preferences/shared_preferences.dart';

import 'achievement_data.dart';

class AchievementManager {
  static Map<String, int> progress = {};
  static int daysPlayed = 0;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final ach in kAchievements) {
      progress[ach.id] = prefs.getInt('ach_${ach.id}') ?? 0;
    }
    daysPlayed = prefs.getInt('days_played') ?? 0;
  }

  static Future<void> updateProgress(String id, int value) async {
    final current = progress[id] ?? 0;
    if (value > current) {
      progress[id] = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ach_$id', value);
    }
  }

  // Gün sayacı — yeni güne geçilince artar
  static Future<void> _recordPlayDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDay = prefs.getString('last_played_date') ?? '';
    if (today != lastDay) {
      await prefs.setString('last_played_date', today);
      daysPlayed = (prefs.getInt('days_played') ?? 0) + 1;
      await prefs.setInt('days_played', daysPlayed);
    }
  }

  // Oyun sonu toplu güncelleme — tetris_game.dart tarafından çağrılır
  static Future<void> syncAfterGame({
    required int score,
    required int maxTile,
    required int gamesPlayed,
    required int level,
  }) async {
    await _recordPlayDay();

    // Skor başarımları
    for (final id in const ['skor_1k', 'skor_10k', 'skor_100k', 'skor_1m',
                             'skor_10m', 'skor_100m', 'skor_1b', 'skor_10b']) {
      await updateProgress(id, score);
    }

    // Blok başarımları
    for (final id in const ['blok_2048', 'blok_16k', 'blok_131k', 'blok_1m',
                             'blok_8m', 'blok_134m', 'blok_1b', 'blok_8b']) {
      await updateProgress(id, maxTile);
    }

    // Oyun başarımları
    for (final id in const ['oyun_1', 'oyun_10', 'oyun_25', 'oyun_50', 'oyun_100']) {
      await updateProgress(id, gamesPlayed);
    }

    // Gün başarımları
    for (final id in const ['gun_1', 'gun_3', 'gun_5', 'gun_10',
                             'gun_20', 'gun_30', 'gun_60', 'gun_90']) {
      await updateProgress(id, daysPlayed);
    }

    // Level başarımları
    for (final id in const ['level_5', 'level_10', 'level_25', 'level_50', 'level_75', 'level_100']) {
      await updateProgress(id, level);
    }
  }

  // Mevsim sayacı — tetris_game.dart mevsim değişiminde çağıracak
  static Future<void> incrementSeasonCount(String seasonKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'season_${seasonKey}_count';
    final newCount = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, newCount);

    await updateProgress('mevsim_${seasonKey}_1', newCount);
    await updateProgress('mevsim_${seasonKey}_10', newCount);

    // Kaç farklı mevsim en az 1 kez yaşandı?
    const seasonKeys = ['bomba', 'buz', 'yercekimi', 'kaos', 'gizem',
                        'karanlik', 'evrim', 'yanardag', 'voltaj'];
    int unique = 0;
    for (final k in seasonKeys) {
      if ((prefs.getInt('season_${k}_count') ?? 0) >= 1) unique++;
    }
    await updateProgress('mevsim_hepsi', unique);
  }

  static bool isCompleted(Achievement ach) =>
      (progress[ach.id] ?? 0) >= ach.target;

  static int get completedCount =>
      kAchievements.where((a) => isCompleted(a)).length;

  static double get totalProgress =>
      kAchievements.isEmpty ? 0.0 : completedCount / kAchievements.length;
}
