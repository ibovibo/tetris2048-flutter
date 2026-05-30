import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/sound_manager.dart';
import 'l10n.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _musicEnabled = true;
  bool _sfxEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _sfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _musicEnabled);
    await prefs.setBool('sfx_enabled', _sfxEnabled);
    SoundManager.enabled = _sfxEnabled;
    if (!_musicEnabled) SoundManager.stopMusic();
  }

  Widget _tap({
    required double top,
    required double left,
    required double right,
    required double height,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, _) {
        final h = MediaQuery.of(context).size.height;
        final w = MediaQuery.of(context).size.width;
        return Positioned(
          top: h * top,
          left: w * left,
          right: w * right,
          height: h * height,
          child: GestureDetector(
            onTap: onTap,
            child: Container(color: Colors.transparent),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Tam ekran PNG
          Positioned.fill(
            child: Image.asset(
              'assets/images/ayarlarmenu.png',
              fit: BoxFit.fill,
            ),
          ),

          // Geri butonu
          Positioned(
            top: h * 0.055,
            left: w * 0.04,
            width: w * 0.15,
            height: w * 0.15,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Müzik toggle tıklanabilir alan
          Positioned(
            top: h * 0.242,
            right: w * 0.13,
            child: _buildToggle(
              _musicEnabled,
              (v) {
                setState(() => _musicEnabled = v);
                _saveSettings();
              },
              w,
              h,
            ),
          ),

          // Ses efekti toggle tıklanabilir alan
          Positioned(
            top: h * 0.335,
            right: w * 0.13,
            child: _buildToggle(
              _sfxEnabled,
              (v) {
                setState(() => _sfxEnabled = v);
                _saveSettings();
              },
              w,
              h,
            ),
          ),

          // Dil butonları — PNG'deki grid konumuna göre
          Positioned(
            top: h * 0.4525,
            left: w * 0.11,
            right: -w * 0.02,
            height: h * 0.396,
            child: _buildLangGrid(w, h),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    bool value,
    Function(bool) onChanged,
    double w,
    double h,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: w * 0.162,
        height: h * 0.046,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? const Color(0xFF6A0FD4) : Colors.grey.shade500,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: h * 0.038,
            height: h * 0.038,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangGrid(double w, double h) {
    final langs = [
      ('en', '🇬🇧', 'English', const Color(0xFF1A6ACC)),
      ('de', '🇩🇪', 'Deutsch', const Color(0xFFFFCC00)),
      ('fr', '🇫🇷', 'Français', const Color(0xFF3B8BEB)),
      ('it', '🇮🇹', 'Italiano', const Color(0xFF9B4FD4)),
      ('pl', '🇵🇱', 'Polski', const Color(0xFFE8334A)),
      ('es', '🇪🇸', 'Español', const Color(0xFFFF8C00)),
      ('pt', '🇧🇷', 'Português', const Color(0xFF2DAE4E)),
      ('ru', '🇷🇺', 'Русский', const Color(0xFF3B8BEB)),
      ('tr', '🇹🇷', 'Türkçe', const Color(0xFF8B0000)),
      ('ar', '🇸🇦', 'العربية', const Color(0xFF1B5E20)),
      ('th', '🇹🇭', 'ภาษาไทย', const Color(0xFF0D1B5E)),
      ('id', '🇮🇩', 'Indonesia', const Color(0xFFE8334A)),
      ('ko', '🇰🇷', '한국어', Colors.white),
      ('ja', '🇯🇵', '日本語', const Color(0xFFE84090)),
      ('zh', '🀄', '繁體中文', const Color(0xFF8B0000)),
    ];

    final btnW = (w * 0.88 - w * 0.025 * 2) / 3 * 0.855;
    final btnH = h * 0.0675 * 1.05 * 1.05 * 0.78;

    return Wrap(
      spacing: w * 0.025,
      runSpacing: h * 0.012,
      children: langs.map((lang) {
        final selected = L10n.lang == lang.$1;
        return GestureDetector(
          onTap: () async {
            await L10n.setLang(lang.$1);
            setState(() {});
          },
          child: Container(
            width: btnW,
            height: btnH,
            decoration: BoxDecoration(
              color: lang.$4,
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(
                      color: lang.$4 == Colors.white
                          ? Colors.black
                          : Colors.white,
                      width: 3,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lang.$2,
                  style: TextStyle(
                    fontSize: 16,
                    shadows: lang.$4 == Colors.white
                        ? const []
                        : const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(1, 1),
                            ),
                          ],
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    lang.$3,
                    style: TextStyle(
                      color: lang.$4 == Colors.white
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                        fontSize: 13,
                      shadows: lang.$4 == Colors.white
                          ? const []
                          : const [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 6,
                                offset: Offset(1, 1),
                              ),
                            ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle,
                    color: lang.$4 == Colors.white
                        ? Colors.black
                        : Colors.white,
                    size: 14,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
