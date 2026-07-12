import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/sound_manager.dart';
import 'l10n.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onLanguageChanged;
  const SettingsScreen({super.key, this.onBack, this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  bool _langDropdownOpen = false;

  static const _langs = [
    ('en', '🇬🇧', 'English'),
    ('de', '🇩🇪', 'Deutsch'),
    ('fr', '🇫🇷', 'Français'),
    ('it', '🇮🇹', 'Italiano'),
    ('pl', '🇵🇱', 'Polski'),
    ('es', '🇪🇸', 'Español'),
    ('pt', '🇧🇷', 'Português'),
    ('ru', '🇷🇺', 'Русский'),
    ('tr', '🇹🇷', 'Türkçe'),
    ('ar', '🇸🇦', 'العربية'),
    ('th', '🇹🇭', 'ภาษาไทย'),
    ('id', '🇮🇩', 'Indonesia'),
    ('ko', '🇰🇷', '한국어'),
    ('ja', '🇯🇵', '日本語'),
    ('zh', '🀄', '繁體中文'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _soundEnabled = prefs.getBool('sfx_enabled') ?? true;
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _saveSound(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', v);
    SoundManager.enabled = v;
  }

  Future<void> _saveMusic(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', v);
    if (!v) {
      SoundManager.stopMusic();
    } else {
      SoundManager.init().then((_) => SoundManager.playMenuMusic());
    }
  }

  Future<void> _saveVibration(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', v);
  }

  String get _currentLangDisplay {
    final match = _langs.where((l) => l.$1 == L10n.lang).firstOrNull;
    return match != null ? '${match.$2}  ${match.$3}' : L10n.lang;
  }

  Widget _buildToggle(bool value, ValueChanged<bool> onChanged, double w, double h) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: w * 0.16,
        height: h * 0.055,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? const Color(0xFF4CAF50) : const Color(0xFF999999),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: h * 0.044,
            height: h * 0.044,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildToggleRow({
    required double w,
    required double h,
    required double labelTop,
    required double toggleTop,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return [
      Positioned(
        top: labelTop,
        left: w * 0.30,
        right: w * 0.08,
        height: h * 0.065,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            textScaler: TextScaler.noScaling,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: h * 0.023,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2B5FD4),
              shadows: const [Shadow(color: Colors.white60, blurRadius: 4)],
            ),
          ),
        ),
      ),
      Positioned(
        top: toggleTop,
        right: w * 0.16,
        width: w * 0.20,
        height: h * 0.14,
        child: Align(
          alignment: Alignment.centerRight,
          child: _buildToggle(value, onChanged, w, h),
        ),
      ),
    ];
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
          // Arka plan PNG
          Positioned.fill(
            child: Image.asset(
              'assets/images/ayarlarmenu.png',
              fit: BoxFit.fill,
            ),
          ),

          // Başlık — sadece yazı
          Positioned(
            top: h * 0.12,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                L10n.t('settings'),
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: h * 0.038,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),

          // Toggle satırları — SES, MÜZİK, TİTREŞİM
          ..._buildToggleRow(
            w: w, h: h,
            labelTop: h * 0.28,
            toggleTop: h * 0.245,
            label: L10n.t('sound'),
            value: _soundEnabled,
            onChanged: (v) {
              setState(() => _soundEnabled = v);
              _saveSound(v);
            },
          ),
          ..._buildToggleRow(
            w: w, h: h,
            labelTop: h * 0.385,
            toggleTop: h * 0.345,
            label: L10n.t('music'),
            value: _musicEnabled,
            onChanged: (v) {
              setState(() => _musicEnabled = v);
              _saveMusic(v);
            },
          ),
          ..._buildToggleRow(
            w: w, h: h,
            labelTop: h * 0.49,
            toggleTop: h * 0.445,
            label: L10n.t('vibration'),
            value: _vibrationEnabled,
            onChanged: (v) {
              setState(() => _vibrationEnabled = v);
              _saveVibration(v);
            },
          ),

          // Dil başlığı
          Positioned(
            top: h * 0.61,
            left: w * 0.18,
            child: Text(
              L10n.t('language'),
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: h * 0.022,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2B5FD4),
                shadows: const [Shadow(color: Colors.white60, blurRadius: 4)],
              ),
            ),
          ),

          // Dropdown açıkken dışına tıklayınca kapat (tüm ekran üstünde şeffaf katman)
          if (_langDropdownOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _langDropdownOpen = false),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),

          // Dil seçici (backdrop'ın üstünde, z-order'da sonra geliyor)
          Positioned(
            bottom: h * 0.280,
            left: w * 0.43,
            right: w * 0.17,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Açılır liste (yukarı açılır)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: _langDropdownOpen ? h * 0.30 : 0,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _langDropdownOpen
                        ? ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _langs.length,
                            itemExtent: 36,
                            itemBuilder: (_, i) {
                              final lang = _langs[i];
                              final isSelected = L10n.lang == lang.$1;
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  await L10n.setLang(lang.$1);
                                  if (!mounted) return;
                                  setState(() => _langDropdownOpen = false);
                                  widget.onLanguageChanged?.call();
                                },
                                child: Container(
                                  color: isSelected
                                      ? const Color(0xFFEDE7F6)
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        lang.$2,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          lang.$3,
                                          textScaler: TextScaler.noScaling,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF6A0FD4)
                                                : const Color(0xFF333333),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_rounded,
                                          color: Color(0xFF6A0FD4),
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                // Tetikleyici buton
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _langDropdownOpen = !_langDropdownOpen),
                  child: Container(
                    height: h * 0.048,
                    padding: EdgeInsets.symmetric(horizontal: w * 0.032),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.93),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentLangDisplay,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontSize: h * 0.019,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _langDropdownOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: const Color(0xFF2B5FD4),
                            size: h * 0.026,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
