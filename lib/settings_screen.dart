import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/sound_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _volume = 0.7;
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
      _volume = prefs.getDouble('volume') ?? 0.7;
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _sfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volume', _volume);
    await prefs.setBool('music_enabled', _musicEnabled);
    await prefs.setBool('sfx_enabled', _sfxEnabled);
    SoundManager.setVolume(_volume);
    SoundManager.enabled = _sfxEnabled;
    if (!_musicEnabled) SoundManager.stopMusic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      body: SafeArea(
        child: Column(
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('← GERİ', style: TextStyle(
                      fontFamily: 'monospace', fontSize: 12,
                      color: Color(0xFF5858A0),
                    )),
                  ),
                  const Spacer(),
                  const Text('AYARLAR', style: TextStyle(
                    fontFamily: 'monospace', fontSize: 16,
                    fontWeight: FontWeight.bold, color: Color(0xFFC87FFF),
                  )),
                  const Spacer(),
                  const SizedBox(width: 60),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Ayar panelleri
            _buildPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SES SEVİYESİ', style: TextStyle(
                    fontFamily: 'monospace', fontSize: 10,
                    color: Color(0xFF5CF5E0), letterSpacing: 3,
                  )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('🔈', style: TextStyle(fontSize: 18)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFC87FFF),
                            inactiveTrackColor: const Color(0xFF1A0A3A),
                            thumbColor: const Color(0xFFC87FFF),
                            overlayColor: const Color(0x33C87FFF),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _volume,
                            min: 0,
                            max: 1,
                            onChanged: (v) {
                              setState(() => _volume = v);
                              SoundManager.setVolume(v);
                            },
                            onChangeEnd: (_) => _saveSettings(),
                          ),
                        ),
                      ),
                      const Text('🔊', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Center(
                    child: Text('${(_volume * 100).round()}%', style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 14,
                      color: Color(0xFFC87FFF), fontWeight: FontWeight.bold,
                    )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildPanel(
              child: Column(
                children: [
                  _buildToggle('MÜZİK', _musicEnabled, (v) {
                    setState(() => _musicEnabled = v);
                    _saveSettings();
                  }),
                  const SizedBox(height: 16),
                  _buildToggle('SES EFEKTLERİ', _sfxEnabled, (v) {
                    setState(() => _sfxEnabled = v);
                    _saveSettings();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0820),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5CF5E0).withValues(alpha: 0.15)),
      ),
      child: child,
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Text(label, style: const TextStyle(
          fontFamily: 'monospace', fontSize: 12,
          color: Colors.white, letterSpacing: 2,
        )),
        const Spacer(),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: value ? const Color(0xFFC87FFF) : const Color(0xFF1A0A3A),
              border: Border.all(
                color: value ? const Color(0xFFC87FFF) : const Color(0xFF333366),
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? Colors.white : const Color(0xFF5858A0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}