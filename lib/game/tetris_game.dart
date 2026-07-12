import 'dart:math';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flame/flame.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n.dart';
import '../achievement_manager.dart';
import '../leaderboard_manager.dart';
import '../profile_manager.dart';
import '../stats_manager.dart';
import 'board.dart';
import 'piece.dart';
import 'constants.dart';
import 'special_resolver.dart';
import 'sound_manager.dart';
import 'particle_system.dart';
import 'max_explosion.dart';
import 'bar_break.dart';

class TetrisGame extends FlameGame
    with KeyboardEvents, DoubleTapDetector, PanDetector, TapDetector {
  TetrisGame();
  void Function()? onPause;

  late Board board;
  late Piece currentPiece;
  late Piece nextPiece;
  final List<Piece> nextQueue = [];
  final ParticleSystem particles = ParticleSystem();
  final List<MultiplierLine> multiplierLines = [];
  final _rng = Random();

  // Pop cells — birleşen blokların bounce animasyonu
  final List<PopCell> popCells = [];
  final List<_PendingSeasonDrop> _pendingDrops = [];

  int score = 0;
  double displayScore = 0;
  int best = 0;
  int bestCombo = 1;
  int _currentGameBestCombo = 1;
  int level = 1;
  int combo = 1;
  int _lastXpGained = 0;
  double _xpCountTimer = 0.0;
  double _meter = 0.0;
  double _meterDisplay = 0.0; // görsel meter — gerçek meter'a smooth yaklaşır
  int _pendingSpecialCount = 0;
  bool _gravityReversed = false;
  int streak = 0;
  double streakTimer = 0;
  int moveCount = 0;
  int totalMoves = 0;
  double speed = 540;
  double dropTimer = 0;
  bool gameActive = false;
  @override
  bool paused = false;
  bool _musicEnabled = true;
  Set<int> seenMilestones = {};

  Map<String, int> frozenSet = {};
  Map<int, int> frozenCols = {};

  double pieceVisualY = 0;
  double dangerPulse = 0;
  double comboHeat = 0;
  double animTime = 0;
  double screenShake = 0;
  int maxTile = 0;
  int _mergesThisGame = 0;

  // Mevsim sistemi
  String? activeSeason; // 'bomb', 'speed', 'ice', 'gravity', 'chaos'
  String? _lastSeason;
  String? _secondLastSeason;
  int seasonTurnsLeft = 0;
  double _seasonBombTimer = 0; // bomba mevsimi için
  int _pendingSeasonIdx = 0;
  bool _mysteryActive = false;
  bool _darknessActive = false;

  // Bar bozulma / rastgele mevsim devri (1M blok sonrası endgame)
  bool isBarBroken = false;
  bool isRandomSeasonMode = false;
  BarBreakEffect? _barBreakEffect;

  // Evrim animasyonu
  bool _evolutionActive = false;
  bool _evolutionIsSeasonCycle = false;
  double _evolutionTimer = 0.0;
  int _evolutionFrom = 0;
  int _evolutionTo = 0;
  final Set<int> _evolvedThresholds = {};
  List<(int, int)> _evolutionTargets = [];
  bool _evolutionBlastDone = false;
  double _evolutionFlash = 0.0;
  final List<(int, int)> _evolutionSeasonQueue = [];
  double _evolutionSeasonTimer = 0.0;
  double _evolutionSeasonInterval = 0.0;

  // Voltaj mevsimi
  bool _voltageActive = false;
  double _voltageElectricTimer = 0.0;
  final List<VoltageZap> _voltageZaps = [];
  List<(int, int, double)> _voltageAffectedCells = [];

  // Yanardağ mevsimi
  bool _volcanoActive = false;
  List<int> _volcanoRockRows = [];
  bool _volcanoAnimating = false;
  double _volcanoAnimTimer = 0.0;
  double _volcanoSlideOffset = 0.0;
  bool _volcanoCleanup = false;
  double _volcanoCleanupTimer = 0.0;
  double _volcanoCleanupSlide = 0.0;

  double boardX = 0;
  double boardY = 0;
  double uiScale = 1.0;
  MaxExplosion? _maxExplosion;
  final Map<int, ui.Picture> _glowCache = {};
  final Map<String, ui.Image> _blockImages = {};
  ui.Image? _bgImage;
  ui.Image? _scoreBoxImage;
  ui.Image? _bestScoreBoxImage;
  ui.Image? _yuzdeBarImage;
  ui.Image? _gameOverImage;
  ui.Image? _pauseMenuImage;
  ui.Image? _pauseBtnImage;
  Rect? _gameOverRestartRect;
  Rect? _gameOverMenuRect;
  Rect? _pauseResumeRect;
  Rect? _pauseRestartRect;
  Rect? _pauseHomeRect;
  Rect? _pauseSfxRect;
  Rect? _pauseMusicRect;
  Rect? _pauseBtnRect;
  double _pauseSfxFlash = 0.0;
  double _pauseMusicFlash = 0.0;

  // Swipe/drag kontrolleri
  double _dragTotalX = 0;
  double _dragTotalY = 0;
  bool _dragLocked = false;

  @override
  Color backgroundColor() => const Color(0xFF04040E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    board = Board();
    SoundManager.init().then((_) => SoundManager.playGameMusic());
    await _loadBest();
    try {
      _bgImage = await Flame.images.load('oyunekrannew.png');
    } catch (e) {}
    try {
      _scoreBoxImage = await Flame.images.load('score_bos.png');
    } catch (e) {}
    try {
      _bestScoreBoxImage = await Flame.images.load('bestscore_bos.png');
    } catch (e) {}
    try {
      _gameOverImage = await Flame.images.load('game_over.png');
    } catch (e) {}
    try {
      _pauseMenuImage = await Flame.images.load('pausemenu.png');
    } catch (e) {}
    try {
      _pauseBtnImage = await Flame.images.load('pause.png');
    } catch (e) {}

    try {
      _yuzdeBarImage = await Flame.images.load('yuzdebar.png');
    } catch (e) {}

    final blockMap = {
      '2': 'blokk_2',
      '4': 'blokk_4',
      '8': 'blokk_8',
      '16': 'blokk_16',
      '32': 'blokk_32',
      '64': 'blokk_64',
      '128': 'blokk_128',
      '256': 'blokk_256',
      '512': 'blokk_512',
      '1024': 'blokk_1024',
      '2048': 'blokk_2048',
      '4096': 'blokk_4096',
      '8192': 'blokk_8192',
      '16384': 'blokk_16384',
      '32768': 'blokk_32768',
      '65536': 'blokk_65536',
      '131072': 'blokk_131072',
      '262144': 'blokk_262144',
      '524288': 'blokk_524288',
      '1048576': 'blokk_1048576',
      '2097152': 'blokk_2097152',
      '4194304': 'blokk_4194304',
      '8388608': 'blokk_8388608',
      '16777216': 'blokk_16777216',
      '33554432': 'blokk_33554432',
      '67108864': 'blokk_67108864',
      '134217728': 'blokk_134217728',
      '268435456': 'blokk_268435456',
      '536870912': 'blokk_536870912',
      '1073741824': 'blokk_1073741824',
      '2147483648': 'blokk_2147483648',
      '4294967296': 'blokk_4294967296',
      '8589934592': 'blokk_8589934592',
      'joker': 'blokk_joker',
      'bomb': 'blokk_bomba',
      'ice': 'blokk_buz',
      'star': 'blokk_yokeden',
      'x2': 'blokk_2x',
      'x4': 'blokk_4x',
      'x8': 'blokk_8x',
      'x16': 'blokk_16x',
      'megabomb': 'blokk_megabomba',
      'chaos': 'kaosjoker',
      'mystery_block': 'gizemblok',
    };
    for (final entry in blockMap.entries) {
      try {
        _blockImages[entry.key] = await Flame.images.load(
          'blocks/${entry.value}.png',
        );
      } catch (_) {}
    }

    // Görseller yüklendi — gerçek görsel oranlarıyla layout'u yeniden hesapla.
    _recalcLayout();
    _initGame();
  }

  Future<void> _loadBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      best = prefs.getInt('best_score') ?? 0;
      bestCombo = prefs.getInt('best_combo') ?? 1;
    } catch (_) {}
  }

  Future<void> _saveBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('best_score', best);
      await prefs.setInt('best_combo', bestCombo);
    } catch (_) {}
  }

  ui.Picture _buildGlowPicture(Color color) {
    const pad = 1.5;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, kCell - pad * 2 + 6, kCell - pad * 2 + 6),
        const Radius.circular(10),
      ),
      Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    return recorder.endRecording();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _recalcLayout();
  }

  // Board + üst/alt UI'nin ekrana sığması için ölçek hesaplar.
  // Ekran, tasarımın gerektirdiği alandan küçükse (örn. kısa pencere/cihaz),
  // tüm board+UI katmanı oranlı şekilde küçültülür — asla büyütülmez,
  // böylece zaten sığan ekranların görünümü değişmez.
  void _recalcLayout() {
    final designW = kCols * kCell;
    final designBoardH = kRows * kCell;
    final sw0 = designW * 0.44;
    final scoreBoxH = _scoreBoxImage != null
        ? sw0 * (_scoreBoxImage!.height / _scoreBoxImage!.width)
        : 52.0;
    final topMargin = max(scoreBoxH + 8, 56.0); // skor kutusu + pause butonu
    final barH = _yuzdeBarImage != null
        ? designW * (_yuzdeBarImage!.height / _yuzdeBarImage!.width)
        : 0.0;
    final bottomMargin = barH + 4;
    final designH = topMargin + designBoardH + bottomMargin;

    uiScale = (size.x > 0 && size.y > 0)
        ? min(1.0, min(size.x / designW, size.y / designH))
        : 1.0;

    final vw = size.x / uiScale;
    final vh = size.y / uiScale;
    boardX = (vw - designW) / 2;
    boardY = (vh - designH) / 2 + topMargin;
  }

  void _initGame() {
    board.reset();
    SoundManager.stopSeasonMusic();
    score = 0;
    displayScore = 0;
    level = 1;
    combo = 1;
    streak = 0;
    streakTimer = 0;
    moveCount = 0;
    totalMoves = 0;
    _meter = 0.0;
    _meterDisplay = 0.0;
    _pendingSpecialCount = 0;
    _gravityReversed = false;
    speed = 540;
    dropTimer = 0;
    frozenSet = {};
    frozenCols = {};
    comboHeat = 0;
    pieceVisualY = 0;
    screenShake = 0;
    seenMilestones = {};
    maxTile = 0;
    _mergesThisGame = 0;
    _currentGameBestCombo = 1;
    _lastXpGained = 0;
    _xpCountTimer = 0.0;
    activeSeason = null;
    _lastSeason = null;
    _secondLastSeason = null;
    seasonTurnsLeft = 0;
    _seasonBombTimer = 0;
    _mysteryActive = false;
    _darknessActive = false;
    isBarBroken = false;
    isRandomSeasonMode = false;
    _barBreakEffect = null;
    _evolutionActive = false;
    _evolutionIsSeasonCycle = false;
    _evolutionTimer = 0.0;
    _evolutionFrom = 0;
    _evolutionTo = 0;
    _evolvedThresholds.clear();
    _evolutionTargets = [];
    _evolutionBlastDone = false;
    _evolutionFlash = 0.0;
    _evolutionSeasonQueue.clear();
    _evolutionSeasonTimer = 0.0;
    _evolutionSeasonInterval = 0.0;
    _voltageActive = false;
    _voltageElectricTimer = 0.0;
    _voltageZaps.clear();
    _voltageAffectedCells = [];
    _volcanoActive = false;
    _volcanoRockRows = [];
    _volcanoAnimating = false;
    _volcanoAnimTimer = 0.0;
    _volcanoSlideOffset = 0.0;
    _volcanoCleanup = false;
    _volcanoCleanupTimer = 0.0;
    _volcanoCleanupSlide = 0.0;
    _glowCache.clear();
    particles.seasonBg.setSeason(null);
    multiplierLines.clear();
    popCells.clear();
    _pendingDrops.clear();

    currentPiece = PieceGenerator.generate(
      score,
      moveCount,
      season: activeSeason,
    );
    if (_gravityReversed) {
      currentPiece.y = kRows - currentPiece.shape.length;
    }
    nextPiece = PieceGenerator.generate(score, moveCount, season: activeSeason);
    nextQueue.clear();
    nextQueue.add(
      PieceGenerator.generate(score, moveCount, season: activeSeason),
    );
    nextQueue.add(
      PieceGenerator.generate(score, moveCount, season: activeSeason),
    );
    pieceVisualY = currentPiece.y.toDouble();
    SoundManager.playGameMusic();
    gameActive = true;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (_volcanoAnimating) return KeyEventResult.handled;
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        gameActive = false;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _moveLeft();
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) _moveRight();
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) _moveDown();
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) _rotate();
      if (event.logicalKey == LogicalKeyboardKey.space) _hardDrop();
      if (event.logicalKey == LogicalKeyboardKey.keyR && !gameActive) {
        _initGame();
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) _togglePause();
      if (event.logicalKey == LogicalKeyboardKey.keyM) goToMenu();
      if (event.logicalKey == LogicalKeyboardKey.keyK) {
        _meter = 100.0;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyU) {
        _pendingSeasonIdx = kSeasons.indexWhere((s) => s.key == 'chaos');
        _startRandomSeason();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyA) {
        activeSeason = 'voltage';
        _voltageActive = true;
        seasonTurnsLeft = 5;
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  void onPanStart(DragStartInfo info) {
    // start positions intentionally not stored (not used elsewhere)
    _dragTotalX = 0;
    _dragTotalY = 0;
    _dragLocked = false;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!gameActive || paused || _volcanoAnimating) return;
    _dragTotalX += info.delta.global.x;
    _dragTotalY += info.delta.global.y;

    // Yatay kaydirma - sola/saga
    if (_dragTotalX.abs() > _dragTotalY.abs() * 1.8) {
      if (_dragTotalX > 20) {
        _moveRight();
        _dragTotalX = 0;
      } else if (_dragTotalX < -20) {
        _moveLeft();
        _dragTotalX = 0;
      }
    }

    // Yukari kaydirma - rotate
    if (_dragTotalY < -40 && !_dragLocked) {
      _rotate();
      _dragLocked = true;
    }

    // Asagi hizli kaydirma - hard drop (space)
    if (_dragTotalY > 60 && !_dragLocked) {
      _hardDrop();
      _dragLocked = true;
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _dragTotalX = 0;
    _dragTotalY = 0;
  }

  @override
  void onDoubleTapDown(TapDownInfo info) {
    if (!gameActive || paused || _volcanoAnimating) return;
    if (_maxExplosion != null) return;
    _rotate();
  }

  @override
  void onTapDown(TapDownInfo info) async {
    if (_volcanoAnimating) return;
    // render() içinde uygulanan uiScale ile eşleşmesi için dokunma noktası
    // board/UI'nin kullandığı sanal koordinat sistemine çevrilir.
    final tap = info.eventPosition.global / uiScale;
    final bw = kCols * kCell;
    final bh = kRows * kCell;
    final sh = _scoreBoxImage != null
        ? (bw * 0.48) * (_scoreBoxImage!.height / _scoreBoxImage!.width)
        : 52.0;

    if (paused && gameActive) {
      final p = Offset(tap.x, tap.y);
      if (_pauseResumeRect?.contains(p) == true) {
        paused = false;
        return;
      }
      if (_pauseRestartRect?.contains(p) == true) {
        _initGame();
        paused = false;
        return;
      }
      if (_pauseHomeRect?.contains(p) == true) {
        onPause?.call();
        return;
      }
      if (_pauseSfxRect?.contains(p) == true) {
        SoundManager.enabled = !SoundManager.enabled;
        _pauseSfxFlash = 1.0;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('sfx_enabled', SoundManager.enabled);
        return;
      }
      if (_pauseMusicRect?.contains(p) == true) {
        _musicEnabled = !_musicEnabled;
        if (_musicEnabled) {
          SoundManager.playGameMusic();
        } else {
          SoundManager.stopMusic();
        }
        _pauseMusicFlash = 1.0;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('music_enabled', _musicEnabled);
        return;
      }
      if (_pauseMenuImage == null) {
        const ph = 186.0;
        final pcx = boardX + bw / 2;
        final pry = boardY + bh / 2 - ph / 2;
        if (_isInsideButton(tap, pcx, pry + 90, 162, 36)) {
          _togglePause();
          return;
        }
        if (_isInsideButton(tap, pcx, pry + 140, 162, 36)) {
          goToMenu();
          return;
        }
      }
      return;
    }

    if (gameActive && _pauseBtnRect?.contains(Offset(tap.x, tap.y)) == true) {
      paused = !paused;
      return;
    }

    if (!gameActive) {
      if (_gameOverRestartRect?.contains(Offset(tap.x, tap.y)) == true) {
        _initGame();
        return;
      }
      if (_gameOverMenuRect?.contains(Offset(tap.x, tap.y)) == true) {
        onPause?.call();
        return;
      }
    }
  }

  bool _isInsideButton(Vector2 tap, double cx, double cy, double w, double h) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    return rect.contains(Offset(tap.x, tap.y));
  }

  void _drawFittedText(
    Canvas canvas,
    String text,
    Rect area,
    Color color, {
    bool bold = false,
  }) {
    double fontSize = area.height * 0.8;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: area.width);

    while (tp.width > area.width && fontSize > 8) {
      fontSize -= 1;
      tp.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
          fontFamily: 'monospace',
        ),
      );
      tp.layout(maxWidth: area.width);
    }

    tp.paint(
      canvas,
      Offset(
        area.left + (area.width - tp.width) / 2,
        area.top + (area.height - tp.height) / 2,
      ),
    );
  }

  void _drawCross(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFFFF2222)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final inset = rect.width * 0.2;
    canvas.drawLine(
      Offset(rect.left + inset, rect.top + inset),
      Offset(rect.right - inset, rect.bottom - inset),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right - inset, rect.top + inset),
      Offset(rect.left + inset, rect.bottom - inset),
      paint,
    );
  }

  void _drawOutlineText(
    Canvas canvas,
    String text,
    Rect area,
    Color color,
    Color outlineColor, {
    bool bold = false,
  }) {
    final extraChars = (text.length - 7).clamp(0, 20);
    double fontSize = area.height * 0.72 * pow(0.90, extraChars);

    TextPainter makeTp(Color c, {double? size}) => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size ?? fontSize,
          fontWeight: bold ? FontWeight.w900 : FontWeight.normal,
          color: c,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final tp = makeTp(color)..layout(maxWidth: area.width);
    while (tp.width > area.width && fontSize > 8) {
      fontSize -= 1;
      tp.text = makeTp(color, size: fontSize).text;
      tp.layout(maxWidth: area.width);
    }

    final dx = area.left + (area.width - tp.width) / 2;
    final dy = area.top + (area.height - tp.height) / 2;
    final offsets = [
      const Offset(-2, 0),
      const Offset(2, 0),
      const Offset(0, -2),
      const Offset(0, 2),
      const Offset(-2, -2),
      const Offset(2, -2),
      const Offset(-2, 2),
      const Offset(2, 2),
    ];

    for (final off in offsets) {
      final outTp = makeTp(outlineColor, size: fontSize)
        ..layout(maxWidth: area.width);
      outTp.paint(canvas, Offset(dx + off.dx, dy + off.dy));
    }
    tp.paint(canvas, Offset(dx, dy));
  }

  void _drawCurvedOutlineText(
    Canvas canvas,
    String text,
    Rect area,
    Color color,
    Color outlineColor, {
    bool bold = false,
  }) {
    final letters = text.split('');
    if (letters.isEmpty) return;

    // Slightly larger initial font size so the title appears a bit bigger
    const refLen = 5; // baseline (English "PAUSE")
    // Shrink only for up to 2 extra characters beyond the 5-char baseline
    // so strings longer than 7 chars won't trigger further shrinking.
    final extra = (text.length - refLen).clamp(0, 2);
    final scale = pow(0.90, extra);
    double fontSize = area.height * 1.06 * scale;
    // If this is the localized pause text in Turkish, boost the font size
    // so the Turkish string appears visually larger regardless of length.
    if (L10n.lang == 'tr' && text == L10n.t('pause')) {
      // base boost we want at minimum
      double boost = 1.35;
      // If the shrink `scale` dropped below 1.0 due to extra characters,
      // ensure the boost overcomes the shrink so the final size grows
      // relative to the baseline. We scale the boost up so that
      // `scale * boost >= 1.10` (i.e. at least 10% larger than baseline).
      if (scale < 1.0) {
        boost = math.max(boost, (1.10 / scale));
      }
      fontSize *= boost;
    }
    // Further reduce letter spacing so characters are tighter
    const letterSpacing = -0.4;

    List<TextPainter> buildPainters(double size) => letters
        .map(
          (letter) => TextPainter(
            text: TextSpan(
              text: letter,
              style: TextStyle(
                fontSize: size,
                fontWeight: bold ? FontWeight.w900 : FontWeight.normal,
                color: color,
                letterSpacing: letterSpacing,
              ),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          )..layout(),
        )
        .toList();

    var painters = buildPainters(fontSize);
    while (painters.fold<double>(0, (sum, tp) => sum + tp.width) +
                (letters.length - 1) * (fontSize * 0.06) >
            area.width &&
        fontSize > 8) {
      fontSize -= 1;
      painters = buildPainters(fontSize);
    }

    final totalWidth =
        painters.fold<double>(0, (sum, tp) => sum + tp.width) +
        (letters.length - 1) * (fontSize * 0.06);
    final startX = area.left + (area.width - totalWidth) / 2;
    // Use actual painter heights to center vertically (fixes CJK and shrink alignment)
    final maxPainterHeight = painters.fold<double>(
      0.0,
      (m, tp) => math.max(m, tp.height),
    );
    final baseY = area.top + (area.height - maxPainterHeight) / 2;
    // Keep the title curve subtle.
    final curveHeight = area.height * 0.08;
    final rotateSpread = 0.03;
    final outlineOffsets = [
      const Offset(-2, 0),
      const Offset(2, 0),
      const Offset(0, -2),
      const Offset(0, 2),
      const Offset(-2, -2),
      const Offset(2, -2),
      const Offset(-2, 2),
      const Offset(2, 2),
    ];

    double cursorX = startX;
    for (var i = 0; i < painters.length; i++) {
      final tp = painters[i];
      final progress = letters.length == 1 ? 0.5 : i / (letters.length - 1);
      final arc = math.sin(progress * math.pi);
      final yOffset = -curveHeight * arc;
      final angle = (progress - 0.5) * rotateSpread;
      final charX = cursorX + tp.width / 2;
      final charY = baseY + yOffset + tp.height / 2;

      for (final off in outlineOffsets) {
        canvas.save();
        canvas.translate(charX + off.dx, charY + off.dy);
        canvas.rotate(angle);
        final outTp = TextPainter(
          text: TextSpan(
            text: letters[i],
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w900 : FontWeight.normal,
              color: outlineColor,
              letterSpacing: letterSpacing,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();
        outTp.paint(canvas, Offset(-outTp.width / 2, -outTp.height / 2));
        canvas.restore();
      }

      canvas.save();
      canvas.translate(charX, charY);
      canvas.rotate(angle);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();

      // even smaller extra gap between letters
      cursorX += tp.width + fontSize * 0.02;
    }
  }

  void _togglePause() {
    if (!gameActive) return;
    paused = !paused;
    if (paused) {
      SoundManager.pauseMusic();
    } else {
      SoundManager.resumeMusic();
    }
  }

  void goToMenu() {
    SoundManager.stopSeasonMusic();
    SoundManager.stopMusic();
    gameActive = false;
    paused = true;
    onPause?.call();
  }

  bool _valid(List<List<int>> shape, int ox, int oy) {
    for (int r = 0; r < shape.length; r++) {
      for (int c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 0) continue;
        final x = ox + c, y = oy + r;
        if (x < 0 || x >= kCols) return false;

        if (_gravityReversed) {
          if (y < 0) return false; // üst sınırı taban kabul et
        } else {
          if (y >= kRows) return false; // alt sınırı taban kabul et
        }

        if (y >= 0 && y < kRows && board.cells[y][x] != 0) return false;
      }
    }
    return true;
  }

  void _moveLeft() {
    _doMoveLeft();
  }

  void _moveRight() {
    _doMoveRight();
  }

  void _doMoveLeft() {
    if (_valid(currentPiece.shape, currentPiece.x - 1, currentPiece.y)) {
      currentPiece.x--;
    }
  }

  void _doMoveRight() {
    if (_valid(currentPiece.shape, currentPiece.x + 1, currentPiece.y)) {
      currentPiece.x++;
    }
  }

  void _moveDown() {
    if (!gameActive || paused) return;
    if (_gravityReversed) {
      // Ters yerçekimi — aşağı tuşu = yukarıya doğru (tavana doğru)
      if (_valid(currentPiece.shape, currentPiece.x, currentPiece.y - 1)) {
        currentPiece.y--;
      } else {
        _lockPiece();
      }
    } else {
      // Normal yerçekimi — aşağı tuşu = aşağıya doğru
      if (_valid(currentPiece.shape, currentPiece.x, currentPiece.y + 1)) {
        currentPiece.y++;
      } else {
        _lockPiece();
      }
    }
  }

  void _rotate() {
    if (!gameActive || paused) return;
    final rot = currentPiece.rotated();
    // SRS-benzeri wall kick: merkez → sol → sağ → 2 sol → 2 sağ → zemin kick
    const kicks = [
      [0, 0],
      [-1, 0],
      [1, 0],
      [-2, 0],
      [2, 0],
      [0, -1],
      [-1, -1],
      [1, -1],
    ];
    for (final k in kicks) {
      if (_valid(rot.shape, rot.x + k[0], rot.y + k[1])) {
        currentPiece = rot;
        currentPiece.x += k[0];
        currentPiece.y += k[1];
        return;
      }
    }
  }

  void _hardDrop() {
    if (!gameActive || paused) return;
    if (_gravityReversed) {
      // Ters yerçekimi — tavana kadar git (y azal)
      while (_valid(currentPiece.shape, currentPiece.x, currentPiece.y - 1)) {
        currentPiece.y--;
      }
    } else {
      // Normal yerçekimi — tabana kadar git (y arttır)
      while (_valid(currentPiece.shape, currentPiece.x, currentPiece.y + 1)) {
        currentPiece.y++;
      }
    }
    _lockPiece();
  }

  void _lockPiece() {
    for (int r = 0; r < currentPiece.shape.length; r++) {
      for (int c = 0; c < currentPiece.shape[r].length; c++) {
        if (currentPiece.shape[r][c] != 0) {
          final br = currentPiece.y + r, bc = currentPiece.x + c;
          if (br < 0) {
            _endGame();
            return;
          }
          // Sınır dışı koruması — crash yerine graceful skip
          if (br >= kRows || bc < 0 || bc >= kCols) continue;
          board.set(br, bc, currentPiece.shape[r][c]);
          if (currentPiece.frozen) frozenSet['$br,$bc'] = 3;
        }
      }
    }

    // Bounce efekti
    for (int r = 0; r < currentPiece.shape.length; r++) {
      for (int c = 0; c < currentPiece.shape[r].length; c++) {
        if (currentPiece.shape[r][c] != 0) {
          particles.addBounce(
            (currentPiece.x + c) * kCell + kCell / 2,
            (currentPiece.y + r) * kCell + kCell / 2,
            tileColor(currentPiece.shape[r][c]),
          );
        }
      }
    }

    // Voltaj mevsimi — kilitlenen parçanın 3x3 komşularını etkile
    _applyVoltageEffect();

    moveCount++;
    totalMoves++;

    // Yanardağ — animasyon her tur tetiklenir, _endSeason son animasyon sonrası
    if (activeSeason == 'volcano') {
      _volcanoAnimating = true;
      _volcanoAnimTimer = 0.0;
      _volcanoSlideOffset = 0.0;
    }

    // Mevsim turu azalt (volcano için _endSeason _doVolcanoShift'e bırakıldı)
    if (seasonTurnsLeft > 0) {
      seasonTurnsLeft--;
      if (seasonTurnsLeft == 0 && activeSeason != 'volcano') {
        unawaited(_endSeason());
      }
    }

    // Bar bozulmuş — sezon aktif değilken her hamlede %14 ihtimalle
    // rastgele bir mevsim tetiklenir (anti-repeat kuralı korunur).
    final barBreakAnimating = _barBreakEffect != null && !_barBreakEffect!.done;
    if (isRandomSeasonMode &&
        !barBreakAnimating &&
        activeSeason == null &&
        _maxExplosion == null) {
      if (_rng.nextDouble() < 0.14) {
        _pendingSeasonIdx = _pickSeasonIdx();
        unawaited(_startRandomSeason(durationOverride: 3 + _rng.nextInt(3)));
      }
    }

    // Buz mevsimi — düşen parça frozen olsun
    if (activeSeason == 'ice') {
      currentPiece.frozen = true;
    }

    // Frozen set tick — her hamle 1 azalt, 0'a düşünce çöz
    final frozenToRemove = <String>[];
    frozenSet.forEach((k, v) {
      frozenSet[k] = v - 1;
      if (frozenSet[k]! <= 0) frozenToRemove.add(k);
    });
    for (final k in frozenToRemove) {
      frozenSet.remove(k);
    }

    // Her 5 hamlede multiplier line
    if (moveCount > 0 && moveCount % 5 == 0) _pickNewMultiplier();

    // Frozen col tick
    final toRemove = <int>[];
    frozenCols.forEach((k, v) {
      frozenCols[k] = v - 1;
      if (frozenCols[k]! <= 0) toRemove.add(k);
    });
    for (final k in toRemove) {
      frozenCols.remove(k);
    }

    _pendingSpecialCount = 0;

    SpecialResolver(
      board: board,
      frozenSet: frozenSet,
      frozenCols: frozenCols,
      addScore: (s) => _addScore(s),
      spawnParticle: (cx, cy, val) {
        particles.spawnExplosion(cx, cy);
        screenShake = 0.35;
      },
      showFloat: (msg) => particles.addFloat(
        kCols * kCell / 2,
        kRows * kCell / 3,
        msg,
        Colors.yellow,
        fontSize: 22,
      ),
      playBombSfx: () => SoundManager.bomb(),
      playMegaBombSfx: () => SoundManager.megaBomb(),
      playIceJokerSfx: () => SoundManager.iceJoker(),
      playStarSfx: () => SoundManager.starJoker(),
      onMeterGain: (gain) {
        if (isRandomSeasonMode) return;
        _meter = (_meter + gain).clamp(0.0, 100.0).toDouble();
        if (_meter >= 100.0) {
          _meter = 0.0;
          _meterDisplay = 0.0;
          _triggerMaxExplosion();
        }
      },
      onJokerTriggered: () {
        _pendingSpecialCount++;
      },
    ).resolveAll();

    final events = board.resolveMerges(
      frozenSet,
      frozenCols,
      multiplierLines,
      reverseGravity: _gravityReversed,
    );
    if (events.isNotEmpty) {
      double meterGain = 0;
      final allMerges = events;
      int specialCount = 0;

      for (final evt in allMerges) {
        final finalScore = evt.baseScore * combo;
        _addScore(finalScore);
        SoundManager.merge(evt.val);
        _mergesThisGame++;
        if (evt.val > maxTile) maxTile = evt.val;

        _checkMilestone(evt.val);
        meterGain += _getMergeFill(evt.val);
        if (evt.mult > 1) meterGain += 5.0;

        final color = tileColor(evt.val);
        particles.spawnMerge(evt.cx, evt.cy, color, evt.val);

        // Pop cell animasyonu
        final bc = (evt.cx / kCell).floor();
        final br = (evt.cy / kCell).floor();
        popCells.add(PopCell(c: bc, r: br));

        // Score popup — birleşme noktasında rastgele offset
        final ox = (_rng.nextDouble() - 0.5) * kCell * 2.5;
        final oy = -15.0 - _rng.nextDouble() * 20;
        final fs = evt.val >= 2048
            ? 30.0
            : evt.val >= 512
            ? 26.0
            : evt.val >= 128
            ? 22.0
            : evt.val >= 32
            ? 17.0
            : 13.0;
        String label = '+$finalScore';
        if (combo > 1) label += ' x$combo';
        final popColor = combo > 5
            ? const Color(0xFFFF3366)
            : combo > 2
            ? const Color(0xFFFF8040)
            : color;
        particles.addScoreFloat(evt.cx + ox, evt.cy + oy, label, popColor, fs);

        if (evt.mult > 1) {
          final mc = evt.mult >= 16
              ? const Color(0xFFC87FFF)
              : evt.mult >= 8
              ? const Color(0xFFFF3CB4)
              : evt.mult >= 4
              ? const Color(0xFFFF8C00)
              : const Color(0xFFFFD700);
          particles.addScoreFloat(evt.cx, evt.cy - 35, '${evt.mult}X!', mc, 26);
        }
        if (evt.bigBonus > 0) {
          particles.addScoreFloat(
            evt.cx,
            evt.cy - 55,
            'MEGA +${evt.bigBonus}!',
            const Color(0xFFFF2080),
            22,
          );
        }

        _incrementCombo();
      }

      // Combo bonus
      if (allMerges.length >= 2) {
        meterGain += 0.3 * allMerges.length;
      }

      // Special block bonus
      specialCount = _pendingSpecialCount;
      meterGain += 4.0 * specialCount;

      if (!isRandomSeasonMode) {
        _meter = (_meter + meterGain).clamp(0.0, 100.0).toDouble();
        if (_meter >= 100.0) {
          _meter = 0.0;
          _meterDisplay = 0.0;
          _triggerMaxExplosion();
        }
      }
    } else {
      _resetCombo();
    }

    if (_gravityReversed) {
      board.applyReverseGravity(frozenSet);
    } else {
      board.applyGravity(frozenSet);
    }

    currentPiece = nextPiece;
    if (activeSeason == 'ice') currentPiece.frozen = true;
    if (_gravityReversed) {
      currentPiece.y = kRows - currentPiece.shape.length;
    }
    nextPiece = nextQueue.removeAt(0);
    nextQueue.add(
      PieceGenerator.generate(score, moveCount, season: activeSeason),
    );
    pieceVisualY = currentPiece.y.toDouble();
    if (!_valid(currentPiece.shape, currentPiece.x, currentPiece.y)) {
      _endGame();
      return;
    }
    _updateLevel();
  }

  void _checkEvolution() {
    const thresholds = {
      1000000: (2, 4),
      5000000: (4, 8),
      10000000: (8, 16),
      20000000: (16, 32),
      30000000: (32, 64),
      50000000: (64, 128),
    };
    for (final entry in thresholds.entries) {
      if (score >= entry.key && !_evolvedThresholds.contains(entry.key)) {
        _evolvedThresholds.add(entry.key);
        _evolutionIsSeasonCycle = false;
        _startEvolution(entry.value.$1, entry.value.$2);
        return;
      }
    }
  }

  void _triggerEvolutionSeasonCycle() {
    if (_evolutionActive) return; // önceki animasyon hâlâ oynarsa kuyrukla
    final values = <int>{};
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        final v = board.get(r, c);
        if (v > 0 && v * 2 <= 536870912) values.add(v);
      }
    }
    if (values.isEmpty) return;
    final list = values.toList()..shuffle(_rng);
    _evolutionSeasonQueue.clear();
    for (final v in list.take(_rng.nextInt(2) + 3)) {
      _evolutionSeasonQueue.add((v, v * 2));
    }
    if (_evolutionSeasonQueue.isNotEmpty) {
      _evolutionIsSeasonCycle = true;
      final next = _evolutionSeasonQueue.removeAt(0);
      _startEvolution(next.$1, next.$2);
    }
  }

  void _startEvolution(int from, int to) {
    _evolutionFrom = from;
    _evolutionTo = to;
    _evolutionTimer = 0.0;
    _evolutionBlastDone = false;
    _evolutionFlash = 0.0;
    _evolutionTargets = [];
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (board.get(r, c) == from) {
          _evolutionTargets.add((r, c));
        }
      }
    }
    _evolutionActive = true;
  }

  void _pickNewMultiplier() {
    return; // multiplier lines devre dışı
    final progress = (score / 5000).clamp(0.0, 1.0);
    if (multiplierLines.length >= 2) multiplierLines.removeAt(0);
    final mults = [2, 2, 4, 4, 8, 16];
    final weights = [
      10.0,
      10.0,
      progress * 8 + 1,
      progress * 8 + 1,
      progress * 4,
      progress * 2,
    ];
    final totalW = weights.fold(0.0, (a, b) => a + b);
    double r = _rng.nextDouble() * totalW;
    int mult = 2;
    for (int i = 0; i < mults.length; i++) {
      r -= weights[i];
      if (r <= 0) {
        mult = mults[i];
        break;
      }
    }
    final isRow = _rng.nextBool();
    final index = isRow ? kRows - 2 - _rng.nextInt(5) : _rng.nextInt(kCols);
    multiplierLines.add(MultiplierLine(isRow: isRow, index: index, mult: mult));
  }

  void _addScore(int add) {
    score += add;
    if (score > best) {
      best = score;
      _saveBest();
    }
  }

  void _incrementCombo() {
    combo++;
    if (combo > _currentGameBestCombo) _currentGameBestCombo = combo;
    if (combo > bestCombo) {
      bestCombo = combo;
      _saveBest();
    }
    comboHeat = (comboHeat + 0.12).clamp(0, 1);

    if (combo >= 3) {
      SoundManager.combo(combo);
      final comboColor = combo >= 12
          ? const Color(0xFFFF3366)
          : combo >= 7
          ? const Color(0xFFFF6600)
          : combo >= 4
          ? const Color(0xFFFFCC00)
          : const Color(0xFF88FF44);
      particles.addComboWave(comboColor, combo);
      if (combo >= 5) screenShake = 0.18;
      if (combo >= 8) screenShake = 0.35;
      if (combo >= 12) {
        screenShake = 0.55;
        particles.spawnConfetti(kCols * kCell / 2, kRows * kCell / 3);
      }
    }
    streak++;
    streakTimer = 3.0;
    _checkStreakReward();
  }

  void _resetCombo() {
    combo = 1;
    comboHeat = 0;
  }

  double _getMergeFill(int value) {
    const table = {
      4: 0.2,
      8: 0.3,
      16: 0.5,
      32: 0.7,
      64: 1.0,
      128: 1.5,
      256: 2.25,
      512: 3.25,
      1024: 4.5,
      2048: 6.0,
      4096: 8.0,
      8192: 10.5,
      16384: 13.5,
      32768: 17.5,
      65536: 22.0,
      131072: 27.0,
      262144: 33.0,
      524288: 39.0,
      1048576: 45.0,
      2097152: 51.0,
      4194304: 57.0,
      8388608: 63.0,
      16777216: 69.0,
      33554432: 75.0,
      67108864: 81.0,
      134217728: 87.0,
      268435456: 93.0,
      536870912: 99.0,
      1073741824: 63.0,
      2147483648: 69.0,
      4294967296: 75.0,
      8589934592: 81.0,
    };
    if (table.containsKey(value)) return table[value]!;
    if (value > 536870912) {
      return 99.0 + (math.log(value / 536870912) / math.log(2)) * 6.0;
    }
    return 0.5;
  }

  void _checkStreakReward() {
    if (streak == 5) {
      _addScore(500);
      particles.spawnConfetti(kCols * kCell / 2, kRows * kCell / 2);
    } else if (streak == 10) {
      _addScore(2000);
      particles.spawnConfetti(kCols * kCell / 2, kRows * kCell / 2);
      screenShake = 0.35;
    } else if (streak == 20) {
      _addScore(10000);
      particles.spawnConfetti(kCols * kCell / 2, kRows * kCell / 2);
      screenShake = 0.65;
    }
  }

  void _checkMilestone(int val) {
    const milestones = [
      8,
      16,
      32,
      64,
      128,
      256,
      512,
      1024,
      2048,
      4096,
      8192,
      16384,
    ];
    if (milestones.contains(val) && !seenMilestones.contains(val)) {
      seenMilestones.add(val);
    }
  }

  int _pickSeasonIdx() {
    int seasonIdx;
    do {
      seasonIdx = _rng.nextInt(kSeasons.length);
    } while (kSeasons[seasonIdx].key == _lastSeason ||
        kSeasons[seasonIdx].key == _secondLastSeason);
    return seasonIdx;
  }

  void _triggerMaxExplosion() {
    if (_maxExplosion != null || _evolutionActive) return;
    SoundManager.pauseMusic();
    SoundManager.meterExplosion();
    // Mevcut mevsimi hemen bitir
    if (activeSeason != null) unawaited(_endSeason());

    _addScore(100000);
    screenShake = 1.2;

    _pendingSeasonIdx = _pickSeasonIdx();
    _maxExplosion = MaxExplosion(selectedSeason: _pendingSeasonIdx);
  }

  // Bar bozulma animasyonunu başlatır — 1M+ blok oluştuğunda bir kez tetiklenir.
  void _triggerBarBreak() {
    if (_barBreakEffect != null) return;
    SoundManager.barBreak();
    if (activeSeason != null) unawaited(_endSeason());
    _barBreakEffect = BarBreakEffect();
  }

  Future<void> _startRandomSeason({int? durationOverride}) async {
    debugPrint('=== _startRandomSeason çağrıldı: $_pendingSeasonIdx ===');
    activeSeason = kSeasons[_pendingSeasonIdx].key;
    _secondLastSeason = _lastSeason;
    _lastSeason = activeSeason;
    // Başarım mevsim sayacı
    const seasonAchKeyMap = {
      'bomb': 'bomba', 'ice': 'buz', 'gravity': 'yercekimi',
      'chaos': 'kaos', 'mystery': 'gizem', 'darkness': 'karanlik',
      'evolution': 'evrim', 'voltage': 'voltaj', 'volcano': 'yanardag',
    };
    final achSeasonKey = seasonAchKeyMap[activeSeason];
    if (achSeasonKey != null) {
      unawaited(AchievementManager.incrementSeasonCount(achSeasonKey));
    }
    debugPrint('=== activeSeason: $activeSeason ===');
    debugPrint(
      '_startRandomSeason: activeSeason=$activeSeason, pendingIdx=$_pendingSeasonIdx',
    );
    seasonTurnsLeft = durationOverride ??
        (activeSeason == 'mirror'
            ? 5
            : activeSeason == 'bomb'
            ? 6
            : activeSeason == 'ice'
            ? 6
            : activeSeason == 'gravity'
            ? 5
            : activeSeason == 'chaos'
            ? 6
            : activeSeason == 'mystery'
            ? 5
            : activeSeason == 'darkness'
            ? 5
            : activeSeason == 'evolution'
            ? 5
            : activeSeason == 'volcano'
            ? 3
            : activeSeason == 'voltage'
            ? 6
            : 10);
    _seasonBombTimer = 2.0;

    if (activeSeason == 'gravity') {
      _gravityReversed = true;
      // Havadaki parçayı yenile — flip sonrası çakışma olmasın
      currentPiece = PieceGenerator.generate(
        score,
        moveCount,
        season: activeSeason,
      );
      board.flipVertical(frozenSet);
      currentPiece.y = kRows - currentPiece.shape.length;
      pieceVisualY = currentPiece.y.toDouble();
    }

    // Mevsim sesini başlat
    await SoundManager.playSeasonMusic(activeSeason!);
    debugPrint('=== playSeasonMusic çağrıldı ===');

    particles.seasonBg.setSeason(
      activeSeason == 'gravity' ? null : activeSeason,
    );

    if (activeSeason == 'mystery') {
      // Tum board'daki bloklari gizle
      _mysteryActive = true;
    }
    if (activeSeason == 'darkness') {
      _darknessActive = true;
    }
    if (activeSeason == 'evolution') {
      _evolutionSeasonTimer = 0.0;
      _evolutionSeasonInterval = 2.0 + _rng.nextDouble();
      _evolutionSeasonQueue.clear();
    }
    if (activeSeason == 'voltage') {
      _voltageActive = true;
      _voltageElectricTimer = 0.0;
      _voltageZaps.clear();
      _voltageAffectedCells = [];
    }
    if (activeSeason == 'volcano') {
      _volcanoActive = true;
      _volcanoRockRows = [];
      // İlk yükselme hemen başlasın — blok beklenmeden
      _volcanoAnimating = true;
      _volcanoAnimTimer = 0.0;
      _volcanoSlideOffset = 0.0;
    }
    // Kuyruktaki eski parçaları yeni mevsime göre yenile
    nextPiece = PieceGenerator.generate(score, moveCount, season: activeSeason);
    nextQueue.clear();
    nextQueue.add(
      PieceGenerator.generate(score, moveCount, season: activeSeason),
    );
    nextQueue.add(
      PieceGenerator.generate(score, moveCount, season: activeSeason),
    );
  }

  Future<void> _endSeason() async {
    final season = activeSeason;

    // BGM'i normale döndür, mevsim müziğini durdur
    SoundManager.clearSeasonMusicFlag();
    await SoundManager.stopSeasonMusic();

    // Güvenlik kontrolü: await sırasında yeni bir mevsim başladıysa
    // bu eski continuation'ın temizleme işlemlerini atla.
    // Aksi halde activeSeason yanlışlıkla null'a çekilir ve
    // gravity gibi mevsimlerde board ters çevrilir.
    if (activeSeason != season) return;

    // Eğer 32k animasyonu devam ediyorsa oyun müziğini başlatma
    if (_maxExplosion == null) {
      SoundManager.resumeMusic();
    }

    if (season == 'mystery') _mysteryActive = false;
    if (season == 'darkness') _darknessActive = false;
    if (season == 'evolution') {
      _evolutionSeasonQueue.clear();
      _evolutionSeasonTimer = 0.0;
      _evolutionSeasonInterval = 0.0;
    }
    if (season == 'voltage') {
      _voltageActive = false;
      _voltageZaps.clear();
      _voltageAffectedCells = [];
    }
    if (season == 'volcano') {
      _volcanoAnimating = false;
      _volcanoAnimTimer = 0.0;
      _volcanoSlideOffset = 0.0;
      _volcanoActive = false;
      // Temizlik animasyonunu update loop'a devret
      _volcanoCleanup = true;
      _volcanoCleanupTimer = 0.0;
      _volcanoCleanupSlide = 0.0;
    }
    if (season == 'gravity') {
      _gravityReversed = false;
      board.flipVertical(frozenSet);
      board.applyGravity(frozenSet);
      // Ters modda havada olan parçayı normal spawn'a döndür
      currentPiece = PieceGenerator.generate(score, moveCount, season: null);
      pieceVisualY = currentPiece.y.toDouble();
    }
    particles.seasonBg.setSeason(null);
    activeSeason = null;
  }

  void _applyVoltageEffect() {
    if (!_voltageActive) return;
    final lockedCells = <(int, int)>[];
    for (int r = 0; r < currentPiece.shape.length; r++) {
      for (int c = 0; c < currentPiece.shape[r].length; c++) {
        if (currentPiece.shape[r][c] != 0) {
          lockedCells.add((currentPiece.y + r, currentPiece.x + c));
        }
      }
    }
    bool anyEffect = false;
    for (final (lr, lc) in lockedCells) {
      final lx = boardX + lc * kCell + kCell / 2;
      final ly = boardY + lr * kCell + kCell / 2;
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = lr + dr;
          final nc = lc + dc;
          if (nr < 0 || nr >= kRows || nc < 0 || nc >= kCols) continue;
          if (lockedCells.contains((nr, nc))) continue;
          final v = board.get(nr, nc);
          if (v <= 0) continue;
          final newV = (v * 2).clamp(0, 536870912).toInt();
          board.set(nr, nc, newV);
          _addScore(newV);
          final tx = boardX + nc * kCell + kCell / 2;
          final ty = boardY + nr * kCell + kCell / 2;
          _voltageZaps.add(VoltageZap(cx: lx, cy: ly, tx: tx, ty: ty));
          _voltageAffectedCells = [..._voltageAffectedCells, (nr, nc, 0.4)];
          particles.spawnExplosion(tx, ty);
          anyEffect = true;
        }
      }
    }
    if (anyEffect) {
      screenShake = 0.3;
      SoundManager.iceJoker();
      final evoEvents = board.resolveMerges(
        frozenSet,
        frozenCols,
        multiplierLines,
        reverseGravity: _gravityReversed,
      );
      for (final e in evoEvents) {
        _addScore(e.baseScore);
      }
      if (_gravityReversed) {
        board.applyReverseGravity(frozenSet);
      } else {
        board.applyGravity(frozenSet);
      }
    }
  }

  void _doVolcanoShift() {
    if (!_volcanoActive) return;
    // Tüm hücreleri 1 satır yukarı kaydır (0. satır kaybolur)
    for (int r = 0; r < kRows - 1; r++) {
      for (int c = 0; c < kCols; c++) {
        board.set(r, c, board.get(r + 1, c));
      }
    }
    // En alt satıra kayalık doldur
    for (int c = 0; c < kCols; c++) {
      board.set(kRows - 1, c, kStone);
    }
    // Kayalık satır indekslerini güncelle (hepsi 1 yukarı çıktı)
    _volcanoRockRows = _volcanoRockRows
        .map((r) => r - 1)
        .where((r) => r >= 0)
        .toList();
    _volcanoRockRows.add(kRows - 1);
    // frozenSet pozisyonlarını güncelle
    final newFrozen = <String, int>{};
    frozenSet.forEach((k, v) {
      final parts = k.split(',');
      final nr = int.parse(parts[0]) - 1;
      final c = int.parse(parts[1]);
      if (nr >= 0) newFrozen['$nr,$c'] = v;
    });
    frozenSet
      ..clear()
      ..addAll(newFrozen);
    screenShake = 0.25;
    SoundManager.bomb();
    // Son tursa mevsimi bitir — animasyon tamamlandıktan sonra
    if (seasonTurnsLeft <= 1) {
      unawaited(_endSeason());
    }
  }

  void _dropSeasonBomb() {
    final col = _randomEmptyCol();
    if (col < 0) return;
    final row = _bottomEmptyRow(col);
    if (row < 0) return;
    _pendingDrops.add(_PendingSeasonDrop(row: row, col: col, type: kBomb));
    // Görsel — belirecek yer
    particles.spawnMerge(
      col * kCell + kCell / 2,
      row * kCell + kCell / 2,
      const Color(0xFFC87FFF),
      2,
    );
  }

  void _dropSeasonChaos() {
    final col = _randomEmptyCol();
    if (col < 0) return;
    final row = _bottomEmptyRow(col);
    if (row < 0) return;
    final t = kChaos;
    _pendingDrops.add(_PendingSeasonDrop(row: row, col: col, type: t));
    particles.spawnMerge(
      col * kCell + kCell / 2,
      row * kCell + kCell / 2,
      const Color(0xFFFF88FF),
      2,
    );
  }

  int _randomEmptyCol() {
    final cols = <int>[];
    for (int c = 0; c < kCols; c++) {
      if (board.cells[0][c] == 0) cols.add(c);
    }
    if (cols.isEmpty) return -1;
    return cols[_rng.nextInt(cols.length)];
  }

  int _bottomEmptyRow(int col) {
    for (int r = kRows - 1; r >= 0; r--) {
      if (board.cells[r][col] == 0) return r;
    }
    return -1;
  }

  void _updateLevel() {
    int newLevel = 1;
    for (int i = kLevelScores.length - 1; i >= 0; i--) {
      if (score >= kLevelScores[i]) {
        newLevel = i + 1;
        break;
      }
    }
    if (newLevel != level) {
      level = newLevel;
      speed = (450.0 - (level - 1) * 10).clamp(100, 450);
      SoundManager.level();
      particles.spawnConfetti(kCols * kCell / 2, 0);
      screenShake = 0.3;
    }
  }

  Future<void> _endGame() async {
    gameActive = false;
    SoundManager.stopSeasonMusic();
    SoundManager.stopMusic();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    SoundManager.gameOver();
    if (score > best) {
      best = score;
      _saveBest();
    }

    final int tileBonus = maxTile >= 2
        ? (log(maxTile.toDouble()) / log(2) * 100).round()
        : 0;
    _lastXpGained = (score / 1000).round()
        + _currentGameBestCombo * 50
        + tileBonus;

    await ProfileManager.addXP(_lastXpGained);
    await StatsManager.recordGame(
      score: score,
      maxTile: maxTile,
      mergesThisGame: _mergesThisGame,
    );
    await AchievementManager.syncAfterGame(
      score: score,
      maxTile: maxTile,
      gamesPlayed: StatsManager.gamesPlayed,
      level: ProfileManager.level,
    );
    await LeaderboardManager.submitScore(score);
    _xpCountTimer = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    animTime += dt;
    dangerPulse = (dangerPulse + dt * 3) % (2 * pi);
    comboHeat = (comboHeat - dt * 0.006).clamp(0, 1);
    screenShake = (screenShake - dt * 2.5).clamp(0, 1);
    if (_pauseSfxFlash > 0) _pauseSfxFlash -= dt * 15;
    if (_pauseMusicFlash > 0) _pauseMusicFlash -= dt * 15;
    particles.update(dt);
    particles.seasonBg.update(dt, boardX, boardY, kCols * kCell, kRows * kCell);

    // Meter smooth animasyon
    if (_meterDisplay < _meter) {
      _meterDisplay = math.min(_meterDisplay + dt * 35, _meter);
    } else if (_meterDisplay > _meter) {
      _meterDisplay = _meter;
    }

    // Bomba mevsimi — her 2-3 saniyede rastgele bomba
    if (activeSeason == 'bomb' && gameActive && !paused && !_evolutionActive) {
      _seasonBombTimer -= dt;
      if (_seasonBombTimer <= 0) {
        _seasonBombTimer = 1.5 + _rng.nextDouble() * 1.5;
        _dropSeasonBomb();
      }
    }

    // Değiş tokuş (KAOS) mevsimi
    if (activeSeason == 'chaos' && gameActive && !paused && !_evolutionActive) {
      _seasonBombTimer -= dt;
      if (_seasonBombTimer <= 0) {
        _seasonBombTimer = 1.5 + _rng.nextDouble() * 1.5;
        _dropSeasonChaos();
      }
    }

    // Bekleyen mevsim blokları — animasyonla belir, sonra işle
    for (final d in _pendingDrops.toList()) {
      d.timer -= dt;
      if (d.timer <= 0) {
        _pendingDrops.remove(d);
        board.set(d.row, d.col, d.type);
        SpecialResolver(
          board: board,
          frozenSet: frozenSet,
          frozenCols: frozenCols,
          addScore: (s) => _addScore(s),
          spawnParticle: (cx, cy, val) {
            particles.spawnExplosion(cx, cy);
            screenShake = 0.2;
          },
          showFloat: (msg) => particles.addFloat(
            kCols * kCell / 2,
            kRows * kCell / 3,
            msg,
            Colors.yellow,
            fontSize: 22,
          ),
          playBombSfx: () => SoundManager.bomb(),
          playMegaBombSfx: () => SoundManager.megaBomb(),
          playIceJokerSfx: () => SoundManager.iceJoker(),
          playStarSfx: () => SoundManager.starJoker(),
        ).resolveAll();
        if (_gravityReversed) {
          board.applyReverseGravity(frozenSet);
        } else {
          board.applyGravity(frozenSet);
        }
        final events = board.resolveMerges(
          frozenSet,
          frozenCols,
          multiplierLines,
          reverseGravity: _gravityReversed,
        );
        for (final e in events) {
          _addScore(e.baseScore * combo);
        }
      }
    }

    // Max tile — tüm board'u tara, sadece normal pozitif değerler
    int curMax = 0;
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        final v = board.get(r, c);
        if (v > 0 && !isObstacle(v) && v > curMax) curMax = v;
      }
    }
    // Düşen parçadaki değerleri de dahil et
    for (int r = 0; r < currentPiece.shape.length; r++) {
      for (int c = 0; c < currentPiece.shape[r].length; c++) {
        final v = currentPiece.shape[r][c];
        if (v > 0 && !isObstacle(v) && v > curMax) curMax = v;
      }
    }
    if (curMax > 0) maxTile = curMax;

    // 1M+ tetikleyicisi — normal merge, joker (komşuyu 2 katlar) veya
    // X2/X4/X8/X16 gibi doğrudan board.set ile değer oluşturan tüm
    // yollar dahil, panodaki gerçek en büyük değeri esas alır.
    if (!isBarBroken && curMax >= 1000000) {
      isBarBroken = true;
      isRandomSeasonMode = true;
      _triggerBarBreak();
    }

    _maxExplosion?.update(dt);
    if (_maxExplosion?.done == true) {
      _maxExplosion = null;
      unawaited(_startRandomSeason());
    }

    _barBreakEffect?.update(dt);
    if (_barBreakEffect != null && !_barBreakEffect!.done) {
      final shakeAmt = _barBreakEffect!.shakeIntensity;
      if (shakeAmt > screenShake) screenShake = shakeAmt;
    }

    // Pop cells güncelle
    popCells.removeWhere((p) => p.t >= 1.0);
    for (final p in popCells) {
      p.t = (p.t + dt * 4.5).clamp(0, 1.0);
    }

    if (streakTimer > 0) {
      streakTimer -= dt;
      if (streakTimer <= 0) streak = 0;
    }

    if (!gameActive && _lastXpGained > 0 && _xpCountTimer < 3.5) {
      _xpCountTimer += dt;
    }

    // Skor animasyonu
    if (displayScore < score) {
      final diff = score - displayScore;
      final maxStep = math.max(99999.0, score * 0.02);
      displayScore += (diff * 0.15).clamp(1, maxStep);
      if (displayScore > score) displayScore = score.toDouble();
    }

    // Evrim mevsimi — saniye bazlı döngü
    if (activeSeason == 'evolution' &&
        gameActive &&
        !paused &&
        _maxExplosion == null) {
      _evolutionSeasonTimer += dt;
      if (_evolutionSeasonTimer >= _evolutionSeasonInterval) {
        _evolutionSeasonTimer = 0.0;
        _evolutionSeasonInterval = 2.0 + _rng.nextDouble();
        _triggerEvolutionSeasonCycle();
      }
    }

    // Evrim kontrolü ve animasyonu
    if (!_evolutionActive && gameActive && !paused && _maxExplosion == null) {
      _checkEvolution();
    }
    if (_evolutionActive) {
      _evolutionTimer += dt;
      final t = _evolutionTimer;

      // Aşama 2 — Deprem (0.5–1.4s)
      if (t >= 0.5 && t < 1.4) {
        screenShake = 0.8;
      }

      // Aşama 3 — Patlama (tek seferlik, 1.4s)
      if (t >= 1.4 && !_evolutionBlastDone) {
        _evolutionBlastDone = true;
        SoundManager.megaBomb();
        _evolutionFlash = 0.4;
        screenShake = 1.2;
        for (final target in _evolutionTargets) {
          final r = target.$1, c = target.$2;
          if (board.get(r, c) == _evolutionFrom) {
            board.set(r, c, _evolutionTo);
            particles.spawnExplosion(
              boardX + c * kCell + kCell / 2,
              boardY + r * kCell + kCell / 2,
            );
          }
        }
        if (_gravityReversed) {
          board.applyReverseGravity(frozenSet);
        } else {
          board.applyGravity(frozenSet);
        }
        final evoEvents = board.resolveMerges(
          frozenSet,
          frozenCols,
          multiplierLines,
          reverseGravity: _gravityReversed,
        );
        for (final e in evoEvents) {
          _addScore(e.baseScore);
        }
      }

      // Flash sönme
      if (_evolutionFlash > 0) {
        _evolutionFlash = (_evolutionFlash - dt * 2.0).clamp(0.0, 0.4);
      }

      // Animasyon sonu (2.7s)
      if (t >= 2.7) {
        _evolutionActive = false;
        _evolutionTimer = 0.0;
        _evolutionTargets = [];
        if (_evolutionSeasonQueue.isNotEmpty) {
          final next = _evolutionSeasonQueue.removeAt(0);
          _startEvolution(next.$1, next.$2);
        }
      }
    }

    // Voltaj mevsimi — elektrik animasyon sayacı
    if (_voltageActive && gameActive && !paused) {
      _voltageElectricTimer += dt;
    }

    // Zap animasyonları
    for (final zap in _voltageZaps) {
      zap.timer += dt;
    }
    _voltageZaps.removeWhere((z) => z.timer >= z.duration);

    // Etkilenen hücre animasyonları
    _voltageAffectedCells = [
      for (final (r, c, t) in _voltageAffectedCells)
        if (t - dt > 0) (r, c, t - dt),
    ];

    // Yanardağ temizlik animasyonu — mevsim bitince kayalıklar aşağı kayar
    if (_volcanoCleanup && gameActive && !paused) {
      _volcanoCleanupTimer += dt;
      _volcanoCleanupSlide = (_volcanoCleanupTimer / 0.5).clamp(0.0, 1.0);
      if (_volcanoCleanupTimer >= 0.5) {
        _volcanoCleanup = false;
        _volcanoCleanupTimer = 0.0;
        _volcanoCleanupSlide = 0.0;
        for (final r in _volcanoRockRows) {
          if (r >= 0 && r < kRows) {
            for (int c = 0; c < kCols; c++) {
              if (board.get(r, c) == kStone) board.set(r, c, 0);
            }
          }
        }
        _volcanoRockRows = [];
        board.applyGravity(frozenSet);
      }
    }

    // Yanardağ animasyonu — board 1 satır yukarı kayar
    if (_volcanoAnimating && gameActive && !paused && _maxExplosion == null) {
      _volcanoAnimTimer += dt;
      _volcanoSlideOffset = (_volcanoAnimTimer / 0.5).clamp(0.0, 1.0);
      if (_volcanoAnimTimer >= 0.5) {
        _volcanoAnimTimer = 0.0;
        _volcanoSlideOffset = 0.0;
        _volcanoAnimating = false;
        _doVolcanoShift();
      }
    }

    if (!gameActive ||
        paused ||
        _maxExplosion != null ||
        _volcanoAnimating ||
        (_barBreakEffect != null && !_barBreakEffect!.done)) {
      return;
    }

    final targetY = currentPiece.y.toDouble();
    if (pieceVisualY < targetY) {
      pieceVisualY = (pieceVisualY + dt * kRows / (speed / 1000)).clamp(
        0,
        targetY,
      );
    } else {
      pieceVisualY = targetY;
    }

    dropTimer += dt * 1000;
    if (dropTimer >= speed) {
      dropTimer = 0;
      if (_gravityReversed) {
        // Ters yerçekimi — yukarıya doğru hareket
        if (_valid(currentPiece.shape, currentPiece.x, currentPiece.y - 1)) {
          currentPiece.y--;
        } else {
          _lockPiece();
        }
      } else {
        // Normal yerçekimi — aşağıya doğru hareket
        if (_valid(currentPiece.shape, currentPiece.x, currentPiece.y + 1)) {
          currentPiece.y++;
        } else {
          _lockPiece();
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final shake = screenShake * 6;
    canvas.save();
    if (shake > 0.01) {
      canvas.translate(
        (_rng.nextDouble() - 0.5) * shake,
        (_rng.nextDouble() - 0.5) * shake,
      );
    }

    // DEBUG
    try {
      _drawBackground(canvas);
    } catch (e) {
      debugPrint('_drawBackground HATA: $e');
    }

    // Board + UI katmanı — ekrana sığması için uiScale ile ölçeklenir.
    canvas.save();
    canvas.scale(uiScale);
    _drawMultiplierLines(canvas);
    _drawBoard(canvas);
    _drawGhost(canvas);
    _drawPiece(canvas);
    _drawDarkness(canvas);
    particles.render(
      canvas,
      boardX,
      boardY,
      screenW: size.x / uiScale,
      screenH: size.y / uiScale,
    );
    _drawUI(canvas);
    _drawOverlays(canvas);
    _drawVoltageOverlay(canvas);
    _drawEvolutionOverlay(canvas);
    canvas.restore();

    // Tam ekran efektler — gerçek ekran boyutuyla, ölçeklenmeden.
    _maxExplosion?.render(canvas, size.x, size.y);
    _barBreakEffect?.renderFullScreen(canvas, size.x, size.y);

    canvas.restore();
  }

  void _drawBackground(Canvas canvas) {
    final s = size;
    if (_bgImage != null) {
      canvas.drawImageRect(
        _bgImage!,
        Rect.fromLTWH(
          0,
          0,
          _bgImage!.width.toDouble(),
          _bgImage!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, s.x, s.y),
        Paint(),
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, s.x, s.y),
        Paint()..color = const Color(0xFF04020E),
      );
    }
  }

  void _drawMultiplierLines(Canvas canvas) {
    return; // multiplier lines devre dışı
    for (final ml in multiplierLines) {
      final pulse = 0.5 + sin(animTime * 4 + ml.index * 0.7) * 0.5;
      final scanPos = (animTime * 0.9 + ml.index * 0.4) % 1.0;
      Color lc;
      switch (ml.mult) {
        case 16:
          lc = const Color(0xFFC87FFF);
          break;
        case 8:
          lc = const Color(0xFFFF3CB4);
          break;
        case 4:
          lc = const Color(0xFFFF8C00);
          break;
        default:
          lc = const Color(0xFFFFD700);
          break;
      }
      final rect = ml.isRow
          ? Rect.fromLTWH(
              boardX,
              boardY + ml.index * kCell,
              kCols * kCell,
              kCell,
            )
          : Rect.fromLTWH(
              boardX + ml.index * kCell,
              boardY,
              kCell,
              kRows * kCell,
            );

      // Ana dolgu
      canvas.drawRect(
        rect,
        Paint()..color = lc.withValues(alpha: 0.13 * pulse),
      );

      // Dış glow kenarlık
      canvas.drawRect(
        rect,
        Paint()
          ..color = lc.withValues(alpha: 0.45 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      // Keskin iç kenarlık
      canvas.drawRect(
        rect,
        Paint()
          ..color = lc.withValues(alpha: 0.90 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Tarama ışığı efekti
      if (ml.isRow) {
        final scanX = boardX + scanPos * kCols * kCell;
        canvas.drawRect(
          Rect.fromLTWH(
            scanX - kCell * 0.5,
            boardY + ml.index * kCell,
            kCell,
            kCell,
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.28 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
      } else {
        final scanY = boardY + scanPos * kRows * kCell;
        canvas.drawRect(
          Rect.fromLTWH(
            boardX + ml.index * kCell,
            scanY - kCell * 0.5,
            kCell,
            kCell,
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.28 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
      }

      // Çarpan etiketi — glow'lu, belirgin
      final tp = TextPainter(
        text: TextSpan(
          text: '×${ml.mult}',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: lc.withValues(alpha: 0.98),
            shadows: [
              Shadow(color: lc, blurRadius: 14),
              Shadow(color: lc, blurRadius: 28),
              Shadow(
                color: Colors.black.withValues(alpha: 0.9),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final tx = ml.isRow
          ? boardX + kCols * kCell - tp.width - 6
          : boardX + ml.index * kCell + (kCell - tp.width) / 2;
      final ty = ml.isRow
          ? boardY + ml.index * kCell + (kCell - tp.height) / 2
          : boardY + 6;
      tp.paint(canvas, Offset(tx, ty));
    }
  }

  void _drawBoard(Canvas canvas) {
    // Board arkaplanı — şeffaf cam efekti
    canvas.drawRect(
      Rect.fromLTWH(boardX, boardY, kCols * kCell, kRows * kCell),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (int c = 1; c < kCols; c++) {
      canvas.drawLine(
        Offset(boardX + c * kCell, boardY),
        Offset(boardX + c * kCell, boardY + kRows * kCell),
        gridPaint,
      );
    }
    for (int r = 1; r < kRows; r++) {
      canvas.drawLine(
        Offset(boardX, boardY + r * kCell),
        Offset(boardX + kCols * kCell, boardY + r * kCell),
        gridPaint,
      );
    }

    // Hücreler + frozen overlay + max tile glow + pop cells
    // Yanardağ animasyonu sırasında canvas clip + slide offset
    final double slideY = _volcanoAnimating
        ? -_volcanoSlideOffset * kCell
        : 0.0;
    if (_volcanoAnimating || _volcanoCleanup) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(boardX, boardY, kCols * kCell, kRows * kCell),
      );
    }

    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        final v = board.get(r, c);

        // Yanardağ kayalık satırları — aşağıda stripe olarak çizilecek
        if (_volcanoRockRows.contains(r)) continue;

        if (v == 0) {
          // Boş hücre hafif dolgu (slide yok, arka plan sabit)
          canvas.drawRect(
            Rect.fromLTWH(
              boardX + c * kCell + 1,
              boardY + r * kCell + 1,
              kCell - 2,
              kCell - 2,
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.018),
          );
          continue;
        }

        // Max tile glow
        if (v == maxTile && maxTile >= 8 && !_mysteryActive) {
          _drawMaxTileGlow(canvas, c, r, v);
        }

        // Pop cell animasyonu
        final pop = popCells.where((p) => p.c == c && p.r == r).firstOrNull;
        if (pop != null) {
          final scale = pop.t < 0.4 ? 1 + pop.t * 0.7 : 1 + (1 - pop.t) * 0.28;
          final cx = boardX + c * kCell + kCell / 2;
          final cy = boardY + r * kCell + kCell / 2 + slideY;
          canvas.save();
          canvas.translate(cx, cy);
          canvas.scale(scale, scale);
          canvas.translate(-cx, -cy);
          _drawTile(
            canvas,
            boardX + c * kCell,
            boardY + r * kCell + slideY,
            v,
            1.0 - (pop.t * 0.25),
          );
          canvas.restore();
        } else {
          _drawTile(
            canvas,
            boardX + c * kCell,
            boardY + r * kCell + slideY,
            v,
            1.0,
          );
        }

        // Frozen overlay
        if (frozenSet.containsKey('$r,$c')) _drawFrozenOverlay(canvas, c, r);
      }
    }

    // Kayalık satırları — birleşik stripe
    final double cleanupSlideY = _volcanoCleanup
        ? _volcanoCleanupSlide * (kRows + 2) * kCell
        : 0.0;
    for (final rockRow in _volcanoRockRows) {
      _drawVolcanoRockStripe(
        canvas,
        boardY + rockRow * kCell + slideY + cleanupSlideY,
        rockRow,
      );
    }

    // Gelen kayalık satır — animasyon sırasında alttan yükselir
    if (_volcanoAnimating && _volcanoSlideOffset > 0) {
      _drawVolcanoRockStripe(canvas, boardY + kRows * kCell + slideY, kRows);
    }

    if (_volcanoAnimating || _volcanoCleanup) canvas.restore();

    // Bekleyen mevsim blokları — yoğun glow + yanıp sönen efekt
    for (final d in _pendingDrops) {
      final progress = 1.0 - (d.timer / 0.60); // 0→1 arası ilerleme
      final pulse = sin(animTime * 25) * 0.5 + 0.5;
      final alpha = (0.5 + pulse * 0.5).clamp(0.0, 1.0);
      final cx = boardX + d.col * kCell + kCell / 2;
      final cy = boardY + d.row * kCell + kCell / 2;
      final color = d.type == kBomb
          ? const Color(0xFFFF4400)
          : d.type == kChaos
          ? const Color(0xFFFF88FF)
          : const Color(0xFFC87FFF);

      // Büyük dış glow halkası
      final glowR = kCell * (0.8 + progress * 0.6);
      canvas.drawCircle(
        Offset(cx, cy),
        glowR,
        Paint()..color = color.withValues(alpha: alpha * 0.35),
      );

      // İkinci halka — dışa doğru genişliyor
      canvas.drawCircle(
        Offset(cx, cy),
        kCell * (0.5 + progress),
        Paint()
          ..color = color.withValues(alpha: (1.0 - progress) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      // Üçüncü halka
      canvas.drawCircle(
        Offset(cx, cy),
        kCell * 0.4,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Tile çizimi — scale efekti ile büyüyerek beliriyor
      final scale = 0.4 + progress * 0.6;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(scale, scale);
      canvas.translate(-cx, -cy);
      _drawTile(
        canvas,
        boardX + d.col * kCell,
        boardY + d.row * kCell,
        d.type,
        alpha,
      );
      canvas.restore();
    }

    // Gizem mevsimi - board uzerine statik gurultu
    if (_mysteryActive) {
      final rng2 = math.Random((animTime * 6).toInt());
      for (int i = 0; i < 120; i++) {
        final nx = boardX + rng2.nextDouble() * kCols * kCell;
        final ny = boardY + rng2.nextDouble() * kRows * kCell;
        canvas.drawRect(
          Rect.fromLTWH(nx, ny, 1.5 + rng2.nextDouble() * 3, 1.5),
          Paint()
            ..color = Colors.white.withValues(alpha: rng2.nextDouble() * 0.12),
        );
      }
      // Yatay bozulma cizgileri
      final lineCount = rng2.nextInt(3);
      for (int i = 0; i < lineCount; i++) {
        final ly = boardY + rng2.nextDouble() * kRows * kCell;
        canvas.drawRect(
          Rect.fromLTWH(boardX, ly, kCols * kCell, 2),
          Paint()
            ..color = Colors.white.withValues(
              alpha: 0.08 + rng2.nextDouble() * 0.12,
            ),
        );
      }
    }

    // Board kenarlık — ince beyaz
    canvas.drawRect(
      Rect.fromLTWH(boardX, boardY, kCols * kCell, kRows * kCell),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // Max tile etrafında dönen parçacıklar + halo
  void _drawMaxTileGlow(Canvas canvas, int c, int r, int val) {
    if (_mysteryActive) return; // gizem mevsiminde max tile glow yok
    final cx = boardX + c * kCell + kCell / 2;
    final cy = boardY + r * kCell + kCell / 2;
    final color = tileColor(val);
    final tier = (log(val.toDouble()) / log(2)).round();
    final t = animTime;

    // Halo
    final haloR = kCell * 0.62 + (tier - 3) * 3 + sin(t * 2) * 4;
    canvas.drawCircle(
      Offset(cx, cy),
      haloR,
      Paint()..color = color.withValues(alpha: 0.30),
    );

    // Parlak kenarlık nabzı
    canvas.drawRect(
      Rect.fromLTWH(
        boardX + c * kCell + 1,
        boardY + r * kCell + 1,
        kCell - 2,
        kCell - 2,
      ),
      Paint()
        ..color = color.withValues(alpha: 0.65 + sin(t * 3) * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Dönen parçacıklar (tier >= 5)
    if (tier >= 5) {
      final count = (4 + (tier - 5) * 2).clamp(0, 12);
      final dist = kCell * 0.58 + (tier - 5) * 3;
      for (int i = 0; i < count; i++) {
        final angle = (2 * pi / count) * i + t;
        final pulse = 0.55 + sin(t * 4 + i * 1.3) * 0.45;
        final px = cx + cos(angle) * dist;
        final py = cy + sin(angle) * dist;
        final dotColor = i % 2 == 0 ? Colors.white : color;
        canvas.drawCircle(
          Offset(px, py),
          (2 + (tier - 5) * 0.6).clamp(1, 5),
          Paint()..color = dotColor.withValues(alpha: pulse),
        );
      }
    }

    // Ateş parçacıkları (tier >= 8)
    if (tier >= 8) {
      final fc = (6 + (tier - 8) * 3).clamp(0, 16);
      for (int i = 0; i < fc; i++) {
        final angle = (2 * pi / fc) * i + t * 1.85;
        final d = kCell * 0.5 + sin(t * 2.5 + i) * 5;
        final fx = cx + cos(angle) * d;
        final fy = cy + sin(angle) * d;
        canvas.drawCircle(
          Offset(fx, fy),
          (5 + (tier - 8) * 1.5).clamp(2, 12),
          Paint()
            ..color = Colors.orangeAccent.withValues(
              alpha: 0.68 + sin(t * 3 + i) * 0.32,
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }
  }

  // Frozen overlay — buz kristal efekti
  void _drawVolcanoRockStripe(Canvas canvas, double y, int rowSeed) {
    final x = boardX;
    final w = kCols * kCell;
    const h = kCell;
    final seed = rowSeed.abs();

    // 1. Koyu kahverengi taban
    canvas.drawRect(
      Rect.fromLTWH(x, y, w, h),
      Paint()..color = const Color(0xFF3D1F0A),
    );

    // 2. Alt derinlik katmanı
    canvas.drawRect(
      Rect.fromLTWH(x, y + h * 0.45, w, h * 0.55),
      Paint()..color = const Color(0xFF2A1005).withValues(alpha: 0.55),
    );

    // 3. Düzensiz taş lekeleri — deterministik oval şekiller
    final stonePaint = Paint()
      ..color = const Color(0xFF2A1005).withValues(alpha: 0.65);
    for (int i = 0; i < 9; i++) {
      final tx = x + ((i * 37 + seed * 13 + 5) % (w - 24).toInt()).toDouble();
      final ty = y + 8.0 + ((i * 11 + seed * 7) % 18).toDouble();
      final tw = 12.0 + (i * 7 + seed * 3) % 14;
      final th = 5.0 + (i * 5 + seed * 2) % 7;
      canvas.drawOval(Rect.fromLTWH(tx, ty, tw, th), stonePaint);
    }

    // 4. Pürüzlü üst kenar — kayalık dişleri
    final jagPaint = Paint()
      ..color = const Color(0xFF5D3A1A).withValues(alpha: 0.95);
    const jagCount = 22;
    final jagW = w / jagCount;
    for (int i = 0; i < jagCount; i++) {
      final tx = x + i * jagW;
      final jagH = 3.0 + (i * 5 + seed * 3) % 7;
      final path = Path()
        ..moveTo(tx, y)
        ..lineTo(tx + jagW / 2, y - jagH)
        ..lineTo(tx + jagW, y)
        ..close();
      canvas.drawPath(path, jagPaint);
    }

    // 5. Lav parıltısı — üst kenarda turuncu çizgi
    canvas.drawLine(
      Offset(x, y),
      Offset(x + w, y),
      Paint()
        ..color = const Color(0xFFFF4500)
        ..strokeWidth = 2.5,
    );

    // 6. Lav glow — yumuşak blur
    canvas.drawRect(
      Rect.fromLTWH(x, y - 3, w, 7),
      Paint()
        ..color = const Color(0xFFFF4500).withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  void _drawFrozenOverlay(Canvas canvas, int c, int r) {
    _drawFrozenOverlayAt(canvas, boardX + c * kCell, boardY + r * kCell);
  }

  void _drawFrozenOverlayAt(Canvas canvas, double x, double y) {
    final t = animTime;
    final pulse = 0.38 + sin(t * 2.0) * 0.10;
    final sparkle = 0.5 + sin(t * 5.8) * 0.5;

    // Ana buz tabakası
    canvas.drawRect(
      Rect.fromLTWH(x + 1, y + 1, kCell - 2, kCell - 2),
      Paint()..color = const Color(0xFF6EC8FF).withValues(alpha: pulse * 0.75),
    );

    // İç açık katman
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 4, y + 4, kCell - 8, kCell - 8),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFB8ECFF).withValues(alpha: 0.20),
    );

    // Kar kristali — merkez + 6 kol (snowflake)
    final cx = x + kCell / 2, cy = y + kCell / 2;
    final armLen = kCell * 0.30;
    final crystalAlpha = 0.60 + sin(t * 1.6) * 0.18;
    final crystalPaint = Paint()
      ..color = const Color(0xFFDCF8FF).withValues(alpha: crystalAlpha)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final branchPaint = Paint()
      ..color = const Color(0xFFDCF8FF).withValues(alpha: crystalAlpha * 0.75)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + t * 0.12;
      final tipX = cx + cos(angle) * armLen;
      final tipY = cy + sin(angle) * armLen;
      canvas.drawLine(Offset(cx, cy), Offset(tipX, tipY), crystalPaint);
      final branchLen = armLen * 0.38;
      canvas.drawLine(
        Offset(tipX, tipY),
        Offset(
          tipX + cos(angle + math.pi / 3.5) * branchLen,
          tipY + sin(angle + math.pi / 3.5) * branchLen,
        ),
        branchPaint,
      );
      canvas.drawLine(
        Offset(tipX, tipY),
        Offset(
          tipX + cos(angle - math.pi / 3.5) * branchLen,
          tipY + sin(angle - math.pi / 3.5) * branchLen,
        ),
        branchPaint,
      );
    }

    // Merkez yıldız noktası
    canvas.drawCircle(
      Offset(cx, cy),
      1.8,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    // Köşe sparkle noktaları
    final corners = [
      Offset(x + 5, y + 5),
      Offset(x + kCell - 5, y + 5),
      Offset(x + 5, y + kCell - 5),
      Offset(x + kCell - 5, y + kCell - 5),
    ];
    for (int i = 0; i < corners.length; i++) {
      final sp = sparkle * (0.55 + sin(t * 3.8 + i * 1.3) * 0.45);
      canvas.drawCircle(
        corners[i],
        2.2,
        Paint()
          ..color = Colors.white.withValues(alpha: sp)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Sol üst cam yansıması
    canvas.drawRect(
      Rect.fromLTWH(x + 4, y + 4, (kCell - 6) * 0.40, (kCell - 6) * 0.16),
      Paint()..color = Colors.white.withValues(alpha: 0.40),
    );

    // Dış buz kenarlık glow
    canvas.drawRect(
      Rect.fromLTWH(x + 1, y + 1, kCell - 2, kCell - 2),
      Paint()
        ..color = const Color(
          0xFF90DDFF,
        ).withValues(alpha: 0.85 + sin(t * 2.4) * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  void _drawTile(
    Canvas canvas,
    double x,
    double y,
    int val,
    double alpha, {
    bool ghost = false,
  }) {
    final color = tileColor(val);
    const pad = 2.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + pad, y + pad, kCell - pad * 2, kCell - pad * 2),
      const Radius.circular(14),
    );

    if (ghost) {
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.12));
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      return;
    }

    if (_mysteryActive && val != 0 && !isObstacle(val)) {
      final imgKey = 'mystery_block';
      if (_blockImages.containsKey(imgKey)) {
        final img = _blockImages[imgKey]!;
        final src = Rect.fromLTWH(
          0,
          0,
          img.width.toDouble(),
          img.height.toDouble(),
        );
        final dst = Rect.fromLTWH(
          x + pad,
          y + pad,
          kCell - pad * 2,
          kCell - pad * 2,
        );
        canvas.save();
        canvas.clipRRect(
          RRect.fromRectAndRadius(dst, const Radius.circular(6)),
        );
        canvas.drawImageRect(
          img,
          src,
          dst,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..color = Colors.white.withValues(alpha: alpha),
        );
        canvas.restore();
      }
      return;
    }

    // PNG blok çizimi
    String? imgKey;
    if (val == 2) {
      imgKey = '2';
    } else if (val == 4) {
      imgKey = '4';
    } else if (val == 8) {
      imgKey = '8';
    } else if (val == 16) {
      imgKey = '16';
    } else if (val == 32) {
      imgKey = '32';
    } else if (val == 64) {
      imgKey = '64';
    } else if (val == 128) {
      imgKey = '128';
    } else if (val == 256) {
      imgKey = '256';
    } else if (val == 512) {
      imgKey = '512';
    } else if (val == 1024) {
      imgKey = '1024';
    } else if (val == 2048) {
      imgKey = '2048';
    } else if (val == 4096) {
      imgKey = '4096';
    } else if (val == 8192) {
      imgKey = '8192';
    } else if (val == 32768) {
      imgKey = '32768';
    } else if (val == 65536) {
      imgKey = '65536';
    } else if (val == 131072) {
      imgKey = '131072';
    } else if (val == 262144) {
      imgKey = '262144';
    } else if (val == 524288) {
      imgKey = '524288';
    } else if (val == 1048576) {
      imgKey = '1048576';
    } else if (val == 2097152) {
      imgKey = '2097152';
    } else if (val == 4194304) {
      imgKey = '4194304';
    } else if (val == 8388608) {
      imgKey = '8388608';
    } else if (val == 16777216) {
      imgKey = '16777216';
    } else if (val == 33554432) {
      imgKey = '33554432';
    } else if (val == 67108864) {
      imgKey = '67108864';
    } else if (val == 134217728) {
      imgKey = '134217728';
    } else if (val == 268435456) {
      imgKey = '268435456';
    } else if (val == 536870912) {
      imgKey = '536870912';
    } else if (val == 1073741824) {
      imgKey = '1073741824';
    } else if (val == 2147483648) {
      imgKey = '2147483648';
    } else if (val == 4294967296) {
      imgKey = '4294967296';
    } else if (val == 8589934592) {
      imgKey = '8589934592';
    } else if (val >= 16384) {
      imgKey = '16384';
    } else if (val == kJoker) {
      imgKey = 'joker';
    } else if (val == kBomb) {
      imgKey = 'bomb';
    } else if (val == kIce) {
      imgKey = 'ice';
    } else if (val == kStar) {
      imgKey = 'star';
    } else if (val == kX2) {
      imgKey = 'x2';
    } else if (val == kX4) {
      imgKey = 'x4';
    } else if (val == kX8) {
      imgKey = 'x8';
    } else if (val == kX16) {
      imgKey = 'x16';
    } else if (val == kMegaBomb) {
      imgKey = 'megabomb';
    } else if (val == kChaos) {
      imgKey = 'chaos';
    }

    if (imgKey != null && _blockImages.containsKey(imgKey)) {
      final img = _blockImages[imgKey]!;
      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      final dst = Rect.fromLTWH(
        x + pad,
        y + pad,
        kCell - pad * 2,
        kCell - pad * 2,
      );
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          dst,
          Radius.circular(val == kX2 ? 9 : 6),
        ),
      );
      canvas.drawImageRect(
        img,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Colors.white.withValues(alpha: alpha),
      );
      canvas.restore();
      return;
    }

    final glowPic = _glowCache.putIfAbsent(
      color.toARGB32(),
      () => _buildGlowPicture(color),
    );
    canvas.save();
    canvas.translate(x, y);
    canvas.drawPicture(glowPic);
    canvas.restore();

    // Ana dolgu — hafif koyu alt, parlak üst gradient hissi
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: alpha));

    // Üst 1/3 — açık ton (3D tepe ışığı)
    final lightColor = HSVColor.fromColor(color)
        .withValue((HSVColor.fromColor(color).value + 0.25).clamp(0, 1))
        .withSaturation(
          (HSVColor.fromColor(color).saturation - 0.15).clamp(0, 1),
        )
        .toColor();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + pad,
          y + pad,
          kCell - pad * 2,
          (kCell - pad * 2) * 0.45,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = lightColor.withValues(alpha: 0.55 * alpha),
    );

    // Alt 1/4 — koyu ton (3D gölge)
    final darkColor = HSVColor.fromColor(
      color,
    ).withValue((HSVColor.fromColor(color).value - 0.25).clamp(0, 1)).toColor();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + pad,
          y + kCell - pad - (kCell - pad * 2) * 0.28,
          kCell - pad * 2,
          (kCell - pad * 2) * 0.28,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = darkColor.withValues(alpha: 0.6 * alpha),
    );

    // Sol üst köşe parlama — spot ışığı hissi
    canvas.drawCircle(
      Offset(x + pad + 7, y + pad + 7),
      9,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // İnce parlak üst kenar çizgisi
    canvas.drawLine(
      Offset(x + pad + 8, y + pad + 1.5),
      Offset(x + kCell - pad - 8, y + pad + 1.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5 * alpha)
        ..strokeWidth = 1.5,
    );

    // Dış kenarlık — ince, parlak
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // İç kenarlık — rengin açık tonu
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + pad + 1.5,
          y + pad + 1.5,
          kCell - pad * 2 - 3,
          kCell - pad * 2 - 3,
        ),
        const Radius.circular(6),
      ),
      Paint()
        ..color = lightColor.withValues(alpha: 0.18 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Label
    final label = _getTileLabel(val);
    final fontSize = val < 0
        ? (label.length > 2 ? 13.0 : 19.0)
        : (val >= 10000
              ? 10.0
              : val >= 1000
              ? 12.0
              : val >= 100
              ? 15.0
              : 19.0);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: alpha),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.9),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            Shadow(color: color, blurRadius: 10),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(x + kCell / 2 - tp.width / 2, y + kCell / 2 - tp.height / 2 + 1),
    );
  }

  String _getTileLabel(int val) {
    switch (val) {
      case kJoker:
        return '★';
      case kBomb:
        return '💣';
      case kMegaBomb:
        return '💥';
      case kIce:
        return '❄';
      case kX2:
        return '×2';
      case kX4:
        return '×4';
      case kX8:
        return '×8';
      case kX16:
        return '×16';
      case kStar:
        return '✦';
      case kChaos:
        return '🔀';
      case kStone:
        return '⬛';
      case kLocked:
        return '🔒';
      case kDoubleHit:
        return '💢';
      case kSpinner:
        return '↺';
      case kDark:
        return '?';
      default:
        return val > 0 ? val.toString() : '';
    }
  }

  void _drawGhost(Canvas canvas) {
    if (_mysteryActive) return; // gizem mevsiminde ghost yok
    if (!gameActive) return;
    int gy = currentPiece.y;
    if (_gravityReversed) {
      while (_valid(currentPiece.shape, currentPiece.x, gy - 1)) {
        gy--;
      }
    } else {
      while (_valid(currentPiece.shape, currentPiece.x, gy + 1)) {
        gy++;
      }
    }
    if (gy != currentPiece.y) {
      for (int r = 0; r < currentPiece.shape.length; r++) {
        for (int c = 0; c < currentPiece.shape[r].length; c++) {
          final v = currentPiece.shape[r][c];
          if (v != 0) {
            _drawTile(
              canvas,
              boardX + (currentPiece.x + c) * kCell,
              boardY + (gy + r) * kCell,
              v,
              0.18,
              ghost: true,
            );
          }
        }
      }
    }
  }

  void _drawDarkness(Canvas canvas) {
    if (!_darknessActive || !gameActive) return;
    final cx =
        boardX + (currentPiece.x + currentPiece.shape[0].length / 2) * kCell;
    final cy = boardY + (pieceVisualY + currentPiece.shape.length / 2) * kCell;
    final boardRect = Rect.fromLTWH(
      boardX,
      boardY,
      kCols * kCell,
      kRows * kCell,
    );
    canvas.saveLayer(boardRect, Paint());
    canvas.drawRect(boardRect, Paint()..color = Colors.black);
    canvas.drawCircle(
      Offset(cx, cy),
      kCell * 2.5,
      Paint()..blendMode = BlendMode.dstOut,
    );
    canvas.restore();
  }

  void _drawPiece(Canvas canvas) {
    if (!gameActive) return;
    final offsetY = (pieceVisualY - pieceVisualY.floorToDouble()) * kCell;
    for (int r = 0; r < currentPiece.shape.length; r++) {
      for (int c = 0; c < currentPiece.shape[r].length; c++) {
        final v = currentPiece.shape[r][c];
        if (v != 0) {
          final px = boardX + (currentPiece.x + c) * kCell;
          final py =
              boardY + (pieceVisualY.floorToDouble() + r) * kCell + offsetY;
          _drawTile(canvas, px, py, v, 1.0);

          // Frozen parça — üzerine buz efekti çiz
          if (currentPiece.frozen) {
            _drawFrozenOverlayAt(canvas, px, py);
          }
        }
      }
    }
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

  void _drawUI(Canvas canvas) {
    final bw = kCols * kCell;
    final rpW = 80.0;
    final rpX = boardX + bw - 4;
    final sw = bw * 0.44;
    final ssBw = bw * 0.44;
    final gap = bw * 0.12;
    const pauseBtnSize = 38.0;
    final sh = _scoreBoxImage != null
        ? sw * (_scoreBoxImage!.height / _scoreBoxImage!.width)
        : 52.0;

    // === SKOR PANELİ ===
    if (_scoreBoxImage != null) {
      final scoreStr = _formatScore(displayScore.toInt());
      const scoreFontSize = 16.0;
      canvas.drawImageRect(
        _scoreBoxImage!,
        Rect.fromLTWH(
          0,
          0,
          _scoreBoxImage!.width.toDouble(),
          _scoreBoxImage!.height.toDouble(),
        ),
        Rect.fromLTWH(boardX, boardY - sh - 8, sw, sh),
        Paint(),
      );
      _drawTextCentered(
        canvas,
        scoreStr,
        boardX - bw * 0.01 + sw / 2 + 2,
        boardY - sh / 2 - 10 + bw * 0.005,
        scoreFontSize,
        const Color(0xFFFFC944),
        bold: true,
        fontWeight: FontWeight.w800,
      );
    }

    if (_bestScoreBoxImage != null) {
      final bestStr = _formatScore(best);
      const bestFontSize = 16.0;
      final bsh =
          ssBw * (_bestScoreBoxImage!.height / _bestScoreBoxImage!.width);
      final bestTextOffsetX = bw * 0.01;
      final bestTextOffsetY = bw * 0.005;
      canvas.drawImageRect(
        _bestScoreBoxImage!,
        Rect.fromLTWH(
          0,
          0,
          _bestScoreBoxImage!.width.toDouble(),
          _bestScoreBoxImage!.height.toDouble(),
        ),
        Rect.fromLTWH(boardX + sw + gap, boardY - sh - 8, ssBw, bsh),
        Paint(),
      );
      _drawTextCentered(
        canvas,
        bestStr,
        boardX + sw + gap + ssBw / 2 + 10 + bestTextOffsetX,
        boardY - sh / 2 - 10 + bestTextOffsetY,
        bestFontSize,
        const Color(0xFFFFC944),
        bold: true,
        fontWeight: FontWeight.w800,
      );
    }

    // Pause butonu — ortada
    if (_pauseBtnImage != null) {
      final pbx = boardX + bw * 0.435;
      final pby = boardY - 48.0;
      canvas.drawImageRect(
        _pauseBtnImage!,
        Rect.fromLTWH(
          0,
          0,
          _pauseBtnImage!.width.toDouble(),
          _pauseBtnImage!.height.toDouble(),
        ),
        Rect.fromLTWH(pbx, pby, pauseBtnSize, pauseBtnSize),
        Paint(),
      );
      _pauseBtnRect = Rect.fromLTWH(pbx, pby, pauseBtnSize, pauseBtnSize);
    } else {
      _pauseBtnRect = Rect.fromLTWH(
        boardX + bw * 0.435,
        boardY - 48.0,
        pauseBtnSize,
        pauseBtnSize,
      );
    }

    if (_yuzdeBarImage != null) {
      final bw = kCols * kCell;
      final barW = bw;
      final barH = barW * (_yuzdeBarImage!.height / _yuzdeBarImage!.width);
      final barX = boardX;
      final barY = boardY + kRows * kCell + 4;
      final barRect = Rect.fromLTWH(barX, barY, barW, barH);
      final breakEffect = _barBreakEffect;

      canvas.save();
      if (breakEffect != null) {
        canvas.translate(breakEffect.shakeOffset.dx, breakEffect.shakeOffset.dy);
      }

      // Bar görseli HER ZAMAN çizilir — bar kırılınca da kalkmaz, yerinde durur.
      canvas.drawImageRect(
        _yuzdeBarImage!,
        Rect.fromLTWH(
          0,
          0,
          _yuzdeBarImage!.width.toDouble(),
          _yuzdeBarImage!.height.toDouble(),
        ),
        Rect.fromLTWH(barX, barY, barW, barH),
        Paint()..filterQuality = FilterQuality.high,
      );

      // Dolum/yüzde — sadece bar kırılmamışken (meter sistemi aktifken) gösterilir.
      if (!isBarBroken) {
        // Dolum barı padding
        final fillPadXLeft = barW * 0.065;
        final fillPadXRight = barW * 0.18;
        final fillPadY = barH * 0.31;
        final fillMaxW = barW - fillPadXLeft - fillPadXRight;
        final fillH = barH * 0.40;
        final fillW = fillMaxW * (_meterDisplay / 100.0);
        final fillX = barX + fillPadXLeft + 4;
        final fillY = barY + fillPadY;

        // Koyu arka plan
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(fillX, fillY, fillMaxW, fillH),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xFF1A0A00),
        );

        // Sarı dolum — gradient hissi için iki katman
        if (fillW > 2) {
          // Ana dolum
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(fillX, fillY, fillW, fillH),
              const Radius.circular(8),
            ),
            Paint()..color = const Color(0xFFFFAA00),
          );

          // Üst parlak şerit
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(fillX, fillY, fillW, fillH * 0.40),
              const Radius.circular(8),
            ),
            Paint()..color = const Color(0xFFFFE566).withValues(alpha: 0.7),
          );

          // Alt koyu şerit
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(fillX, fillY + fillH * 0.65, fillW, fillH * 0.35),
              const Radius.circular(8),
            ),
            Paint()..color = const Color(0xFFCC6600).withValues(alpha: 0.5),
          );

          // Parlak iç kenar
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(fillX, fillY, fillW, fillH),
              const Radius.circular(8),
            ),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.15)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }

        // Yüzde sayacı — barın ortasında (her zaman gösterilsin)
        final pct = _meterDisplay.clamp(0.0, 100.0);
        final pctStr =
            '${pct == 0.0 ? '0' : pct.toStringAsFixed(1).replaceFirst(RegExp(r'^0'), '')}%';
        final pctArea = Rect.fromLTWH(
          barX + barW * 0.35,
          barY + fillPadY,
          barW * 0.30,
          fillH,
        );
        _drawFittedText(canvas, pctStr, pctArea, Colors.white, bold: true);
      }

      canvas.restore();

      if (isBarBroken) {
        breakEffect?.renderBar(canvas, barRect);
      }
    }

    // === SAĞ PANEL: MEVSİM ===
    if (activeSeason != null && seasonTurnsLeft > 0) {
      final si = kSeasons.firstWhere(
        (s) => s.key == activeSeason,
        orElse: () => kSeasons[0],
      );
      final sColor = si.color;
      final pulse = 0.7 + sin(animTime * 3) * 0.3;
      const siH = 54.0;
      final siY = boardY + 123;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rpX, siY, rpW, siH),
          const Radius.circular(10),
        ),
        Paint()..color = sColor.withValues(alpha: 0.15),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rpX, siY, rpW, siH),
          const Radius.circular(10),
        ),
        Paint()
          ..color = sColor.withValues(alpha: pulse * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      _drawTextCentered(
        canvas,
        '${si.emoji} ${si.name}',
        rpX + rpW / 2,
        siY + 18,
        8,
        sColor.withValues(alpha: pulse),
        bold: true,
      );
      _drawTextCentered(
        canvas,
        '$seasonTurnsLeft TUR',
        rpX + rpW / 2,
        siY + 36,
        9,
        sColor.withValues(alpha: pulse),
        bold: true,
      );
    }
  }

  void _drawRightBox(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    String label,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF1E64C8).withValues(alpha: 0.68),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(10),
      ),
      Paint()
        ..color = const Color(0xFF4A9EFF).withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawTextCentered(
      canvas,
      label,
      x + w / 2,
      y + 14,
      9,
      Colors.white.withValues(alpha: 0.85),
    );
  }

  double _getLevelProgress() {
    final lv = level;
    final cur = lv - 1 < kLevelScores.length ? kLevelScores[lv - 1] : 0;
    final next = lv < kLevelScores.length
        ? kLevelScores[lv]
        : kLevelScores.last;
    return ((score - cur) / (next - cur)).clamp(0.0, 1.0);
  }

  void _drawMiniTile(Canvas canvas, double x, double y, int val) {
    final color = tileColor(val);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, 18, 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 1, y + 1, 16, 6),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawVoltageZapLine(
    Canvas canvas,
    double x1,
    double y1,
    double x2,
    double y2,
    double alpha,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final path = Path()..moveTo(x1, y1);
    const segments = 6;
    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final px = x1 + dx * t + (_rng.nextDouble() - 0.5) * 20;
      final py = y1 + dy * t + (_rng.nextDouble() - 0.5) * 20;
      path.lineTo(px, py);
    }
    path.lineTo(x2, y2);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00FFFF).withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFFF00).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawVoltageOverlay(Canvas canvas) {
    if (!_voltageActive &&
        _voltageZaps.isEmpty &&
        _voltageAffectedCells.isEmpty) {
      return;
    }

    // ── 1. Düşen parça elektrik efekti ──────────────────────────
    if (_voltageActive && gameActive && !paused) {
      final pulse = math.sin(_voltageElectricTimer * math.pi * 6) * 0.15 + 0.85;
      final haloPulse =
          0.4 + math.sin(_voltageElectricTimer * math.pi * 3) * 0.2;
      for (int r = 0; r < currentPiece.shape.length; r++) {
        for (int c = 0; c < currentPiece.shape[r].length; c++) {
          if (currentPiece.shape[r][c] == 0) continue;
          final cx = boardX + (currentPiece.x + c) * kCell + kCell / 2;
          final cy = boardY + pieceVisualY * kCell + r * kCell + kCell / 2;
          // Büyük parlayan halo
          canvas.drawCircle(
            Offset(cx, cy),
            kCell * 0.9,
            Paint()
              ..color = const Color(
                0xFF00FFFF,
              ).withValues(alpha: haloPulse * 0.5)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
          );
          canvas.drawCircle(
            Offset(cx, cy),
            kCell * 0.6,
            Paint()
              ..color = const Color(
                0xFFFFFF00,
              ).withValues(alpha: haloPulse * 0.4)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(cx, cy),
                width: kCell - 2,
                height: kCell - 2,
              ),
              const Radius.circular(6),
            ),
            Paint()
              ..color = const Color(0xFFFFFF00).withValues(alpha: pulse * 0.45)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          );
          // Şimşek çizgileri — her frame yeni rastgele pozisyon
          final zapCount = 5 + _rng.nextInt(4);
          for (int i = 0; i < zapCount; i++) {
            final angle = _rng.nextDouble() * math.pi * 2;
            final len = 12.0 + _rng.nextDouble() * 20.0;
            final sx = cx + math.cos(angle) * (kCell * 0.45);
            final sy = cy + math.sin(angle) * (kCell * 0.45);
            canvas.drawLine(
              Offset(sx, sy),
              Offset(sx + math.cos(angle) * len, sy + math.sin(angle) * len),
              Paint()
                ..color =
                    (_rng.nextBool()
                            ? const Color(0xFF00FFFF)
                            : const Color(0xFFFFFF00))
                        .withValues(alpha: 0.7 + _rng.nextDouble() * 0.3)
                ..strokeWidth = 4.0 + _rng.nextDouble() * 2.0,
            );
          }
        }
      }
    }

    // ── 2. Şimşek çizgileri (zap) ────────────────────────────────
    for (final zap in _voltageZaps) {
      final alpha = (1.0 - zap.timer / zap.duration).clamp(0.0, 1.0);
      _drawVoltageZapLine(canvas, zap.cx, zap.cy, zap.tx, zap.ty, alpha);
    }

    // ── 3. Etkilenen hücre parlaması ─────────────────────────────
    for (final (r, c, timer) in _voltageAffectedCells) {
      final alpha = (timer / 0.4).clamp(0.0, 0.6);
      final cx = boardX + c * kCell + kCell / 2;
      final cy = boardY + r * kCell + kCell / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: kCell.toDouble(),
            height: kCell.toDouble(),
          ),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFFFFFF00).withValues(alpha: alpha * 0.5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: kCell + 4.0,
            height: kCell + 4.0,
          ),
          const Radius.circular(8),
        ),
        Paint()
          ..color = const Color(0xFF00BFFF).withValues(alpha: alpha * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _drawEvolutionOverlay(Canvas canvas) {
    if (!_evolutionActive) return;
    final t = _evolutionTimer;
    final sw = size.x / uiScale, sh = size.y / uiScale;
    final cx = sw / 2, cy = sh / 2;

    // Hedef blok vurgusu için alpha — overlay yok, board görünür kalır
    final double overlayAlpha;
    if (t < 0.5) {
      overlayAlpha = (t / 0.5) * 0.65;
    } else if (t >= 2.4) {
      overlayAlpha = ((2.7 - t) / 0.3).clamp(0.0, 1.0) * 0.65;
    } else {
      overlayAlpha = 0.65;
    }

    // Kırmızı flash (patlama anı)
    if (_evolutionFlash > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, sw, sh),
        Paint()
          ..color = const Color(0xFFFF1111).withValues(alpha: _evolutionFlash),
      );
    }

    // Nabzeden hedef bloklar (patlama öncesi, 0–1.4s)
    if (t < 1.4) {
      final pulseFreq = t >= 0.5 ? 14.0 : 7.0; // depremde daha hızlı
      final pulse = (math.sin(animTime * pulseFreq) * 0.5 + 0.5);
      final highlightAlpha = ((0.35 + pulse * 0.65) * (overlayAlpha / 0.65))
          .clamp(0.0, 1.0);
      for (final target in _evolutionTargets) {
        final r = target.$1, c = target.$2;
        if (board.get(r, c) == _evolutionFrom) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                boardX + c * kCell + 2,
                boardY + r * kCell + 2,
                kCell - 4,
                kCell - 4,
              ),
              const Radius.circular(6),
            ),
            Paint()
              ..color = const Color(
                0xFFFF3333,
              ).withValues(alpha: highlightAlpha),
          );
        }
      }
    }

    // Ana metin (0→2.4s)
    if (t < 2.4) {
      final rawAlpha = (t < 0.3 ? t / 0.3 : 1.0).clamp(0.0, 1.0);
      // Mevsim döngüsünde daha küçük ve saydam
      final textAlpha = _evolutionIsSeasonCycle
          ? (rawAlpha * 0.6).clamp(0.0, 0.6)
          : rawAlpha;
      final mainFontSize = _evolutionIsSeasonCycle ? 28.0 : 40.0;
      final subFontSize = _evolutionIsSeasonCycle ? 14.0 : 20.0;
      final subOffsetY = _evolutionIsSeasonCycle ? 22.0 : 28.0;

      // Evrilen değerleri kısa string'e çevir
      String valStr(int v) => v >= 1000 ? '${v ~/ 1000}K' : '$v';
      final fromStr = valStr(_evolutionFrom);
      final toStr = valStr(_evolutionTo);
      final evolvingText = L10n.t('evolving')
          .replaceAll('{from}', _evolutionFrom.toString())
          .replaceAll('{to}', _evolutionTo.toString());

      // Glow çemberi
      canvas.drawCircle(
        Offset(cx, cy - 18),
        85,
        Paint()
          ..color = const Color(0xFFFF2222).withValues(alpha: textAlpha * 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );

      // Üst satır: büyük değer göstergesi
      _drawEvolutionValueText(
        canvas,
        '$fromStr → $toStr',
        cx,
        cy - 22,
        textAlpha,
        fontSize: mainFontSize,
      );

      // Alt satır: localized evrim metni
      _drawTextCentered(
        canvas,
        evolvingText,
        cx,
        cy + subOffsetY,
        subFontSize,
        Colors.white.withValues(alpha: textAlpha * 0.92),
        bold: true,
      );
    }
  }

  void _drawEvolutionValueText(
    Canvas canvas,
    String text,
    double cx,
    double cy,
    double alpha, {
    double fontSize = 40,
  }) {
    final shadows = <Shadow>[
      Shadow(
        color: Colors.black.withValues(alpha: 0.9),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
      Shadow(
        color: const Color(0xFFFF0000).withValues(alpha: alpha * 0.9),
        blurRadius: 20,
      ),
      Shadow(
        color: const Color(0xFFFF0000).withValues(alpha: alpha * 0.5),
        blurRadius: 40,
      ),
    ];
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFF4444).withValues(alpha: alpha),
            shadows: shadows,
          ),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawTextCentered(
    Canvas canvas,
    String text,
    double cx,
    double cy,
    double size,
    Color color, {
    bool bold = false,
    FontWeight? fontWeight,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          textStyle: TextStyle(
            fontSize: size,
            fontWeight:
                fontWeight ?? (bold ? FontWeight.w800 : FontWeight.w600),
            color: color,
          ),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawMenuButton(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
    String label,
    Color color,
  ) {
    final pulse = 0.65 + sin(animTime * 3.2) * 0.35;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      const Radius.circular(9),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = color.withValues(alpha: 0.15 * pulse),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.50 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    _drawTextCentered(canvas, label, cx, cy, 11, color, bold: true);
  }

  void _drawOverlays(Canvas canvas) {
    final bw = kCols * kCell, bh = kRows * kCell;
    final vw = size.x / uiScale, vh = size.y / uiScale;

    // Pause
    if (paused && gameActive && _pauseMenuImage != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, vw, vh),
        Paint()..color = Colors.black.withValues(alpha: 0.75),
      );

      final pw = vw * 0.80;
      final ph = pw * (_pauseMenuImage!.height / _pauseMenuImage!.width);
      final px = (vw - pw) / 2;
      final py = (vh - ph) / 2;

      canvas.drawImageRect(
        _pauseMenuImage!,
        Rect.fromLTWH(
          0,
          0,
          _pauseMenuImage!.width.toDouble(),
          _pauseMenuImage!.height.toDouble(),
        ),
        Rect.fromLTWH(px, py, pw, ph),
        Paint(),
      );

      // PAUSE başlık yazısı — görselin üst kısmında
      final pauseText = L10n.t('pause');
      const pauseRefLen = 5; // English "PAUSE"
      final effectivePauseLen = math.max(pauseText.length, pauseRefLen);
      final pauseExtraChars = (effectivePauseLen - pauseRefLen).clamp(0, 20);

      // Per-language visual adjustments
      final lang = L10n.lang;
      double langScale = 1.0;
      double wMul =
          1.0; // width multiplier (controls font size via width constraint)
      double dxMul = 0.00; // additional x offset as fraction of pw
      double dyMul = 0.00; // additional y offset as fraction of ph
      if (lang == 'tr') {
        langScale = 1.464;
        wMul =
            1.10; // +10% width so the while-loop shrink stops earlier → bigger font
        dxMul = -0.015; // shift left to keep text centered with wider area
        dyMul = -0.01;
      } else if (lang == 'th') {
        langScale = 2.0; // 2x for Thai
        dxMul = 0.02;
        dyMul = -0.04; // move Thai further up by additional 0.03
      }

      // Keep the title area base constant; apply language scale to height only.
      final pauseTitleRect = Rect.fromLTWH(
        px + pw * (0.26 + dxMul),
        py + ph * (0.045 + dyMul),
        pw * 0.50 * wMul,
        ph * 0.095 * langScale,
      );
      _drawCurvedOutlineText(
        canvas,
        pauseText,
        pauseTitleRect,
        Colors.white,
        const Color(0xFF6A0FD4),
        bold: true,
      );

      final resumeRect = Rect.fromLTWH(
        px + pw * 0.31,
        py + ph * 0.272,
        pw * 0.55,
        ph * 0.077,
      );
      _drawOutlineText(
        canvas,
        L10n.t('resume'),
        resumeRect,
        Colors.white,
        const Color(0xFF4CAF50),
        bold: true,
      );
      _pauseResumeRect = Rect.fromLTWH(
        px + pw * 0.15,
        py + ph * 0.25,
        pw * 0.70,
        ph * 0.11,
      );

      final restartRect = Rect.fromLTWH(
        px + pw * 0.29,
        py + ph * 0.446,
        pw * 0.572,
        ph * 0.077,
      );
      _drawOutlineText(
        canvas,
        L10n.t('restart'),
        restartRect,
        Colors.white,
        const Color(0xFFFF9800),
        bold: true,
      );
      _pauseRestartRect = Rect.fromLTWH(
        px + pw * 0.15,
        py + ph * 0.45,
        pw * 0.70,
        ph * 0.11,
      );

      final homeRect = Rect.fromLTWH(
        px + pw * 0.31,
        py + ph * 0.620,
        pw * 0.528,
        ph * 0.077,
      );
      _drawOutlineText(
        canvas,
        L10n.t('menu'),
        homeRect,
        Colors.white,
        const Color(0xFF2196F3),
        bold: true,
      );
      _pauseHomeRect = Rect.fromLTWH(
        px + pw * 0.15,
        py + ph * 0.64,
        pw * 0.70,
        ph * 0.11,
      );

      final sfxBtn = Rect.fromLTWH(
        px + pw * 0.22,
        py + ph * 0.790,
        pw * 0.198,
        ph * 0.126,
      );
      _pauseSfxRect = sfxBtn;
      if (!SoundManager.enabled) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(sfxBtn, const Radius.circular(12)),
          Paint()..color = Colors.black.withValues(alpha: 0.5),
        );
        _drawCross(canvas, sfxBtn);
      }
      if (_pauseSfxFlash > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(sfxBtn, const Radius.circular(12)),
          Paint()..color = Colors.white.withValues(alpha: _pauseSfxFlash * 0.5),
        );
      }

      final musicBtn = Rect.fromLTWH(
        px + pw * 0.565,
        py + ph * 0.795,
        pw * 0.198,
        ph * 0.126,
      );
      _pauseMusicRect = musicBtn;
      if (!_musicEnabled) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(musicBtn, const Radius.circular(12)),
          Paint()..color = Colors.black.withValues(alpha: 0.5),
        );
        _drawCross(canvas, musicBtn);
      }
      if (_pauseMusicFlash > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(musicBtn, const Radius.circular(12)),
          Paint()
            ..color = Colors.white.withValues(alpha: _pauseMusicFlash * 0.5),
        );
      }
    } else if (paused && gameActive) {
      canvas.drawRect(
        Rect.fromLTWH(boardX, boardY, bw, bh),
        Paint()..color = Colors.black.withValues(alpha: 0.85),
      );
      const pw = 196.0, ph = 186.0;
      final pcx = boardX + bw / 2;
      final prx = pcx - pw / 2, pry = boardY + bh / 2 - ph / 2;
      // Panel dış glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(prx - 10, pry - 10, pw + 20, ph + 20),
          const Radius.circular(20),
        ),
        Paint()
          ..color = const Color(0xFFC87FFF).withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
      // Panel
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(prx, pry, pw, ph),
          const Radius.circular(14),
        ),
        Paint()..color = const Color(0xFF0C0820),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(prx, pry, pw, ph),
          const Radius.circular(14),
        ),
        Paint()
          ..color = const Color(0xFFC87FFF).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      // Başlık
      _drawTextCentered(
        canvas,
        '⏸  DURAKLATILDI',
        pcx,
        pry + 30,
        17,
        const Color(0xFFC87FFF),
        bold: true,
      );
      // Ayırıcı
      canvas.drawLine(
        Offset(prx + 14, pry + 52),
        Offset(prx + pw - 14, pry + 52),
        Paint()
          ..color = const Color(0xFFC87FFF).withValues(alpha: 0.28)
          ..strokeWidth = 1,
      );
      // Butonlar
      _drawMenuButton(
        canvas,
        pcx,
        pry + 90,
        162,
        36,
        '[ESC]  DEVAM ET',
        const Color(0xFF5CF5E0),
      );
      _drawMenuButton(
        canvas,
        pcx,
        pry + 140,
        162,
        36,
        '[M]  ANA MENÜ',
        const Color(0xFFFF8800),
      );
    }

    // Game over
    if (!gameActive && _gameOverImage != null) {
      // Yarı saydam karartma
      canvas.drawRect(
        Rect.fromLTWH(0, 0, vw, vh),
        Paint()..color = Colors.black.withValues(alpha: 0.75),
      );

      // Game over görseli — ekran ortasında
      final gw = kCols * kCell * 1.1;
      final gh = gw * (_gameOverImage!.height / _gameOverImage!.width);
      final gx = (vw - gw) / 2;
      final gy = (vh - gh) / 2;

      canvas.drawImageRect(
        _gameOverImage!,
        Rect.fromLTWH(
          0,
          0,
          _gameOverImage!.width.toDouble(),
          _gameOverImage!.height.toDouble(),
        ),
        Rect.fromLTWH(gx, gy, gw, gh),
        Paint(),
      );

      final goT = (_xpCountTimer / 3.5).clamp(0.0, 1.0);
      final goProgress = 1.0 - (1.0 - goT) * (1.0 - goT);
      final scoreStr =
          '${L10n.t('game_over_score')}: ${_formatScore((score * goProgress).round())}';
      final extraChars = (scoreStr.length - 11).clamp(0, 20);
      final baseScoreH = gh * 0.12;
      final scoreFontScale = 1.0 - extraChars * 0.05;
      final scoreH = baseScoreH * scoreFontScale * 0.85;
      final scoreRect = Rect.fromLTWH(
        gx + gw * 0.18,
        gy + gh * 0.45,
        gw * 0.64,
        scoreH,
      );
      _drawFittedText(canvas, scoreStr, scoreRect, Colors.white, bold: true);

      // Sol yıldız altı — best skor
      final bestRect = Rect.fromLTWH(
        gx + gw * 0.20,
        gy + gh * 0.60,
        gw * 0.60,
        gh * 0.12,
      );
      _drawFittedText(
        canvas,
        _formatScore(best),
        bestRect,
        const Color(0xFFFFD700),
        bold: true,
      );

      // Kazanılan XP — sol üst köşe, 45° sola eğimli
      if (_lastXpGained > 0) {
        final xpCx = gx + gw * 0.07;
        final xpCy = gy + gh * 0.22;
        final xpFontSize = gh * 0.060;
        final t = (_xpCountTimer / 3.5).clamp(0.0, 1.0);
        final progress = 1.0 - (1.0 - t) * (1.0 - t); // ease-out quad
        final xpShown = (_lastXpGained * progress).round();
        final xpText = '+${_formatScore(xpShown)} XP';

        canvas.save();
        canvas.translate(xpCx, xpCy);
        canvas.rotate(-50 * pi / 180);

        // Layout için önce ölç
        final xpTp = TextPainter(
          text: TextSpan(
            text: xpText,
            style: TextStyle(
              fontSize: xpFontSize,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFD700),
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();

        final padH = xpFontSize * 0.30;
        final padV = xpFontSize * 0.18;
        final bgW = xpTp.width + padH * 2;
        final bgH = xpTp.height + padV * 2;
        final bgRect = Rect.fromCenter(center: Offset.zero, width: bgW, height: bgH);
        final rr = RRect.fromRectAndRadius(bgRect, Radius.circular(bgH * 0.4));

        // Dış glow
        canvas.drawRRect(
          rr,
          Paint()
            ..color = const Color(0xFFFFD700).withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );

        // Koyu arka plan
        canvas.drawRRect(
          rr,
          Paint()..color = const Color(0xFF1A1000).withValues(alpha: 0.82),
        );

        // Altın kenarlık
        canvas.drawRRect(
          rr,
          Paint()
            ..color = const Color(0xFFFFD700)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );

        // Metin (outline + fill)
        final outlineTp = TextPainter(
          text: TextSpan(
            text: xpText,
            style: TextStyle(
              fontSize: xpFontSize,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = xpFontSize * 0.08
                ..color = Colors.black.withValues(alpha: 0.8),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        outlineTp.paint(canvas, Offset(-xpTp.width / 2, -xpTp.height / 2));
        xpTp.paint(canvas, Offset(-xpTp.width / 2, -xpTp.height / 2));

        canvas.restore();
      }

      // Sol turuncu buton — restart
      final restartText = L10n.t('restart');
      final restartH = restartText.length > 9
          ? gh * 0.0525
          : restartText.length > 7
          ? gh * 0.0595
          : gh * 0.07;
      final restartRect = Rect.fromLTWH(
        gx + gw * 0.18,
        gy + gh * 0.82 + (gh * 0.07 - restartH) / 2 + gh * 0.01,
        gw * 0.28,
        restartH,
      );
      _drawFittedText(
        canvas,
        restartText,
        restartRect,
        Colors.white,
        bold: true,
      );

      // Sağ mavi buton — menu
      final menuText = L10n.t('menu');
      final menuH = menuText.length > 9
          ? gh * 0.0525
          : menuText.length > 7
          ? gh * 0.0595
          : gh * 0.07;
      final menuRect = Rect.fromLTWH(
        gx + gw * 0.60,
        gy + gh * 0.82 + (gh * 0.07 - menuH) / 2 + gh * 0.01,
        gw * 0.28,
        menuH,
      );
      _drawFittedText(canvas, menuText, menuRect, Colors.white, bold: true);

      // Tıklanabilir alanlar
      _gameOverRestartRect = restartRect;
      _gameOverMenuRect = menuRect;

    }
  }
}

// Pop cell animasyonu için yardımcı class
class PopCell {
  int c, r;
  double t;
  PopCell({required this.c, required this.r}) : t = 0;
}

class _PendingSeasonDrop {
  final int row, col, type;
  double timer;
  _PendingSeasonDrop({required this.row, required this.col, required this.type})
    : timer = 0.60;
}

class VoltageZap {
  final double cx, cy;
  final double tx, ty;
  double timer = 0.0;
  final double duration = 0.3;
  VoltageZap({
    required this.cx,
    required this.cy,
    required this.tx,
    required this.ty,
  });
}
