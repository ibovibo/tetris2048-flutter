import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class AvatarManager {
  static String? avatarPath;  // kendi fotoğrafı (dosya yolu)
  static int? avatarIndex;    // preset avatar (1-15)

  static const String defaultAsset = 'assets/images/anonpp.png';

  static String? getAvatarAsset(int index) {
    if (index >= 1 && index <= 12) {
      return 'assets/ui/avatars/pp$index.png';
    }
    return null;
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Dosya yolu
    final saved = prefs.getString('avatar_path');
    if (saved != null && File(saved).existsSync()) {
      avatarPath = saved;
    } else {
      avatarPath = null;
      if (saved != null) await prefs.remove('avatar_path');
    }

    // Preset index
    avatarIndex = prefs.getInt('avatar_index');
  }

  static Future<void> setAvatar(String path) async {
    avatarPath = path;
    avatarIndex = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_path', path);
    await prefs.remove('avatar_index');
  }

  static Future<void> setAvatarIndex(int index) async {
    avatarIndex = index;
    avatarPath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('avatar_index', index);
    await prefs.remove('avatar_path');
  }

  static Future<void> resetToDefault() async {
    avatarPath = null;
    avatarIndex = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatar_path');
    await prefs.remove('avatar_index');
  }

  static bool get hasCustomAvatar => avatarPath != null;
  static bool get hasPresetAvatar => avatarIndex != null;

  // Aktif avatar path'ini döndürür (ProfileWidget/AvatarDisplay için)
  // - Önce kendi fotoğrafı
  // - Sonra preset asset (henüz null dönebilir → AvatarDisplay default'a düşer)
  // - Yoksa null (default anon)
  static String? get activePath {
    if (avatarPath != null) return avatarPath;
    if (avatarIndex != null) return getAvatarAsset(avatarIndex!);
    return null;
  }
}
