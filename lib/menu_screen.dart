import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import 'avatar_manager.dart';
import 'game/sound_manager.dart';
import 'life_manager.dart';
import 'screens/achievements_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'game/tetris_game.dart';
import 'l10n.dart';
import 'profile_manager.dart';
import 'screens/profile_edit_screen.dart';
import 'settings_screen.dart';
import 'widgets/life_bar_widget.dart';
import 'widgets/no_lives_popup.dart';
import 'widgets/profile_widget.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _selectedTabIndex = 2;
  Timer? _lifeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    SoundManager.init().then((_) => SoundManager.playMenuMusic());
    _lifeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    SoundManager.stopMusic();
    _controller.dispose();
    _lifeTimer?.cancel();
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

  void _onNavTap(int index) {
    setState(() => _selectedTabIndex = index);
  }

  Future<void> _tryStartGame() async {
    if (LifeManager.hasLife) {
      await LifeManager.useLife();
      if (!mounted) return;
      setState(() {});
      SoundManager.stopMusic();
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const GameScreen()));
    } else {
      _showNoLivesPopup();
    }
  }

  void _showNoLivesPopup() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: NoLivesPopup(
          onWatchAd: () async {
            // TODO: gerçek rewarded reklam SDK entegrasyonu (AdMob/AppLovin)
            await Future<void>.delayed(const Duration(seconds: 1));
            await LifeManager.addLife(1);
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            if (!mounted) return;
            setState(() {});
            await _tryStartGame();
          },
          onBuyPremium: () {
            Navigator.of(dialogContext).pop();
            // TODO: premium mağaza ekranı açılacak
          },
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Widget _buildActivePage() {
    switch (_selectedTabIndex) {
      case 0:
        return const _ComingSoonPage();
      case 1:
        return AchievementsScreen(
          onBack: () => setState(() => _selectedTabIndex = 2),
        );
      case 2:
        return _buildPlayPage();
      case 3:
        return LeaderboardScreen(
          onBack: () => setState(() => _selectedTabIndex = 2),
        );
      case 4:
        return SettingsScreen(
          onBack: () => setState(() => _selectedTabIndex = 2),
          onLanguageChanged: () => setState(() {}),
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
            // PLAY butonu
            Positioned(
              bottom: h * 0.255,
              left: w * 0.225,
              right: w * 0.225,
              child: GestureDetector(
                onTap: _tryStartGame,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
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
                                  color: const Color(0xFFE2E2E6),
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
                  left: index == 0 ? 2 + itemWidth * 0.04 : 2,
                  right: 2,
                ),
                child: SizedBox(
                  width: itemWidth - 4 - (index == 0 ? itemWidth * 0.04 : 0),
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildActivePage()),
          Positioned(
            bottom: size.height * 0.006,
            left: 0,
            right: 0,
            child: _buildBottomNav(context),
          ),
          // Profil widget'ı — cihaz yüksekliğinin %10'unda, nav bar'ın üzerinde
          if (_selectedTabIndex == 2)
            Positioned(
              top: size.height * 0.1,
              left: size.width * 0.03,
              width: size.width * 0.454,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditScreen(),
                    ),
                  ).then((_) => setState(() {}));
                },
                child: ProfileWidget(
                  userName: ProfileManager.userName,
                  level: ProfileManager.level,
                  xpProgress: ProfileManager.xpProgress,
                  avatarPath: AvatarManager.avatarPath,
                  avatarIndex: AvatarManager.avatarIndex,
                  onEditAvatar: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileEditScreen(),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
              ),
            ),
          // Can göstergesi — profil widget'ının simetriğinde, sağ üstte
          if (_selectedTabIndex == 2)
            Positioned(
              top: size.height * 0.1,
              right: size.width * 0.03,
              width: size.width * 0.38,
              child: LifeBarWidget(
                currentLives: LifeManager.currentLives,
                maxLives: LifeManager.maxLives,
                timeToNext: LifeManager.timeToNextLife(),
              ),
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
    _game.onRequestRestart = (proceed) async {
      if (LifeManager.hasLife) {
        await LifeManager.useLife();
        proceed();
      } else {
        _showNoLivesPopup(proceed);
      }
    };
  }

  void _showNoLivesPopup(VoidCallback proceed) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: NoLivesPopup(
          onWatchAd: () async {
            // TODO: gerçek rewarded reklam SDK entegrasyonu (AdMob/AppLovin)
            await Future<void>.delayed(const Duration(seconds: 1));
            await LifeManager.addLife(1);
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            await LifeManager.useLife();
            proceed();
          },
          onBuyPremium: () {
            Navigator.of(dialogContext).pop();
            // TODO: premium mağaza ekranı açılacak
          },
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: GameWidget(game: _game));
  }
}
