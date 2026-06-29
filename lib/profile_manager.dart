import 'package:shared_preferences/shared_preferences.dart';

class ProfileManager {
  static int totalXP = 0;
  static int level = 1;
  static int currentLevelXP = 0;
  static int currentLevelRequired = 0;
  static String userName = 'Player';

  // 100 level, her level önceki * 1.15, başlangıç 10.000
  static const List<int> kLevelXP = [
    10000, 11500, 13225, 15209, 17490, 20114, 23131, 26600, 30590, 35179,
    40456, 46524, 53503, 61528, 70757, 81371, 93577, 107613, 123755, 142318,
    163666, 188216, 216448, 248916, 286253, 329191, 378570, 435355, 500658, 575757,
    662121, 761439, 875655, 1007003, 1158054, 1331762, 1531526, 1761255, 2025443, 2329260,
    2678649, 3080446, 3542513, 4073890, 4684974, 5387720, 6195878, 7125260, 8194049, 9423156,
    10836629, 12462124, 14331443, 16481159, 18953333, 21796333, 25065783, 28825651, 33149499, 38121924,
    43840213, 50416245, 57978682, 66675484, 76676807, 88178328, 101405077, 116615839, 134108215, 154224447,
    177358114, 203961831, 234556106, 269739522, 310200450, 356730518, 410240096, 471776110, 542542527, 623923906,
    717512492, 825139366, 948910271, 1091246812, 1254933834, 1443173909, 1659649995, 1908597494, 2194887018, 2524120071,
    2902738082, 3338148794, 3838871113, 4414701780, 5076907047, 5838443104, 6714209570, 7721341005, 8879542156, 10211473479,
  ];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    totalXP = prefs.getInt('total_xp') ?? 0;
    userName = prefs.getString('user_name') ?? 'Player';
    _recalcLevel();
  }

  static Future<void> addXP(int xp) async {
    totalXP += xp;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_xp', totalXP);
    _recalcLevel();
  }

  static void _recalcLevel() {
    int cumulative = 0;
    level = 1;
    for (int i = 0; i < kLevelXP.length; i++) {
      if (totalXP >= cumulative + kLevelXP[i]) {
        cumulative += kLevelXP[i];
        level = i + 2;
      } else {
        currentLevelXP = totalXP - cumulative;
        currentLevelRequired = kLevelXP[i];
        break;
      }
    }
    if (level > 100) level = 100;
  }

  static double get xpProgress {
    if (currentLevelRequired == 0) return 1.0;
    return (currentLevelXP / currentLevelRequired).clamp(0.0, 1.0);
  }
}
