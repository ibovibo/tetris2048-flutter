import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/sound_manager.dart';
import 'game/tetris_game.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    SoundManager.init().then((_) => SoundManager.playMenuMusic());
  }

  @override
  void dispose() {
    SoundManager.stopMusic();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildButtonLabelSlot({
    required String text,
    required TextStyle style,
    required Alignment alignment,
    required double widthFactor,
    required double heightFactor,
    required EdgeInsets padding,
    bool useFittedBox = true,
    Color? strokeColor,
    double strokeWidth = 0,
  }) {
    final label = strokeColor == null || strokeWidth <= 0
        ? Text(
            text,
            textAlign: TextAlign.center,
            style: style,
            maxLines: useFittedBox ? null : 2,
            overflow: useFittedBox ? null : TextOverflow.visible,
          )
        : Stack(
            alignment: Alignment.center,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: style.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = strokeWidth
                    ..color = strokeColor,
                  color: null,
                  shadows: null,
                ),
                maxLines: useFittedBox ? null : 2,
                overflow: useFittedBox ? null : TextOverflow.visible,
              ),
              Text(
                text,
                textAlign: TextAlign.center,
                style: style.copyWith(shadows: null),
                maxLines: useFittedBox ? null : 2,
                overflow: useFittedBox ? null : TextOverflow.visible,
              ),
            ],
          );

    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        child: Padding(
          padding: padding,
          child: Center(
            child: useFittedBox
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: label,
                  )
                : label,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/menu_bos.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: size.height * 0.05,
            left: size.width * 0.05,
            width: size.width * 0.25,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.black,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SHOP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Yakında...',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/shop_button.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.05,
            right: size.width * 0.05,
            width: size.width * 0.25,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/settingsbos.png',
                    fit: BoxFit.contain,
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final h = constraints.maxHeight;
                        return Transform.translate(
                          offset: Offset(0, -constraints.maxHeight * 0.03),
                          child: _buildButtonLabelSlot(
                            text: 'AYARLAR',
                            alignment: Alignment.center,
                            widthFactor: 1.00,
                            heightFactor: 1.00,
                            padding: EdgeInsets.only(
                              left: constraints.maxWidth * 0.30,
                              right: constraints.maxWidth * 0.10,
                            ),
                            useFittedBox: false,
                            strokeColor: const Color(0xFF7A4A00),
                            strokeWidth: h * 0.035,
                            style: TextStyle(
                              fontSize: h * 0.32,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFF8D57A),
                              letterSpacing: h * 0.03,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.25,
            left: size.width * 0.2,
            right: size.width * 0.2,
            child: GestureDetector(
              onTap: () {
                SoundManager.stopMusic();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/start_bos.png',
                    fit: BoxFit.contain,
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final h = constraints.maxHeight;
                        return Transform.translate(
                          offset: Offset(0, -constraints.maxHeight * 0.06),
                          child: _buildButtonLabelSlot(
                          text: 'BAŞLA',
                          alignment: Alignment.center,
                          widthFactor: 0.86,
                          heightFactor: 0.78,
                          padding: EdgeInsets.only(
                            left: constraints.maxWidth * 0.08,
                            right: constraints.maxWidth * 0.08,
                            top: constraints.maxHeight * 0.12,
                            bottom: constraints.maxHeight * 0.10,
                          ),
                          useFittedBox: false,
                          strokeColor: const Color(0xFF9A4A12),
                          strokeWidth: h * 0.045,
                          style: TextStyle(
                            fontSize: h * 0.45,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFF0C8),
                            letterSpacing: h * 0.05,
                          ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TetrisGame _game;

  @override
  void initState() {
    super.initState();
    _game = TetrisGame();
    _game.onPause = () {
      if (!mounted) return;
      Navigator.of(context).pop();
      SoundManager.init().then((_) => SoundManager.playMenuMusic());
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(game: _game),
    );
  }
}
