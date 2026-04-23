import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'game/tetris_game.dart';
import 'package:flame/game.dart';
import 'game/sound_manager.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    SoundManager.init().then((_) => SoundManager.playMenuMusic());
  }

  @override
  void dispose() {
    SoundManager.stopMusic();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Stack(
        children: [
          // Tam ekran SVG arka plan
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/menu.svg',
              fit: BoxFit.cover,
            ),
          ),

          // Sol üst — Shop butonu
          Positioned(
            top: 48, left: 20,
            child: _buildIconButton(
              icon: Icons.shopping_bag_outlined,
              label: 'Shop',
              onTap: () {},
            ),
          ),

          // Sağ üst — Settings butonu
          Positioned(
            top: 48, right: 20,
            child: _buildIconButton(
              icon: Icons.settings_outlined,
              label: 'Ayarlar',
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ),

          // Alt orta — OYNA butonu
          Positioned(
            bottom: 80,
            left: 0, right: 0,
            child: Center(child: _buildPlayButton(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(
              fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SoundManager.stopMusic();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Transform.scale(
          scale: 1.0 + _controller.value * 0.02,
          child: Container(
            width: 200, height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFFFAA00), Color(0xFFCC4400)],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF6600).withValues(alpha: 0.6),
                  blurRadius: 24, spreadRadius: 2),
              ],
            ),
            child: Stack(
              children: [
                // Üst parlama
                Positioned(
                  top: 4, left: 8, right: 8,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Play ikonu + yazı
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text('OYNA', style: TextStyle(
                        fontFamily: 'monospace', fontSize: 22,
                        fontWeight: FontWeight.w900, color: Colors.white,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 4,
                          offset: Offset(0, 2))],
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = TetrisGame();
    game.onPause = () {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      SoundManager.init().then((_) => SoundManager.playMenuMusic());
    };
    return Scaffold(
      body: GameWidget(game: game),
    );
  }
}