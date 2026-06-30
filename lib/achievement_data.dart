import 'l10n.dart';

enum AchievementCategory { skor, blok, oyun, gun, mevsim, level }

class Achievement {
  final String id;
  final AchievementCategory category;
  final String title;
  final String description;
  final int target;
  final String iconAsset;

  const Achievement({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.target,
    this.iconAsset = '',
  });

  String get localTitle {
    final key = 'ach_t_$id';
    final v = L10n.t(key);
    return v == key ? title : v;
  }

  String get localDesc {
    final key = 'ach_d_$id';
    final v = L10n.t(key);
    return v == key ? description : v;
  }
}

const List<Achievement> kAchievements = [
  // ── SKOR ────────────────────────────────────────────────────────────────
  Achievement(id: 'skor_1k',   category: AchievementCategory.skor, title: 'İlk Adım',    description: '1.000 skor yap',             target: 1000),
  Achievement(id: 'skor_10k',  category: AchievementCategory.skor, title: 'Çırak',        description: '10.000 skor yap',            target: 10000),
  Achievement(id: 'skor_100k', category: AchievementCategory.skor, title: 'Usta',         description: '100.000 skor yap',           target: 100000),
  Achievement(id: 'skor_1m',   category: AchievementCategory.skor, title: 'Uzman',        description: '1.000.000 skor yap',         target: 1000000),
  Achievement(id: 'skor_10m',  category: AchievementCategory.skor, title: 'Efsane',       description: '10.000.000 skor yap',        target: 10000000),
  Achievement(id: 'skor_100m', category: AchievementCategory.skor, title: 'Tanrısal',     description: '100.000.000 skor yap',       target: 100000000),
  Achievement(id: 'skor_1b',   category: AchievementCategory.skor, title: 'Ötesi',        description: '1.000.000.000 skor yap',     target: 1000000000),
  Achievement(id: 'skor_10b',  category: AchievementCategory.skor, title: 'Sonsuz Güç',   description: '10.000.000.000 skor yap',    target: 10000000000),

  // ── BLOK ────────────────────────────────────────────────────────────────
  Achievement(id: 'blok_2048',  category: AchievementCategory.blok, title: '2048',             description: '2048 bloğuna ulaş',          target: 2048),
  Achievement(id: 'blok_16k',   category: AchievementCategory.blok, title: 'Derin Sular',      description: '16.384 bloğuna ulaş',        target: 16384),
  Achievement(id: 'blok_131k',  category: AchievementCategory.blok, title: 'Kristal',          description: '131.072 bloğuna ulaş',       target: 131072),
  Achievement(id: 'blok_1m',    category: AchievementCategory.blok, title: 'Milyoner',         description: '1.048.576 bloğuna ulaş',     target: 1048576),
  Achievement(id: 'blok_8m',    category: AchievementCategory.blok, title: 'Dev',              description: '8.388.608 bloğuna ulaş',     target: 8388608),
  Achievement(id: 'blok_134m',  category: AchievementCategory.blok, title: 'Evrimin Zirvesi',  description: '134.217.728 bloğuna ulaş',   target: 134217728),
  Achievement(id: 'blok_1b',    category: AchievementCategory.blok, title: 'Tanrı Bloğu',      description: '1.073.741.824 bloğuna ulaş', target: 1073741824),
  Achievement(id: 'blok_8b',    category: AchievementCategory.blok, title: 'Sonsuz',           description: '8.589.934.592 bloğuna ulaş', target: 8589934592),

  // ── OYUN ────────────────────────────────────────────────────────────────
  Achievement(id: 'oyun_1',   category: AchievementCategory.oyun, title: 'Hoş Geldin', description: 'İlk oyunu oyna',  target: 1),
  Achievement(id: 'oyun_10',  category: AchievementCategory.oyun, title: 'Alışkanlık', description: '10 oyun oyna',    target: 10),
  Achievement(id: 'oyun_25',  category: AchievementCategory.oyun, title: 'Azimli',     description: '25 oyun oyna',    target: 25),
  Achievement(id: 'oyun_50',  category: AchievementCategory.oyun, title: 'Tutkulu',    description: '50 oyun oyna',    target: 50),
  Achievement(id: 'oyun_100', category: AchievementCategory.oyun, title: 'Bağımlı',    description: '100 oyun oyna',   target: 100),

  // ── GÜN ─────────────────────────────────────────────────────────────────
  Achievement(id: 'gun_1',  category: AchievementCategory.gun, title: 'İlk Gün',          description: '1 gün oyna',   target: 1),
  Achievement(id: 'gun_3',  category: AchievementCategory.gun, title: 'Üç Gün',           description: '3 gün oyna',   target: 3),
  Achievement(id: 'gun_5',  category: AchievementCategory.gun, title: 'Bir Hafta Neredeyse', description: '5 gün oyna', target: 5),
  Achievement(id: 'gun_10', category: AchievementCategory.gun, title: 'On Gün',           description: '10 gün oyna',  target: 10),
  Achievement(id: 'gun_20', category: AchievementCategory.gun, title: 'Üç Hafta',         description: '20 gün oyna',  target: 20),
  Achievement(id: 'gun_30', category: AchievementCategory.gun, title: 'Bir Ay',           description: '30 gün oyna',  target: 30),
  Achievement(id: 'gun_60', category: AchievementCategory.gun, title: 'İki Ay',           description: '60 gün oyna',  target: 60),
  Achievement(id: 'gun_90', category: AchievementCategory.gun, title: 'Üç Ay',            description: '90 gün oyna',  target: 90),

  // ── MEVSİM ──────────────────────────────────────────────────────────────
  Achievement(id: 'mevsim_bomba_1',      category: AchievementCategory.mevsim, title: 'Bomba Ustası',         description: 'Bomba mevsimini yaşa',           target: 1),
  Achievement(id: 'mevsim_buz_1',        category: AchievementCategory.mevsim, title: 'Buz Kalbi',            description: 'Buz mevsimini yaşa',             target: 1),
  Achievement(id: 'mevsim_yercekimi_1',  category: AchievementCategory.mevsim, title: 'Yerçekimi',            description: 'Yerçekimi mevsimini yaşa',       target: 1),
  Achievement(id: 'mevsim_kaos_1',       category: AchievementCategory.mevsim, title: 'Kaos Lord',            description: 'Kaos mevsimini yaşa',            target: 1),
  Achievement(id: 'mevsim_gizem_1',      category: AchievementCategory.mevsim, title: 'Gizem Avcısı',         description: 'Gizem mevsimini yaşa',           target: 1),
  Achievement(id: 'mevsim_karanlik_1',   category: AchievementCategory.mevsim, title: 'Karanlık Ruh',         description: 'Karanlık mevsimini yaşa',        target: 1),
  Achievement(id: 'mevsim_evrim_1',      category: AchievementCategory.mevsim, title: 'Evrimci',              description: 'Evrim mevsimini yaşa',           target: 1),
  Achievement(id: 'mevsim_yanardag_1',   category: AchievementCategory.mevsim, title: 'Yanardağ',             description: 'Yanardağ mevsimini yaşa',        target: 1),
  Achievement(id: 'mevsim_voltaj_1',     category: AchievementCategory.mevsim, title: 'Voltaj',               description: 'Voltaj mevsimini yaşa',          target: 1),
  Achievement(id: 'mevsim_hepsi',        category: AchievementCategory.mevsim, title: 'Mevsim Koleksiyoncusu',description: '9 mevsimi de yaşa',              target: 9),
  Achievement(id: 'mevsim_bomba_10',     category: AchievementCategory.mevsim, title: 'Bomba Efendisi',       description: 'Bomba mevsimini 10 kez yaşa',    target: 10),
  Achievement(id: 'mevsim_buz_10',       category: AchievementCategory.mevsim, title: 'Buz Lordu',            description: 'Buz mevsimini 10 kez yaşa',      target: 10),
  Achievement(id: 'mevsim_yercekimi_10', category: AchievementCategory.mevsim, title: 'Yerçekimi Efendisi',   description: 'Yerçekimi mevsimini 10 kez yaşa',target: 10),
  Achievement(id: 'mevsim_kaos_10',      category: AchievementCategory.mevsim, title: 'Kaos Tanrısı',         description: 'Kaos mevsimini 10 kez yaşa',     target: 10),
  Achievement(id: 'mevsim_gizem_10',     category: AchievementCategory.mevsim, title: 'Gizem Ustası',         description: 'Gizem mevsimini 10 kez yaşa',    target: 10),
  Achievement(id: 'mevsim_karanlik_10',  category: AchievementCategory.mevsim, title: 'Karanlık Lord',        description: 'Karanlık mevsimini 10 kez yaşa', target: 10),
  Achievement(id: 'mevsim_evrim_10',     category: AchievementCategory.mevsim, title: 'Evrim Tanrısı',        description: 'Evrim mevsimini 10 kez yaşa',    target: 10),
  Achievement(id: 'mevsim_yanardag_10',  category: AchievementCategory.mevsim, title: 'Yanardağ Efendisi',    description: 'Yanardağ mevsimini 10 kez yaşa', target: 10),
  Achievement(id: 'mevsim_voltaj_10',    category: AchievementCategory.mevsim, title: 'Voltaj Tanrısı',       description: 'Voltaj mevsimini 10 kez yaşa',   target: 10),

  // ── LEVEL ───────────────────────────────────────────────────────────────
  Achievement(id: 'level_5',   category: AchievementCategory.level, title: 'Yeni Kan',      description: "Level 5'e ulaş",   target: 5),
  Achievement(id: 'level_10',  category: AchievementCategory.level, title: 'Deneyimli',     description: "Level 10'a ulaş",  target: 10),
  Achievement(id: 'level_25',  category: AchievementCategory.level, title: 'Veteran',       description: "Level 25'e ulaş",  target: 25),
  Achievement(id: 'level_50',  category: AchievementCategory.level, title: 'Usta Oyuncu',   description: "Level 50'ye ulaş", target: 50),
  Achievement(id: 'level_100', category: AchievementCategory.level, title: 'Efsane Oyuncu', description: "Level 100'e ulaş", target: 100),
];
