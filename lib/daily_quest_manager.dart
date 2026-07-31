import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'currency_manager.dart';
import 'daily_quest_data.dart';

class DailyQuest {
  final QuestTemplate template;
  int progress;
  bool completed;

  DailyQuest({required this.template, this.progress = 0, this.completed = false});

  Map<String, dynamic> toJson() => {
        'id': template.id,
        'progress': progress,
        'completed': completed,
      };

  static DailyQuest? fromJson(Map<String, dynamic> json) {
    QuestTemplate? template;
    for (final t in kQuestPool) {
      if (t.id == json['id']) {
        template = t;
        break;
      }
    }
    if (template == null) return null;
    return DailyQuest(
      template: template,
      progress: json['progress'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

/// Uygulama ön planda kaldığı süreyi dakika bazında activeTime görevine ekler.
/// Gerçek zaman damgası farkıyla biriktirir; kısa bir bildirim/kilit ekranı
/// kesintisinde önceki periyodik-timer yaklaşımı o anki dakikayı sıfırdan
/// başlatıp tüm ilerlemeyi kaybediyordu (sadece kesintisiz maç oynanışında
/// dakika doluyormuş gibi görünüyordu). Artık kesinti olsa da geçen saniyeler
/// _pendingSeconds'ta birikir, kaybolmaz.
/// NOT: Uygulama açık bırakılırsa dolar (AFK sömürüsüne açık) — MVP için kabul edilebilir.
class _AppLifecycleTracker with WidgetsBindingObserver {
  Timer? _timer;
  bool _started = false;
  DateTime? _resumedAt;
  int _pendingSeconds = 0;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _onResume();
  }

  void _onResume() {
    _resumedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _flush());
  }

  void _onPause() {
    _flush();
    _timer?.cancel();
    _timer = null;
  }

  void _flush() {
    final resumedAt = _resumedAt;
    if (resumedAt == null) return;
    final now = DateTime.now();
    _pendingSeconds += now.difference(resumedAt).inSeconds;
    _resumedAt = now;
    if (_pendingSeconds >= 60) {
      final minutes = _pendingSeconds ~/ 60;
      _pendingSeconds -= minutes * 60;
      DailyQuestManager.addActiveMinutes(minutes);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResume();
    } else {
      _onPause();
    }
  }
}

class DailyQuestManager {
  static List<DailyQuest> todaysQuests = [];
  static String currentDayId = '';
  // Günün tüm görevleri (reklam dahil) tamamlanınca bir kez elmas verilir.
  static bool dailyBonusClaimed = false;
  // 6 görevden (5 gerçek + reklam) 5'i tamamlanınca bar dolar — hepsi şart değil.
  static const int barRequiredCompletions = 5;

  static final _lifecycleTracker = _AppLifecycleTracker();
  static final Random _rng = Random();

  static String getTodayId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = getTodayId();
    final storedDayId = prefs.getString('quest_day_id');

    if (storedDayId == today) {
      final loaded = <DailyQuest>[];
      final raw = prefs.getString('quest_data');
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List;
          for (final item in list) {
            final q = DailyQuest.fromJson(item as Map<String, dynamic>);
            if (q != null) loaded.add(q);
          }
        } catch (_) {}
      }
      if (loaded.isNotEmpty) {
        todaysQuests = loaded;
        currentDayId = today;
        dailyBonusClaimed = prefs.getBool('quest_bonus_claimed') ?? false;
      } else {
        generateDailyQuests();
      }
    } else {
      generateDailyQuests();
    }
    await _persist();
    await _checkDailyBonus();
    _lifecycleTracker.start();
  }

  // Günün görevlerini üretir: 5 tipten her biri için rastgele zorluk (2 kolay,
  // 2 orta, 1 zor) ve o zorluktaki seçeneklerden rastgele bir template,
  // + sabit reklam görevi.
  static void generateDailyQuests() {
    dailyBonusClaimed = false;
    const realTypes = [
      QuestType.reachScore,
      QuestType.reachBlock,
      QuestType.playMatches,
      QuestType.seasons,
      QuestType.activeTime,
    ];
    final shuffledTypes = List<QuestType>.from(realTypes)..shuffle(_rng);
    final difficulties = [
      QuestDifficulty.easy,
      QuestDifficulty.easy,
      QuestDifficulty.medium,
      QuestDifficulty.medium,
      QuestDifficulty.hard,
    ]..shuffle(_rng);

    final quests = <DailyQuest>[];
    for (int i = 0; i < shuffledTypes.length; i++) {
      final type = shuffledTypes[i];
      final difficulty = difficulties[i];
      final options = kQuestPool
          .where((t) => t.type == type && t.difficulty == difficulty)
          .toList();
      final template = options[_rng.nextInt(options.length)];
      quests.add(DailyQuest(template: template));
    }

    final adTemplate = kQuestPool.firstWhere((t) => t.type == QuestType.watchAd);
    quests.add(DailyQuest(template: adTemplate));

    todaysQuests = quests;
    currentDayId = getTodayId();
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quest_day_id', currentDayId);
    await prefs.setString(
      'quest_data',
      jsonEncode(todaysQuests.map((q) => q.toJson()).toList()),
    );
    await prefs.setBool('quest_bonus_claimed', dailyBonusClaimed);
  }

  // Gün değiştiyse (cihaz tarihi ilerlediyse) yeni görevleri üretir.
  static Future<void> _ensureToday() async {
    if (currentDayId != getTodayId()) {
      generateDailyQuests();
      await _persist();
    }
  }

  static Future<void> onMatchEnd({
    required int score,
    required int maxTile,
    required int seasonsThisMatch,
  }) async {
    await _ensureToday();
    for (final q in todaysQuests) {
      if (q.completed) continue;
      switch (q.template.type) {
        case QuestType.reachScore:
          if (score > q.progress) q.progress = score;
          break;
        case QuestType.reachBlock:
          if (maxTile > q.progress) q.progress = maxTile;
          break;
        case QuestType.playMatches:
          q.progress++;
          break;
        case QuestType.seasons:
          // Toplam (isTotal) varyantı onSeasonExperienced() ile anlık güncellenir.
          if (!q.template.isTotal && seasonsThisMatch > q.progress) {
            q.progress = seasonsThisMatch;
          }
          break;
        case QuestType.activeTime:
        case QuestType.watchAd:
          break;
      }
      await _checkAndComplete(q);
    }
    await _persist();
  }

  static Future<void> onSeasonExperienced() async {
    await _ensureToday();
    for (final q in todaysQuests) {
      if (q.completed) continue;
      if (q.template.type == QuestType.seasons && q.template.isTotal) {
        q.progress++;
        await _checkAndComplete(q);
      }
    }
    await _persist();
  }

  static Future<void> addActiveMinutes(int minutes) async {
    await _ensureToday();
    for (final q in todaysQuests) {
      if (q.completed) continue;
      if (q.template.type == QuestType.activeTime) {
        q.progress += minutes;
        await _checkAndComplete(q);
      }
    }
    await _persist();
  }

  static Future<void> completeWatchAd() async {
    await _ensureToday();
    for (final q in todaysQuests) {
      if (q.template.type == QuestType.watchAd && !q.completed) {
        q.progress = q.template.target;
        await _checkAndComplete(q);
      }
    }
    await _persist();
  }

  // Görev ilk kez tamamlanınca (false->true geçişi) altın ödülünü verir.
  // `completed` bayrağı zaten kalıcı olduğundan bu geçiş görev başına en fazla
  // bir kez gerçekleşir — çift ödül verilmez.
  static Future<void> _checkAndComplete(DailyQuest q) async {
    if (!q.completed && q.progress >= q.template.target) {
      q.completed = true;
      await CurrencyManager.addGold(q.template.goldReward);
      await _checkDailyBonus();
    }
  }

  // Bar dolduğunda (barRequiredCompletions kadar görev tamamlandığında) bir
  // kez elmas verir. Sadece _checkAndComplete içinden değil, load() içinden
  // de çağrılır — aksi halde görevler bu özellik eklenmeden önce zaten
  // tamamlanmış olsa (yeni bir false->true geçişi hiç yaşanmadığından) bonus
  // hiçbir zaman tetiklenmezdi.
  static Future<void> _checkDailyBonus() async {
    if (!dailyBonusClaimed &&
        todaysQuests.where((e) => e.completed).length >= barRequiredCompletions) {
      dailyBonusClaimed = true;
      await CurrencyManager.addDiamond(1);
      await _persist();
    }
  }

  static int get completedCount => todaysQuests.where((q) => q.completed).length;

  static bool get allRealQuestsCompleted => todaysQuests
      .where((q) => q.template.type != QuestType.watchAd)
      .every((q) => q.completed);
}
