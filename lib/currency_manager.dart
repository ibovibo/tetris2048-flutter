import 'package:shared_preferences/shared_preferences.dart';

class CurrencyManager {
  static int gold = 0;
  static int diamond = 0;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    gold = prefs.getInt('gold') ?? 0;
    diamond = prefs.getInt('diamond') ?? 0;
  }

  static Future<void> addGold(int amount) async {
    gold += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gold', gold);
  }

  // Harcama (mağaza için, sonra kullanılacak)
  static Future<bool> spendGold(int amount) async {
    if (gold < amount) return false;
    gold -= amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gold', gold);
    return true;
  }

  static Future<void> addDiamond(int amount) async {
    diamond += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('diamond', diamond);
  }

  // Harcama (mağaza için, sonra kullanılacak)
  static Future<bool> spendDiamond(int amount) async {
    if (diamond < amount) return false;
    diamond -= amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('diamond', diamond);
    return true;
  }
}
