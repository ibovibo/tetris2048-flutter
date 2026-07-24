import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

enum SpecialBlockType { bomb, megaBomb, ice, star, chaos }

class BlockSkinManager {
  // blockType -> custom görsel dosya yolu (null ise varsayılan asset)
  static Map<SpecialBlockType, String?> customSkins = {
    for (final type in SpecialBlockType.values) type: null,
  };

  // Her blok tipinin varsayılan asset yolu (tetris_game.dart'taki blockMap ile eşleşir)
  static const Map<SpecialBlockType, String> defaultAssets = {
    SpecialBlockType.bomb: 'assets/images/blocks/blokk_bomba.png',
    SpecialBlockType.megaBomb: 'assets/images/blocks/blokk_megabomba.png',
    SpecialBlockType.ice: 'assets/images/blocks/blokk_buz.png',
    SpecialBlockType.star: 'assets/images/blocks/blokk_yokeden.png',
    SpecialBlockType.chaos: 'assets/images/blocks/kaosjoker.png',
  };

  // tetris_game.dart _blockImages haritasında kullanılan anahtarlar
  static const Map<SpecialBlockType, String> gameImageKeys = {
    SpecialBlockType.bomb: 'bomb',
    SpecialBlockType.megaBomb: 'megabomb',
    SpecialBlockType.ice: 'ice',
    SpecialBlockType.star: 'star',
    SpecialBlockType.chaos: 'chaos',
  };

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final type in SpecialBlockType.values) {
      final path = prefs.getString('block_skin_${type.name}');
      // Dosya gerçekten var mı kontrol et (silinmiş olabilir)
      if (path != null && File(path).existsSync()) {
        customSkins[type] = path;
      } else {
        customSkins[type] = null;
        if (path != null) await prefs.remove('block_skin_${type.name}');
      }
    }
  }

  static Future<void> setSkin(SpecialBlockType type, String path) async {
    customSkins[type] = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('block_skin_${type.name}', path);
  }

  static Future<void> resetSkin(SpecialBlockType type) async {
    customSkins[type] = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('block_skin_${type.name}');
  }

  static Future<void> resetAll() async {
    for (final type in SpecialBlockType.values) {
      await resetSkin(type);
    }
  }

  static bool hasCustom(SpecialBlockType type) => customSkins[type] != null;
}
