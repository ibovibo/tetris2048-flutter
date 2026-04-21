import 'package:flutter/material.dart';
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      body: Stack(
        children: [
          CustomPaint(painter: _GridPainter(), size: size),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 60),
                _buildPlayButton(context),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0820),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF5CF5E0).withValues(alpha: 0.3)),
                    ),
                    child: const Text('⚙ AYARLAR', style: TextStyle(
                      fontFamily: 'monospace', fontSize: 13,
                      color: Color(0xFF5CF5E0), letterSpacing: 3,
                    )),
                  ),
                ),
                const SizedBox(height: 32),
                _buildStats(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final e in [
              ['T', 0xFFFF3333],
              ['E', 0xFFFF9900],
              ['T', 0xFFFFEE00],
              ['R', 0xFF33CC33],
              ['İ', 0xFF3399FF],
              ['S', 0xFF9933FF],
            ])
              Text(e[0] as String, style: TextStyle(
                fontFamily: 'monospace', fontSize: 48, fontWeight: FontWeight.w900,
                color: Color(e[1] as int),
                shadows: [Shadow(color: Color(e[1] as int), blurRadius: 16), const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 3))],
              )),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final e in [
              ['2', 0xFF3399FF],
              ['0', 0xFF33CC99],
              ['4', 0xFFFF9900],
              ['8', 0xFFFF3366],
            ])
              Text(e[0] as String, style: TextStyle(
                fontFamily: 'monospace', fontSize: 56, fontWeight: FontWeight.w900,
                color: Color(e[1] as int),
                shadows: [Shadow(color: Color(e[1] as int), blurRadius: 20), const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 3))],
              )),
          ],
        ),
        const SizedBox(height: 8),
        Text('HYBRID PUZZLE GAME', style: TextStyle(
          fontFamily: 'monospace', fontSize: 11, letterSpacing: 5,
          color: Colors.white.withValues(alpha:0.3),
        )),
      ],
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
            width: 260, height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFFFAA00), Color(0xFFCC4400)],
              ),
              boxShadow: [BoxShadow(color: const Color(0xFFFF6600).withValues(alpha:0.5), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 4, left: 8, right: 8,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const Center(
                  child: Text('OYNA', style: TextStyle(
                    fontFamily: 'monospace', fontSize: 26, fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        Text('EN YÜKSEK SKOR', style: TextStyle(
          fontFamily: 'monospace', fontSize: 10, letterSpacing: 3,
          color: Colors.white.withValues(alpha:0.3),
        )),
        const SizedBox(height: 4),
        const Text('0', style: TextStyle(
          fontFamily: 'monospace', fontSize: 26, fontWeight: FontWeight.bold,
          color: Color(0xFFF5E05C),
          shadows: [Shadow(color: Color(0xFFF5E05C), blurRadius: 10)],
        )),
      ],
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A4A8A).withValues(alpha:0.4)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}