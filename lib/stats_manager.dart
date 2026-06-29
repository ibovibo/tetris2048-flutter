import 'package:shared_preferences/shared_preferences.dart';

class StatsManager {
  static int bestBlock = 0;
  static int highestScore = 0;
  static int totalMerges = 0;
  static int gamesPlayed = 0;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    bestBlock = prefs.getInt('best_block') ?? 0;
    highestScore = prefs.getInt('highest_score') ?? 0;
    totalMerges = prefs.getInt('total_merges') ?? 0;
    gamesPlayed = prefs.getInt('games_played') ?? 0;
  }

  static Future<void> recordGame({
    required int score,
    required int maxTile,
    required int mergesThisGame,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (maxTile > bestBlock) {
      bestBlock = maxTile;
      await prefs.setInt('best_block', bestBlock);
    }

    if (score > highestScore) {
      highestScore = score;
      await prefs.setInt('highest_score', highestScore);
    }

    totalMerges += mergesThisGame;
    await prefs.setInt('total_merges', totalMerges);

    gamesPlayed += 1;
    await prefs.setInt('games_played', gamesPlayed);
  }
}
