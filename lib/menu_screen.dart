import 'dart:math';

import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/sound_manager.dart';
import 'game/tetris_game.dart';
import 'l10n.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int best = 0;
  int _selectedTabIndex = 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    SoundManager.init().then((_) => SoundManager.playMenuMusic());
    _loadBestScore();
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
    bool lockTextBounds = false,
    Color? strokeColor,
    double strokeWidth = 0,
  }) {
    const textScaler = TextScaler.noScaling;
    final label = strokeColor == null || strokeWidth <= 0
        ? Text(
            text,
            textAlign: TextAlign.center,
            textScaler: textScaler,
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
                textScaler: textScaler,
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
                textScaler: textScaler,
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
                    fit: lockTextBounds ? BoxFit.contain : BoxFit.scaleDown,
                    child: label,
                  )
                : label,
          ),
        ),
      ),
    );
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      best = prefs.getInt('best_score') ?? 0;
    });
  }

  String _formatScore(int score) {
    if (score >= 1000000000) {
      return '${(score / 1000000000).toStringAsFixed(2)}B';
    } else if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(2)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }

  void _onNavTap(int index) {
    setState(() => _selectedTabIndex = index);
  }

  Widget _buildActivePage() {
    switch (_selectedTabIndex) {
      case 0:
        return const _ComingSoonPage();
      case 1:
        return const _ComingSoonPage();
      case 2:
        return _buildPlayPage();
      case 3:
        return const _ComingSoonPage();
      case 4:
        return SettingsScreen(
          onBack: () => setState(() => _selectedTabIndex = 2),
        );
      default:
        return _buildPlayPage();
    }
  }

  Widget _buildPlayPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/newmenu.png',
                fit: BoxFit.cover,
              ),
            ),
            // En iyi skor paneli
            Positioned(
              bottom: h * 0.405,
              left: w * 0.26,
              right: w * 0.26,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/bestmenu.png',
                    fit: BoxFit.contain,
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (_, c) {
                        final h2 = c.maxHeight;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FractionallySizedBox(
                              widthFactor: 0.72,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  L10n.t('best_score'),
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(
                                    fontSize: h2 * 0.28,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2446A8),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              _formatScore(best),
                              style: TextStyle(
                                fontSize: h2 * 0.38,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF2446A8),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // PLAY butonu
            Positioned(
              bottom: h * 0.255,
              left: w * 0.225,
              right: w * 0.225,
              child: GestureDetector(
                onTap: () {
                  SoundManager.stopMusic();
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(),
                        ),
                      )
                      .then((_) => _loadBestScore());
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
                        builder: (_, c) {
                          final h2 = c.maxHeight;
                          return Transform.translate(
                            offset: Offset(0, -c.maxHeight * 0.06),
                            child: _buildButtonLabelSlot(
                              text: L10n.t('start'),
                              alignment: Alignment.center,
                              widthFactor: 0.86,
                              heightFactor: 0.78,
                              padding: EdgeInsets.only(
                                left: c.maxWidth * 0.08,
                                right: c.maxWidth * 0.08,
                                top: c.maxHeight * 0.12,
                                bottom: c.maxHeight * 0.10,
                              ),
                              useFittedBox: false,
                              strokeColor: const Color(0xFF9A4A12),
                              strokeWidth: h2 * 0.045,
                              style: TextStyle(
                                fontSize: h2 * 0.325,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF8D57A),
                                letterSpacing: h2 * 0.03,
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
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    double navHeight,
    double itemWidth,
  ) {
    final isSelected = _selectedTabIndex == index;
    // İlk 5 harf tam boyutta kalır; sonrasında her harf yazıyı biraz küçültür.
    final extraChars = label.length > 5 ? label.length - 5 : 0;
    final lengthScale = extraChars > 0 ? pow(0.92, extraChars).toDouble() : 1.0;
    final baseFontSize = navHeight * 0.1444;
    return GestureDetector(
      // Transparan alanlarda da tıklamayı yakala
      behavior: HitTestBehavior.opaque,
      onTap: () => _onNavTap(index),
      child: SizedBox(
        width: itemWidth,
        height: navHeight,
        child: Stack(
          // Stack SizedBox'ı tam doldursun
          fit: StackFit.expand,
          children: [
            // Pulse glow — AnimatedBuilder Stack'in doğrudan çocuğu,
            // içinde Positioned YOK; Padding ile ikon bölgesine hizalanır
            // Yazı etiketi
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: navHeight * 0.07,
                  left: 2,
                  right: 2,
                ),
                child: SizedBox(
                  width: itemWidth - 4,
                  // Sabit yükseklik (taban font boyutuna göre) — lengthScale
                  // küçülse de kutu boyu değişmesin, yazı aşağı kaymasın.
                  height: baseFontSize * 1.3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textScaler: TextScaler.noScaling,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: baseFontSize * lengthScale,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (index == 2
                                  ? Colors.white
                                  : const Color(0xFFFFC107))
                            : const Color(0xFF2446A8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final navWidth = MediaQuery.of(context).size.width * 0.95;
    final labels = [
      L10n.t('shop'),
      L10n.t('achievements'),
      L10n.t('start'),
      L10n.t('leaderboard'),
      L10n.t('settings'),
    ];

    return Center(
      child: SizedBox(
        width: navWidth,
        // Yükseklik yok — görsel kendi doğal yüksekliğini belirler
        child: Stack(
          children: [
            // Görsel genişliğe oturur, yüksekliği aspect ratio'dan gelir
            Image.asset(
              'assets/images/altmenu.png',
              width: navWidth,
              fit: BoxFit.fitWidth,
            ),
            // Metin ve glow, görselin gerçek render boyutunu alır
            Positioned.fill(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final h = constraints.maxHeight;
                  final itemW = navWidth / 5;
                  return Row(
                    children: List.generate(
                      5,
                      (i) => _buildNavItem(i, labels[i], h, itemW),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildActivePage()),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.006,
            left: 0,
            right: 0,
            child: _buildBottomNav(context),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          L10n.t('coming_soon'),
          textScaler: TextScaler.noScaling,
          style: const TextStyle(
            color: Color(0xFF555555),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
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
    return Scaffold(body: GameWidget(game: _game));
  }
}
