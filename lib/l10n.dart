import 'package:shared_preferences/shared_preferences.dart';

class L10n {
  static String _lang = 'tr';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('lang') ?? 'tr';
  }

  static Future<void> setLang(String lang) async {
    _lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
  }

  static String get lang => _lang;

  static const _strings = {
    'tr': {
      'start': 'BAŞLA',
      'shop': 'MAĞAZA',
      'settings': 'AYARLAR',
      'score': 'SKOR',
      'game_over_score': 'SKOR',
      'best': 'EN İYİ',
      'restart': 'TEKRAR',
      'menu': 'MENÜ',
    },
    'en': {
      'start': 'START',
      'shop': 'SHOP',
      'settings': 'SETTINGS',
      'score': 'SCORE',
      'game_over_score': 'SCORE',
      'best': 'BEST',
      'restart': 'RESTART',
      'menu': 'MENU',
    },
    'es': {
      'start': 'JUGAR',
      'shop': 'TIENDA',
      'settings': 'AJUSTES',
      'score': 'PUNTOS',
      'game_over_score': 'PUNTOS',
      'best': 'MEJOR',
      'restart': 'REINICIAR',
      'menu': 'MENÚ',
    },
    'pt': {
      'start': 'JOGAR',
      'shop': 'LOJA',
      'settings': 'AJUSTES',
      'score': 'PONTOS',
      'game_over_score': 'PONTOS',
      'best': 'MELHOR',
      'restart': 'REINICIAR',
      'menu': 'MENU',
    },
    'de': {
      'start': 'SPIELEN',
      'shop': 'LADEN',
      'settings': 'EINST.',
      'score': 'PUNKTE',
      'game_over_score': 'PUNKTE',
      'best': 'BESTE',
      'restart': 'NEUSTART',
      'menu': 'MENÜ',
    },
    'fr': {
      'start': 'JOUER',
      'shop': 'BOUTIQUE',
      'settings': 'RÉGLAGES',
      'score': 'SCORE',
      'game_over_score': 'SCORE',
      'best': 'MEILLEUR',
      'restart': 'REJOUER',
      'menu': 'MENU',
    },
    'it': {
      'start': 'GIOCA',
      'shop': 'NEGOZIO',
      'settings': 'IMPOSTA',
      'score': 'PUNTEGGIO',
      'game_over_score': 'PUNTI',
      'best': 'MIGLIORE',
      'restart': 'RICOMINCIA',
      'menu': 'MENU',
    },
    'ru': {
      'start': 'ИГРАТЬ',
      'shop': 'МАГАЗИН',
      'settings': 'НАСТРОЙКИ',
      'score': 'СЧЁТ',
      'game_over_score': 'СЧЁТ',
      'best': 'РЕКОРД',
      'restart': 'ЗАНОВО',
      'menu': 'МЕНЮ',
    },
    'ja': {
      'start': 'スタート',
      'shop': 'ショップ',
      'settings': '設定',
      'score': 'スコア',
      'game_over_score': 'スコア',
      'best': 'ベスト',
      'restart': 'やり直す',
      'menu': 'メニュー',
    },
    'ko': {
      'start': '시작',
      'shop': '상점',
      'settings': '설정',
      'score': '점수',
      'game_over_score': '점수',
      'best': '최고',
      'restart': '재시작',
      'menu': '메뉴',
    },
    'pl': {
      'start': 'GRAJ',
      'shop': 'SKLEP',
      'settings': 'USTAWIENIA',
      'score': 'WYNIK',
      'game_over_score': 'WYNIK',
      'best': 'REKORD',
      'restart': 'RESTART',
      'menu': 'MENU',
    },
  };

  static String t(String key) => _strings[_lang]?[key] ?? key;
}
