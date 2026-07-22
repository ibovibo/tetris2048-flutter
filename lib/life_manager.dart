import 'package:shared_preferences/shared_preferences.dart';

class LifeManager {
  static const int maxLives = 3;
  static const int regenMinutes = 10; // 10 dakikada 1 can yenilenir

  static int currentLives = maxLives;
  static DateTime? lastRegenTime; // son can yenilenme/harcama zamanı
  static bool isPremium = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isPremium = prefs.getBool('is_premium') ?? false;
    currentLives = prefs.getInt('current_lives') ?? maxLives;
    final lastMillis = prefs.getInt('last_regen_time');
    lastRegenTime = lastMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastMillis)
        : DateTime.now();
    _recalcLives(); // geçen süreye göre can hesapla
  }

  // Geçen süreye göre kaç can yenilendiğini hesapla (gerçek zaman)
  static void _recalcLives() {
    if (currentLives >= maxLives) {
      lastRegenTime = DateTime.now();
      return;
    }
    if (lastRegenTime == null) {
      lastRegenTime = DateTime.now();
      return;
    }
    final elapsed = DateTime.now().difference(lastRegenTime!);
    final regenerated = elapsed.inMinutes ~/ regenMinutes;
    if (regenerated > 0) {
      currentLives = (currentLives + regenerated).clamp(0, maxLives);
      // Kalan süreyi koru (tam bölünmeyen kısım)
      final usedMinutes = regenerated * regenMinutes;
      lastRegenTime = lastRegenTime!.add(Duration(minutes: usedMinutes));
      if (currentLives >= maxLives) {
        lastRegenTime = DateTime.now();
      }
      _save();
    }
  }

  // Bir can harca (oyun başlatırken)
  static Future<bool> useLife() async {
    if (isPremium) return true; // premium sınırsız
    _recalcLives();
    if (currentLives <= 0) return false; // can yok
    if (currentLives >= maxLives) {
      // Dolu iken ilk kez harcanınca sayaç başlar
      lastRegenTime = DateTime.now();
    }
    currentLives--;
    await _save();
    return true;
  }

  // Can ekle (reklam izleyince veya ödül)
  static Future<void> addLife(int amount) async {
    currentLives = (currentLives + amount).clamp(0, maxLives);
    if (currentLives >= maxLives) lastRegenTime = DateTime.now();
    await _save();
  }

  static Future<void> setPremium(bool value) async {
    isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', value);
  }

  // Sonraki cana kalan süre (dolu ise null)
  static Duration? timeToNextLife() {
    if (isPremium) return null;
    _recalcLives();
    if (currentLives >= maxLives) return null;
    if (lastRegenTime == null) return const Duration(minutes: regenMinutes);
    final elapsed = DateTime.now().difference(lastRegenTime!);
    final remaining = const Duration(minutes: regenMinutes) -
        Duration(seconds: elapsed.inSeconds % (regenMinutes * 60));
    return remaining;
  }

  static bool get hasLife {
    if (isPremium) return true;
    _recalcLives();
    return currentLives > 0;
  }

  static bool get isFull => isPremium || currentLives >= maxLives;

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_lives', currentLives);
    await prefs.setInt(
      'last_regen_time',
      (lastRegenTime ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }
}
