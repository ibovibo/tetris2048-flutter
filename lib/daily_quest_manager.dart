import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// NOT: Uygulama açık bırakılırsa dolar (AFK sömürüsüne açık) — MVP için kabul edilebilir.
class _AppLifecycleTracker with WidgetsBindingObserver {
  Timer? _timer;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      DailyQuestManager.addActiveMinutes(1);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }
}

class DailyQuestManager {
  static List<DailyQuest> todaysQuests = [];
  static String currentDayId = '';

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
      } else {
        generateDailyQuests();
      }
    } else {
      generateDailyQuests();
    }
    await _persist();
    _lifecycleTracker.start();
  }

  // Günün görevlerini üretir: 5 tipten her biri için rastgele zorluk (2 kolay,
  // 2 orta, 1 zor) ve o zorluktaki seçeneklerden rastgele bir template,
  // + sabit reklam görevi.
  static void generateDailyQuests() {
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
      _checkAndComplete(q);
    }
    await _persist();
  }

  static Future<void> onSeasonExperienced() async {
    await _ensureToday();
    for (final q in todaysQuests) {
      if (q.completed) continue;
      if (q.template.type == QuestType.seasons && q.template.isTotal) {
        q.progress++;
        _checkAndComplete(q);
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
        _checkAndComplete(q);
      }
    }
    await _persist();
  }

  static Future<void> completeWatchAd() async {
    await _ensureToday();
    for (final q in todaysQuests) {
      if (q.template.type == QuestType.watchAd && !q.completed) {
        q.progress = q.template.target;
        q.completed = true;
        // TODO: sikke ödülü
      }
    }
    await _persist();
  }

  static void _checkAndComplete(DailyQuest q) {
    if (!q.completed && q.progress >= q.template.target) {
      q.completed = true;
      // TODO: sikke ödülü
    }
  }

  static int get completedCount => todaysQuests.where((q) => q.completed).length;

  static bool get allRealQuestsCompleted => todaysQuests
      .where((q) => q.template.type != QuestType.watchAd)
      .every((q) => q.completed);
}
