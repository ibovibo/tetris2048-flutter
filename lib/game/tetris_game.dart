import 'dart:math';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flame/flame.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'board.dart';
import 'piece.dart';
import 'constants.dart';
import 'special_resolver.dart';
import 'sound_manager.dart';
import 'particle_system.dart';
import 'max_explosion.dart';

class TetrisGame extends FlameGame with KeyboardEvents, DoubleTapDetector, PanDetector, TapDetector {
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
  int level = 1;
  int combo = 1;
  int streak = 0;
  double streakTimer = 0;
  int moveCount = 0;
  int totalMoves = 0;
  double speed = 540;
  double dropTimer = 0;
  bool gameActive = false;
  @override
  bool paused = false;
  Set<int> seenMilestones = {};

  Map<String, int> frozenSet = {};
  Map<int, int> frozenCols = {};

  double pieceVisualY = 0;
  double dangerPulse = 0;
  double comboHeat = 0;
  double animTime = 0;
  double screenShake = 0;
  int maxTile = 0;

  // Mevsim sistemi
  String? activeSeason; // 'bomb', 'speed', 'ice', 'multiplier', 'shuffle'
  int seasonTurnsLeft = 0;
  double _seasonBombTimer = 0; // bomba mevsimi için
  int _pendingSeasonIdx = 0;
  bool _mysteryActive = false;

  double boardX = 0;
  double boardY = 0;
  MaxExplosion? _maxExplosion;
  final Map<int, ui.Picture> _glowCache = {};
  final Map<String, ui.Image> _blockImages = {};
  ui.Image? _bgImage;
  ui.Image? _scoreBoxImage;
  ui.Image? _bestScoreBoxImage;

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
    try { _bgImage = await Flame.images.load('oyunekran_bos.png'); } catch (e) {}
    try { _scoreBoxImage = await Flame.images.load('score_bos.png'); } catch (e) {}
    try { _bestScoreBoxImage = await Flame.images.load('bestscore_bos.png'); } catch (e) {}

    final blockMap = {
      '2': 'blokk_2', '4': 'blokk_4', '8': 'blokk_8',
      '16': 'blokk_16', '32': 'blokk_32', '64': 'blokk_64',
      '128': 'blokk_128', '256': 'blokk_256', '512': 'blokk_512',
      '1024': 'blokk_1024', '2048': 'blokk_2048', '4096': 'blokk_4096',
      '8192': 'blokk_8192', '16384': 'blokk_16384',
      'joker': 'blokk_joker', 'bomb': 'blokk_bomba', 'ice': 'blokk_buz',
      'star': 'blokk_yokeden', 'x2': 'blokk_2x', 'x4': 'blokk_4x',
      'x8': 'blokk_8x', 'x16': 'blokk_16x', 'megabomb': 'blokk_megabomba',
    };
    for (final entry in blockMap.entries) {
      try {
        _blockImages[entry.key] = await Flame.images.load('blocks/${entry.value}.png');
      } catch (_) {}
    }

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
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    return recorder.endRecording();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Görsel 1080x1920, ekranda scale edilmiş
    // Izgara görselde yaklaşık x:175, y:245 piksel konumunda (1080x1920 koordinat)
    final scaleX = size.x / 1080;
    final scaleY = size.y / 1920;
    boardX = 175 * scaleX;
    boardY = 245 * scaleY;
    // kCell sabit kalır, yalnızca boardX/boardY ayarlanır
  }

  void _initGame() {
    board.reset();
    SoundManager.stopSeasonMusic();
    score = 0; displayScore = 0;
    level = 1; combo = 1;
    streak = 0; streakTimer = 0;
    moveCount = 0; totalMoves = 0;
    speed = 540; dropTimer = 0;
    frozenSet = {}; frozenCols = {};
    comboHeat = 0; pieceVisualY = 0; screenShake = 0;
    seenMilestones = {}; maxTile = 0;
    activeSeason = null; seasonTurnsLeft = 0; _seasonBombTimer = 0;
    _mysteryActive = false;
    _glowCache.clear();
    particles.seasonBg.setSeason(null);
    multiplierLines.clear();
    popCells.clear();
    _pendingDrops.clear();

    currentPiece = PieceGenerator.generate(score, moveCount, season: activeSeason);
    nextPiece = PieceGenerator.generate(score, moveCount, season: activeSeason);
    nextQueue.clear();
    nextQueue.add(PieceGenerator.generate(score, moveCount, season: activeSeason));
    nextQueue.add(PieceGenerator.generate(score, moveCount, season: activeSeason));
    pieceVisualY = currentPiece.y.toDouble();
    SoundManager.playGameMusic();
    gameActive = true;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft)  _moveLeft();
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) _moveRight();
      if (event.logicalKey == LogicalKeyboardKey.arrowDown)  _moveDown();
      if (event.logicalKey == LogicalKeyboardKey.arrowUp)    _rotate();
      if (event.logicalKey == LogicalKeyboardKey.space)      _hardDrop();
      if (event.logicalKey == LogicalKeyboardKey.keyR && !gameActive) _initGame();
      if (event.logicalKey == LogicalKeyboardKey.escape)     _togglePause();
      if (event.logicalKey == LogicalKeyboardKey.keyM)       goToMenu();
      if (kDebugMode && event.logicalKey == LogicalKeyboardKey.keyP) _debugInject32768();
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
    if (!gameActive || paused) return;
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
    if (!gameActive || paused) return;
    if (_maxExplosion != null) return;
    _rotate();
  }

  @override
  void onTapDown(TapDownInfo info) {
    final tap = info.eventPosition.global;
    final bw = kCols * kCell;
    final bh = kRows * kCell;

    if (paused && gameActive) {
      const ph = 186.0;
      final pcx = boardX + bw / 2;
      final pry = boardY + bh / 2 - ph / 2;
      if (_isInsideButton(tap, pcx, pry + 90, 162, 36)) {
        _togglePause();
        return;
      }
      if (_isInsideButton(tap, pcx, pry + 140, 162, 36)) {
        goToMenu();
      }
      return;
    }

    if (!gameActive) {
      const ph = 248.0;
      final gcx = size.x / 2;
      final gry = size.y / 2 - ph / 2 - 8;
      if (_isInsideButton(tap, gcx, gry + 208, 178, 36)) {
        _initGame();
      }
    }
  }

  bool _isInsideButton(Vector2 tap, double cx, double cy, double w, double h) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    return rect.contains(Offset(tap.x, tap.y));
  }

  void _debugInject32768() {
    if (!gameActive) return;
    final r = (kRows / 2).floor();
    final c = (kCols / 2).floor();
    board.set(r, c, 32768);
    debugPrint('DEBUG: 32768 tile injected at ($r,$c)');
    _checkMilestone(32768);
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
        if (x < 0 || x >= kCols || y >= kRows) return false;
        if (y >= 0 && board.cells[y][x] != 0) return false;
      }
    }
    return true;
  }

  void _moveLeft()  { if (!gameActive || paused) return; if (_valid(currentPiece.shape, currentPiece.x-1, currentPiece.y)) currentPiece.x--; }
  void _moveRight() { if (!gameActive || paused) return; if (_valid(currentPiece.shape, currentPiece.x+1, currentPiece.y)) currentPiece.x++; }
  void _moveDown()  { if (!gameActive || paused) return; if (_valid(currentPiece.shape, currentPiece.x, currentPiece.y+1)) {
    currentPiece.y++;
  } else {
    _lockPiece();
  } }

  void _rotate() {
    if (!gameActive || paused) return;
    final rot = currentPiece.rotated();
    // SRS-benzeri wall kick: merkez → sol → sağ → 2 sol → 2 sağ → zemin kick
    const kicks = [
      [0, 0], [-1, 0], [1, 0], [-2, 0], [2, 0],
      [0, -1], [-1, -1], [1, -1],
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
    while (_valid(currentPiece.shape, currentPiece.x, currentPiece.y+1)) {
      currentPiece.y++;
    }
    _lockPiece();
  }

  void _lockPiece() {
    for (int r = 0; r < currentPiece.shape.length; r++) {
      for (int c = 0; c < currentPiece.shape[r].length; c++) {
        if (currentPiece.shape[r][c] != 0) {
          final br = currentPiece.y + r, bc = currentPiece.x + c;
          if (br < 0) { _endGame(); return; }
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
            (currentPiece.x + c) * kCell + kCell/2,
            (currentPiece.y + r) * kCell + kCell/2,
            tileColor(currentPiece.shape[r][c]),
          );
        }
      }
    }

    moveCount++; totalMoves++;

    // Mevsim turu azalt
    if (seasonTurnsLeft > 0) {
      seasonTurnsLeft--;
      if (seasonTurnsLeft == 0) {
        unawaited(_endSeason());
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
    frozenCols.forEach((k, v) { frozenCols[k] = v-1; if (frozenCols[k]! <= 0) toRemove.add(k); });
    for (final k in toRemove) {
      frozenCols.remove(k);
    }

    SpecialResolver(
      board: board, frozenSet: frozenSet, frozenCols: frozenCols,
      addScore: (s) => _addScore(s),
      spawnParticle: (cx, cy, val) { particles.spawnExplosion(cx, cy); screenShake = 0.35; },
      showFloat: (msg) => particles.addFloat(kCols*kCell/2, kRows*kCell/3, msg, Colors.yellow, fontSize: 22),
      playBombSfx: () => SoundManager.bomb(),
      playMegaBombSfx: () => SoundManager.megaBomb(),
      playIceJokerSfx: () => SoundManager.iceJoker(),
      playStarSfx: () => SoundManager.starJoker(),
    ).resolveAll();

    // 32768 özel parçalardan (Joker/X2 vb.) oluştuysa da patlamayı tetikle.
    _checkBoardForMaxTileExplosion();

    final events = board.resolveMerges(frozenSet, frozenCols, multiplierLines);
    if (events.isNotEmpty) {
      for (final e in events) {
        final finalScore = e.baseScore * combo;
        _addScore(finalScore);
        SoundManager.merge(e.val);

        // MAX TILE — 32768 oluşunca patlat
        if (e.val == 32768) {
          debugPrint('=== 32768 PATLAMA ===');
          if (_maxExplosion == null) {
            _triggerMaxExplosion();
          }
        }

        _checkMilestone(e.val);

        final color = tileColor(e.val);
        particles.spawnMerge(e.cx, e.cy, color, e.val);

        // Pop cell animasyonu
        final bc = (e.cx / kCell).floor();
        final br = (e.cy / kCell).floor();
        popCells.add(PopCell(c: bc, r: br));

        // Score popup — birleşme noktasında rastgele offset
        final ox = (_rng.nextDouble() - 0.5) * kCell * 2.5;
        final oy = -15.0 - _rng.nextDouble() * 20;
        final fs = e.val >= 2048 ? 30.0 : e.val >= 512 ? 26.0 : e.val >= 128 ? 22.0 : e.val >= 32 ? 17.0 : 13.0;
        String label = '+$finalScore';
        if (combo > 1) label += ' x$combo';
        final popColor = combo > 5 ? const Color(0xFFFF3366)
            : combo > 2 ? const Color(0xFFFF8040) : color;
        particles.addScoreFloat(e.cx + ox, e.cy + oy, label, popColor, fs);

        if (e.mult > 1) {
          final mc = e.mult >= 16 ? const Color(0xFFC87FFF)
              : e.mult >= 8 ? const Color(0xFFFF3CB4)
              : e.mult >= 4 ? const Color(0xFFFF8C00) : const Color(0xFFFFD700);
          particles.addScoreFloat(e.cx, e.cy - 35, '${e.mult}X!', mc, 26);
        }
        if (e.bigBonus > 0) {
          particles.addScoreFloat(e.cx, e.cy - 55, 'MEGA +${e.bigBonus}!', const Color(0xFFFF2080), 22);
        }

        _incrementCombo();
      }
    } else {
      _resetCombo();
    }

    currentPiece = nextPiece;
    if (activeSeason == 'ice') currentPiece.frozen = true;
    nextPiece = nextQueue.removeAt(0);
    nextQueue.add(PieceGenerator.generate(score, moveCount, season: activeSeason));
    pieceVisualY = currentPiece.y.toDouble();

    if (!_valid(currentPiece.shape, currentPiece.x, currentPiece.y)) {
      _endGame(); return;
    }
    _updateLevel();
  }

  void _checkBoardForMaxTileExplosion() {
    if (_maxExplosion != null) return;
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        final v = board.get(r, c);
        if (v >= 32768) {
          _checkMilestone(v);
          return;
        }
      }
    }
  }

  void _pickNewMultiplier() {
    return; // multiplier lines devre dışı
    final progress = (score / 5000).clamp(0.0, 1.0);
    if (multiplierLines.length >= 2) multiplierLines.removeAt(0);
    final mults = [2, 2, 4, 4, 8, 16];
    final weights = [10.0, 10.0, progress*8+1, progress*8+1, progress*4, progress*2];
    final totalW = weights.fold(0.0, (a, b) => a + b);
    double r = _rng.nextDouble() * totalW;
    int mult = 2;
    for (int i = 0; i < mults.length; i++) { r -= weights[i]; if (r <= 0) { mult = mults[i]; break; } }
    final isRow = _rng.nextBool();
    final index = isRow ? kRows - 2 - _rng.nextInt(5) : _rng.nextInt(kCols);
    multiplierLines.add(MultiplierLine(isRow: isRow, index: index, mult: mult));
  }

  void _addScore(int add) {
    score += add;
    if (score > best) { best = score; _saveBest(); }
  }

  void _incrementCombo() {
    combo++;
    if (combo > bestCombo) { bestCombo = combo; _saveBest(); }
    comboHeat = (comboHeat + 0.12).clamp(0, 1);

    if (combo >= 3) {
      SoundManager.combo(combo);
      final comboColor = combo >= 12 ? const Color(0xFFFF3366)
          : combo >= 7 ? const Color(0xFFFF6600)
          : combo >= 4 ? const Color(0xFFFFCC00) : const Color(0xFF88FF44);
      particles.addComboWave(comboColor, combo);
      if (combo >= 5)  screenShake = 0.18;
      if (combo >= 8)  screenShake = 0.35;
      if (combo >= 12) { screenShake = 0.55; particles.spawnConfetti(kCols*kCell/2, kRows*kCell/3); }
    }
    streak++; streakTimer = 3.0;
    _checkStreakReward();
  }

  void _resetCombo() { combo = 1; comboHeat = 0; }

  void _checkStreakReward() {
    if (streak == 5) {
      _addScore(500);
      particles.spawnConfetti(kCols*kCell/2, kRows*kCell/2);
    } else if (streak == 10) {
      _addScore(2000);
      particles.spawnConfetti(kCols*kCell/2, kRows*kCell/2); screenShake = 0.35;
    } else if (streak == 20) {
      _addScore(10000);
      particles.spawnConfetti(kCols*kCell/2, kRows*kCell/2); screenShake = 0.65;
    }
  }

  void _checkMilestone(int val) {
    const milestones = [8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768];
    const msgs = {8:'İlk 8!',16:'16 Yaptın!',32:'32!',64:'64! Harika!',
      128:'128! Müthiş!',256:'256! Süper!',512:'512! Efsane!',
      1024:'1024! İnanılmaz!',2048:'2048! KAZANDIN!',
      4096:'4096! EFSANE!',8192:'8192! TANRISAL!',
      16384:'16384! MÜMKÜN MÜ?!',32768:'32768! OYUNUN TANRISI!'};

    if (milestones.contains(val) && !seenMilestones.contains(val)) {
      seenMilestones.add(val);
    }

    if (val >= 32768) {
      if (_maxExplosion == null) {
        _triggerMaxExplosion();
      }
    }

  }

  void _triggerMaxExplosion() {
    SoundManager.maxExplosion32k();
    SoundManager.pauseMusic();
    // Mevcut mevsimi hemen bitir
    if (activeSeason != null) unawaited(_endSeason());

    // Boardda 32768+ olan hücreyi bul
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (board.get(r, c) >= 32768) {
          // 4x4 alan temizle
          for (int dr = -1; dr <= 2; dr++) {
            for (int dc = -1; dc <= 2; dc++) {
              final nr = r+dr, nc = c+dc;
              if (nr >= 0 && nr < kRows && nc >= 0 && nc < kCols) {
                board.set(nr, nc, 0);
                particles.spawnExplosion(nc*kCell+kCell/2, nr*kCell+kCell/2);
              }
            }
          }
          board.applyGravity(frozenSet);
          _addScore(100000);
          screenShake = 1.2;

          // Süper patlama animasyonunu başlat
          final seasonIdx = _rng.nextInt(kSeasons.length);
          _pendingSeasonIdx = seasonIdx;
          _maxExplosion = MaxExplosion(selectedSeason: seasonIdx);
          return;
        }
      }
    }

    // Boardda bulunamadıysa bile animasyonu başlat
    final seasonIdx = _rng.nextInt(kSeasons.length);
    _pendingSeasonIdx = seasonIdx;
    _maxExplosion = MaxExplosion(selectedSeason: seasonIdx);
    _addScore(100000);
    screenShake = 1.2;
  }

  Future<void> _startRandomSeason() async {
    debugPrint('=== _startRandomSeason çağrıldı: $_pendingSeasonIdx ===');
    activeSeason = kSeasons[_pendingSeasonIdx].key;
    debugPrint('=== activeSeason: $activeSeason ===');
    debugPrint('_startRandomSeason: activeSeason=$activeSeason, pendingIdx=$_pendingSeasonIdx');
    seasonTurnsLeft = 10;
    _seasonBombTimer = 2.0;

    if (activeSeason == 'speed') {
      speed = (speed / 2).clamp(50, 270);
    }

    // Mevsim sesini başlat
    await SoundManager.playSeasonMusic(activeSeason!);
    debugPrint('=== playSeasonMusic çağrıldı ===');

    particles.seasonBg.setSeason(activeSeason);

    if (activeSeason == 'mystery') {
      // Tum board'daki bloklari gizle
      _mysteryActive = true;
    }

    // Kuyruktaki eski parçaları yeni mevsime göre yenile
    nextPiece = PieceGenerator.generate(score, moveCount, season: activeSeason);
    nextQueue.clear();
    nextQueue.add(PieceGenerator.generate(score, moveCount, season: activeSeason));
    nextQueue.add(PieceGenerator.generate(score, moveCount, season: activeSeason));


  }

  Future<void> _endSeason() async {
    final season = activeSeason;
    if (activeSeason == 'speed') {
      // Hızı level'a göre yeniden hesapla
      final baseSpeed = 540.0, fastThreshold = 350.0;
      final levelsToFast = ((baseSpeed - fastThreshold) / 50).ceil();
      if (level <= levelsToFast + 1) {
        speed = baseSpeed - (level-1)*50;
      } else {
        speed = fastThreshold - (level-levelsToFast-1)*20;
      }
      speed = speed.clamp(100, 540);
    }

    // BGM'i normale döndür, mevsim müziğini durdur
    SoundManager.clearSeasonMusicFlag();
    await SoundManager.stopSeasonMusic();
    // Eğer 32k animasyonu devam ediyorsa oyun müziğini başlatma
    if (_maxExplosion == null) {
      SoundManager.resumeMusic();
    }

    if (season == 'mystery') _mysteryActive = false;
    particles.seasonBg.setSeason(null);
    activeSeason = null;
  }

  void _dropSeasonBomb() {
    final col = _randomEmptyCol();
    if (col < 0) return;
    final row = _bottomEmptyRow(col);
    if (row < 0) return;
    _pendingDrops.add(_PendingSeasonDrop(row: row, col: col, type: kBomb));
    // Görsel — belirecek yer
    particles.spawnMerge(col * kCell + kCell/2, row * kCell + kCell/2,
      const Color(0xFFFF4400), 2);
  }

  void _dropSeasonMultiplier() {
    final col = _randomEmptyCol();
    if (col < 0) return;
    final row = _bottomEmptyRow(col);
    if (row < 0) return;
    final types = [kX2, kX4, kX8];
    final t = types[_rng.nextInt(types.length)];
    _pendingDrops.add(_PendingSeasonDrop(row: row, col: col, type: t));
    particles.spawnMerge(col*kCell+kCell/2, row*kCell+kCell/2,
      const Color(0xFFC87FFF), 2);
  }

  void _dropSeasonShuffle() {
    final col = _randomEmptyCol();
    if (col < 0) return;
    final row = _bottomEmptyRow(col);
    if (row < 0) return;
    final t = _rng.nextBool() ? kShuffleRow : kShuffleCol;
    _pendingDrops.add(_PendingSeasonDrop(row: row, col: col, type: t));
    particles.spawnMerge(col*kCell+kCell/2, row*kCell+kCell/2,
      const Color(0xFFFF88FF), 2);
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
    for (int r = kRows-1; r >= 0; r--) {
      if (board.cells[r][col] == 0) return r;
    }
    return -1;
  }

  void _updateLevel() {
    int newLevel = 1;
    for (int i = kLevelScores.length-1; i >= 0; i--) {
      if (score >= kLevelScores[i]) { newLevel = i+1; break; }
    }
    if (newLevel != level) {
      level = newLevel;
      final baseSpeed = 540.0, fastThreshold = 350.0;
      final levelsToFast = ((baseSpeed - fastThreshold) / 50).ceil();
      if (level <= levelsToFast+1) {
        speed = baseSpeed - (level-1)*50;
      } else {
        speed = fastThreshold - (level-levelsToFast-1)*20;
      }
      speed = speed.clamp(100, 540);
      SoundManager.level();
      particles.spawnConfetti(kCols*kCell/2, 0);
      screenShake = 0.3;
    }
  }

  Future<void> _endGame() async {
    gameActive = false;
    SoundManager.stopSeasonMusic();
    SoundManager.stopMusic();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    SoundManager.gameOver();
    if (score > best) { best = score; _saveBest(); }
  }

  @override
  void update(double dt) {
    super.update(dt);
    animTime += dt;
    dangerPulse = (dangerPulse + dt*3) % (2*pi);
    comboHeat = (comboHeat - dt*0.006).clamp(0, 1);
    screenShake = (screenShake - dt*2.5).clamp(0, 1);
    particles.update(dt);
    particles.seasonBg.update(dt, boardX, boardY, kCols*kCell, kRows*kCell);

    // Bomba mevsimi — her 2-3 saniyede rastgele bomba
    if (activeSeason == 'bomb' && gameActive && !paused) {
      _seasonBombTimer -= dt;
      if (_seasonBombTimer <= 0) {
        _seasonBombTimer = 1.5 + _rng.nextDouble() * 1.5;
        _dropSeasonBomb();
      }
    }

    // Çarpan mevsimi — rastgele multiplier bloğu düşür
    if (activeSeason == 'multiplier' && gameActive && !paused) {
      _seasonBombTimer -= dt;
      if (_seasonBombTimer <= 0) {
        _seasonBombTimer = 1.8 + _rng.nextDouble() * 1.5;
        _dropSeasonMultiplier();
      }
    }

    // Değiş tokuş mevsimi
    if (activeSeason == 'shuffle' && gameActive && !paused) {
      _seasonBombTimer -= dt;
      if (_seasonBombTimer <= 0) {
        _seasonBombTimer = 1.5 + _rng.nextDouble() * 1.5;
        _dropSeasonShuffle();
      }
    }

    // Bekleyen mevsim blokları — animasyonla belir, sonra işle
    for (final d in _pendingDrops.toList()) {
      d.timer -= dt;
      if (d.timer <= 0) {
        _pendingDrops.remove(d);
        board.set(d.row, d.col, d.type);
        SpecialResolver(
          board: board, frozenSet: frozenSet, frozenCols: frozenCols,
          addScore: (s) => _addScore(s),
          spawnParticle: (cx, cy, val) { particles.spawnExplosion(cx, cy); screenShake = 0.2; },
          showFloat: (msg) => particles.addFloat(kCols*kCell/2, kRows*kCell/3, msg, Colors.yellow, fontSize: 22),
          playBombSfx: () => SoundManager.bomb(),
          playMegaBombSfx: () => SoundManager.megaBomb(),
          playIceJokerSfx: () => SoundManager.iceJoker(),
          playStarSfx: () => SoundManager.starJoker(),
        ).resolveAll();
        board.applyGravity(frozenSet);
        final events = board.resolveMerges(frozenSet, frozenCols, multiplierLines);
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

    _maxExplosion?.update(dt);
    if (_maxExplosion?.done == true) {
      _maxExplosion = null;
      unawaited(_startRandomSeason());
    }

    // Pop cells güncelle
    popCells.removeWhere((p) => p.t >= 1.0);
    for (final p in popCells) {
      p.t = (p.t + dt*4.5).clamp(0, 1.0);
    }

    if (streakTimer > 0) { streakTimer -= dt; if (streakTimer <= 0) streak = 0; }

    // Skor animasyonu
    if (displayScore < score) {
      final diff = score - displayScore;
      displayScore += (diff * 0.15).clamp(1, 99999);
      if (displayScore > score) displayScore = score.toDouble();
    }

    if (!gameActive || paused || _maxExplosion != null) return;

    final targetY = currentPiece.y.toDouble();
    if (pieceVisualY < targetY) {
      pieceVisualY = (pieceVisualY + dt*kRows/(speed/1000)).clamp(0, targetY);
    } else { pieceVisualY = targetY; }

    dropTimer += dt * 1000;
    if (dropTimer >= speed) {
      dropTimer = 0;
      if (_valid(currentPiece.shape, currentPiece.x, currentPiece.y+1)) {
        currentPiece.y++;
      } else {
        _lockPiece();
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

    _drawMultiplierLines(canvas);
    _drawBoard(canvas);
    _drawGhost(canvas);
    _drawPiece(canvas);
    particles.render(canvas, boardX, boardY, screenW: size.x, screenH: size.y);
    _drawUI(canvas);
    _drawOverlays(canvas);
    _maxExplosion?.render(canvas, size.x, size.y);

    canvas.restore();
  }

  void _drawBackground(Canvas canvas) {
    final s = size;
    if (_bgImage != null) {
      canvas.drawImageRect(
        _bgImage!,
        Rect.fromLTWH(0, 0, _bgImage!.width.toDouble(), _bgImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, s.x, s.y),
        Paint(),
      );
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, s.x, s.y), Paint()..color = const Color(0xFF04020E));
    }
  }

  void _drawMultiplierLines(Canvas canvas) {
    return; // multiplier lines devre dışı
    for (final ml in multiplierLines) {
      final pulse = 0.5 + sin(animTime * 4 + ml.index * 0.7) * 0.5;
      final scanPos = (animTime * 0.9 + ml.index * 0.4) % 1.0;
      Color lc;
      switch (ml.mult) {
        case 16: lc = const Color(0xFFC87FFF); break;
        case 8:  lc = const Color(0xFFFF3CB4); break;
        case 4:  lc = const Color(0xFFFF8C00); break;
        default: lc = const Color(0xFFFFD700); break;
      }
      final rect = ml.isRow
          ? Rect.fromLTWH(boardX, boardY+ml.index*kCell, kCols*kCell, kCell)
          : Rect.fromLTWH(boardX+ml.index*kCell, boardY, kCell, kRows*kCell);

      // Ana dolgu
      canvas.drawRect(rect, Paint()..color = lc.withValues(alpha: 0.13 * pulse));

      // Dış glow kenarlık
      canvas.drawRect(rect, Paint()
        ..color = lc.withValues(alpha: 0.45 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));

      // Keskin iç kenarlık
      canvas.drawRect(rect, Paint()
        ..color = lc.withValues(alpha: 0.90 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);

      // Tarama ışığı efekti
      if (ml.isRow) {
        final scanX = boardX + scanPos * kCols * kCell;
        canvas.drawRect(
          Rect.fromLTWH(scanX - kCell * 0.5, boardY + ml.index * kCell, kCell, kCell),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.28 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
      } else {
        final scanY = boardY + scanPos * kRows * kCell;
        canvas.drawRect(
          Rect.fromLTWH(boardX + ml.index * kCell, scanY - kCell * 0.5, kCell, kCell),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.28 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
      }

      // Çarpan etiketi — glow'lu, belirgin
      final tp = TextPainter(
        text: TextSpan(text: '×${ml.mult}', style: TextStyle(
          fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold,
          color: lc.withValues(alpha: 0.98),
          shadows: [
            Shadow(color: lc, blurRadius: 14),
            Shadow(color: lc, blurRadius: 28),
            Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      final tx = ml.isRow ? boardX + kCols*kCell - tp.width - 6 : boardX + ml.index*kCell + (kCell - tp.width)/2;
      final ty = ml.isRow ? boardY + ml.index*kCell + (kCell - tp.height)/2 : boardY + 6;
      tp.paint(canvas, Offset(tx, ty));
    }
  }

  void _drawBoard(Canvas canvas) {
    // Board arkaplanı — şeffaf cam efekti
    canvas.drawRect(
      Rect.fromLTWH(boardX, boardY, kCols * kCell, kRows * kCell),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );

    final gridPaint = Paint()..color = Colors.white.withValues(alpha:0.05)..style=PaintingStyle.stroke..strokeWidth=0.7;
    for (int c = 1; c < kCols; c++) {
      canvas.drawLine(Offset(boardX+c*kCell,boardY), Offset(boardX+c*kCell,boardY+kRows*kCell), gridPaint);
    }
    for (int r = 1; r < kRows; r++) {
      canvas.drawLine(Offset(boardX,boardY+r*kCell), Offset(boardX+kCols*kCell,boardY+r*kCell), gridPaint);
    }

    // Hücreler + frozen overlay + max tile glow + pop cells
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        final v = board.get(r, c);
        if (v == 0) {
          // Boş hücre hafif dolgu
          canvas.drawRect(Rect.fromLTWH(boardX+c*kCell+1, boardY+r*kCell+1, kCell-2, kCell-2),
            Paint()..color = Colors.white.withValues(alpha:0.018));
          continue;
        }

        // Max tile glow
        if (v == maxTile && maxTile >= 8 && !_mysteryActive) _drawMaxTileGlow(canvas, c, r, v);

        // Pop cell animasyonu
        final pop = popCells.where((p) => p.c == c && p.r == r).firstOrNull;
        if (pop != null) {
          final scale = pop.t < 0.4 ? 1 + pop.t*0.7 : 1 + (1-pop.t)*0.28;
          final cx = boardX + c*kCell + kCell/2;
          final cy = boardY + r*kCell + kCell/2;
          canvas.save();
          canvas.translate(cx, cy);
          canvas.scale(scale, scale);
          canvas.translate(-cx, -cy);
          _drawTile(canvas, boardX+c*kCell, boardY+r*kCell, v, 1.0-(pop.t*0.25));
          canvas.restore();
        } else {
          _drawTile(canvas, boardX+c*kCell, boardY+r*kCell, v, 1.0);
        }

        // Frozen overlay
        if (frozenSet.containsKey('$r,$c')) _drawFrozenOverlay(canvas, c, r);
      }
    }

    // Bekleyen mevsim blokları — yoğun glow + yanıp sönen efekt
    for (final d in _pendingDrops) {
      final progress = 1.0 - (d.timer / 0.60); // 0→1 arası ilerleme
      final pulse = sin(animTime * 25) * 0.5 + 0.5;
      final alpha = (0.5 + pulse * 0.5).clamp(0.0, 1.0);
      final cx = boardX + d.col*kCell + kCell/2;
      final cy = boardY + d.row*kCell + kCell/2;
      final color = d.type == kBomb ? const Color(0xFFFF4400)
          : d.type == kShuffleRow || d.type == kShuffleCol ? const Color(0xFFFF88FF)
          : const Color(0xFFC87FFF);

      // Büyük dış glow halkası
      final glowR = kCell * (0.8 + progress * 0.6);
      canvas.drawCircle(Offset(cx, cy), glowR,
        Paint()..color = color.withValues(alpha: alpha * 0.35));

      // İkinci halka — dışa doğru genişliyor
      canvas.drawCircle(Offset(cx, cy), kCell * (0.5 + progress),
        Paint()..color = color.withValues(alpha: (1.0 - progress) * 0.5)
               ..style = PaintingStyle.stroke..strokeWidth = 3);

      // Üçüncü halka
      canvas.drawCircle(Offset(cx, cy), kCell * 0.4,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.3)
               ..style = PaintingStyle.stroke..strokeWidth = 1.5);

      // Tile çizimi — scale efekti ile büyüyerek beliriyor
      final scale = 0.4 + progress * 0.6;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(scale, scale);
      canvas.translate(-cx, -cy);
      _drawTile(canvas, boardX + d.col*kCell, boardY + d.row*kCell, d.type, alpha);
      canvas.restore();
    }

    // Gizem mevsimi - board uzerine statik gurultu
    if (_mysteryActive) {
      final rng2 = math.Random((animTime * 6).toInt());
      for (int i = 0; i < 120; i++) {
        final nx = boardX + rng2.nextDouble() * kCols * kCell;
        final ny = boardY + rng2.nextDouble() * kRows * kCell;
        canvas.drawRect(Rect.fromLTWH(nx, ny, 1.5 + rng2.nextDouble()*3, 1.5),
          Paint()..color = Colors.white.withValues(alpha: rng2.nextDouble() * 0.12));
      }
      // Yatay bozulma cizgileri
      final lineCount = rng2.nextInt(3);
      for (int i = 0; i < lineCount; i++) {
        final ly = boardY + rng2.nextDouble() * kRows * kCell;
        canvas.drawRect(Rect.fromLTWH(boardX, ly, kCols*kCell, 2),
          Paint()..color = Colors.white.withValues(alpha: 0.08 + rng2.nextDouble()*0.12));
      }
    }

    // Board kenarlık — ince beyaz
    canvas.drawRect(Rect.fromLTWH(boardX, boardY, kCols*kCell, kRows*kCell),
      Paint()..color = Colors.white.withValues(alpha: 0.55)..style=PaintingStyle.stroke..strokeWidth=1.5);
  }

  // Max tile etrafında dönen parçacıklar + halo
  void _drawMaxTileGlow(Canvas canvas, int c, int r, int val) {
    if (_mysteryActive) return; // gizem mevsiminde max tile glow yok
    final cx = boardX + c*kCell + kCell/2;
    final cy = boardY + r*kCell + kCell/2;
    final color = tileColor(val);
    final tier = (log(val.toDouble()) / log(2)).round();
    final t = animTime;

    // Halo
    final haloR = kCell*0.62 + (tier-3)*3 + sin(t*2)*4;
    canvas.drawCircle(Offset(cx, cy), haloR,
          Paint()..color = color.withValues(alpha:0.30));

    // Parlak kenarlık nabzı
    canvas.drawRect(Rect.fromLTWH(boardX+c*kCell+1, boardY+r*kCell+1, kCell-2, kCell-2),
      Paint()..color = color.withValues(alpha:0.65+sin(t*3)*0.35)
            ..style=PaintingStyle.stroke..strokeWidth=2.5);

    // Dönen parçacıklar (tier >= 5)
    if (tier >= 5) {
      final count = (4 + (tier-5)*2).clamp(0, 12);
      final dist = kCell*0.58 + (tier-5)*3;
      for (int i = 0; i < count; i++) {
        final angle = (2*pi/count)*i + t;
        final pulse = 0.55 + sin(t*4+i*1.3)*0.45;
        final px = cx + cos(angle)*dist;
        final py = cy + sin(angle)*dist;
        final dotColor = i % 2 == 0 ? Colors.white : color;
        canvas.drawCircle(Offset(px, py), (2+(tier-5)*0.6).clamp(1,5),
          Paint()..color = dotColor.withValues(alpha:pulse));
      }
    }

    // Ateş parçacıkları (tier >= 8)
    if (tier >= 8) {
      final fc = (6+(tier-8)*3).clamp(0, 16);
      for (int i = 0; i < fc; i++) {
        final angle = (2*pi/fc)*i + t*1.85;
        final d = kCell*0.5 + sin(t*2.5+i)*5;
        final fx = cx + cos(angle)*d;
        final fy = cy + sin(angle)*d;
        canvas.drawCircle(Offset(fx, fy), (5+(tier-8)*1.5).clamp(2,12),
          Paint()..color = Colors.orangeAccent.withValues(alpha:0.68+sin(t*3+i)*0.32)
                 ..maskFilter=const MaskFilter.blur(BlurStyle.normal, 4));
      }
    }
  }

  // Frozen overlay — buz kristal efekti
  void _drawFrozenOverlay(Canvas canvas, int c, int r) {
    _drawFrozenOverlayAt(canvas, boardX + c * kCell, boardY + r * kCell);
  }

  void _drawFrozenOverlayAt(Canvas canvas, double x, double y) {
    final t = animTime;
    final pulse = 0.38 + sin(t * 2.0) * 0.10;
    final sparkle = 0.5 + sin(t * 5.8) * 0.5;

    // Ana buz tabakası
    canvas.drawRect(Rect.fromLTWH(x+1, y+1, kCell-2, kCell-2),
      Paint()..color = const Color(0xFF6EC8FF).withValues(alpha: pulse * 0.75));

    // İç açık katman
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+4, y+4, kCell-8, kCell-8), const Radius.circular(3)),
      Paint()..color = const Color(0xFFB8ECFF).withValues(alpha: 0.20));

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
      canvas.drawLine(Offset(tipX, tipY),
        Offset(tipX + cos(angle + math.pi/3.5) * branchLen, tipY + sin(angle + math.pi/3.5) * branchLen),
        branchPaint);
      canvas.drawLine(Offset(tipX, tipY),
        Offset(tipX + cos(angle - math.pi/3.5) * branchLen, tipY + sin(angle - math.pi/3.5) * branchLen),
        branchPaint);
    }

    // Merkez yıldız noktası
    canvas.drawCircle(Offset(cx, cy), 1.8,
      Paint()..color = Colors.white.withValues(alpha: 0.85));

    // Köşe sparkle noktaları
    final corners = [
      Offset(x+5, y+5), Offset(x+kCell-5, y+5),
      Offset(x+5, y+kCell-5), Offset(x+kCell-5, y+kCell-5),
    ];
    for (int i = 0; i < corners.length; i++) {
      final sp = sparkle * (0.55 + sin(t * 3.8 + i * 1.3) * 0.45);
      canvas.drawCircle(corners[i], 2.2,
        Paint()..color = Colors.white.withValues(alpha: sp)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }

    // Sol üst cam yansıması
    canvas.drawRect(Rect.fromLTWH(x+4, y+4, (kCell-6)*0.40, (kCell-6)*0.16),
      Paint()..color = Colors.white.withValues(alpha: 0.40));

    // Dış buz kenarlık glow
    canvas.drawRect(Rect.fromLTWH(x+1, y+1, kCell-2, kCell-2),
      Paint()..color = const Color(0xFF90DDFF).withValues(alpha: 0.85 + sin(t * 2.4) * 0.15)
             ..style = PaintingStyle.stroke..strokeWidth = 2.0
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }

  void _drawTile(Canvas canvas, double x, double y, int val, double alpha, {bool ghost=false}) {
    final color = tileColor(val);
    const pad = 1.5;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x+pad, y+pad, kCell-pad*2, kCell-pad*2), const Radius.circular(8));

    if (ghost) {
      canvas.drawRRect(rect, Paint()..color=color.withValues(alpha:0.12));
      canvas.drawRRect(rect, Paint()..color=color.withValues(alpha:0.3)..style=PaintingStyle.stroke..strokeWidth=1);
      return;
    }

    if (_mysteryActive && val != 0 && !isObstacle(val)) {
      const pad = 1.5;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x+pad, y+pad, kCell-pad*2, kCell-pad*2),
        const Radius.circular(8));

      // Nabzeden gri - canli ama gri
      final pulse = 0.7 + math.sin(animTime * 2.5 + x * 0.1 + y * 0.08) * 0.3;

      // Dis glow - beyazimsi
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x+pad-3, y+pad-3, kCell-pad*2+6, kCell-pad*2+6),
        const Radius.circular(10)),
        Paint()..color = Colors.white.withValues(alpha: 0.15 * pulse * alpha)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

      // Ana dolgu - koyu gri, canli
      canvas.drawRRect(rect,
        Paint()..color = const Color(0xFF2A2A3A).withValues(alpha: 0.92 * alpha));

      // Ust cam serit
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x+pad+2, y+pad+2, kCell-pad*2-4, (kCell-pad*2)*0.42),
        const Radius.circular(6)),
        Paint()..color = Colors.white.withValues(alpha: 0.22 * alpha));

      // Nabzeden kenarlik
      canvas.drawRRect(rect,
        Paint()..color = Colors.white.withValues(alpha: 0.4 * pulse * alpha)
               ..style = PaintingStyle.stroke..strokeWidth = 1.8);

      // Ikinci dis kenarlik - mor tonu
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x+pad-2, y+pad-2, kCell-pad*2+4, kCell-pad*2+4),
        const Radius.circular(9)),
        Paint()..color = const Color(0xFF8888CC).withValues(alpha: 0.25 * pulse * alpha)
               ..style = PaintingStyle.stroke..strokeWidth = 1);

      // Soru isareti - buyuk, parlak
      final tp = TextPainter(
        text: TextSpan(text: '?', style: TextStyle(
          fontFamily: 'monospace', fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: (0.7 + pulse * 0.3) * alpha),
          shadows: [
            Shadow(color: Colors.white.withValues(alpha: 0.6 * pulse), blurRadius: 12),
            Shadow(color: const Color(0xFF8888FF).withValues(alpha: 0.4), blurRadius: 20),
            Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 4, offset: const Offset(0,2)),
          ],
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x+kCell/2-tp.width/2, y+kCell/2-tp.height/2+1));
      return;
    }

    // PNG blok çizimi
    String? imgKey;
    if (val == 2) {
      imgKey = '2';
    } else if (val == 4) imgKey = '4';
    else if (val == 8) imgKey = '8';
    else if (val == 16) imgKey = '16';
    else if (val == 32) imgKey = '32';
    else if (val == 64) imgKey = '64';
    else if (val == 128) imgKey = '128';
    else if (val == 256) imgKey = '256';
    else if (val == 512) imgKey = '512';
    else if (val == 1024) imgKey = '1024';
    else if (val == 2048) imgKey = '2048';
    else if (val == 4096) imgKey = '4096';
    else if (val == 8192) imgKey = '8192';
    else if (val >= 16384) imgKey = '16384';
    else if (val == kJoker) imgKey = 'joker';
    else if (val == kBomb) imgKey = 'bomb';
    else if (val == kIce) imgKey = 'ice';
    else if (val == kStar) imgKey = 'star';
    else if (val == kX2) imgKey = 'x2';
    else if (val == kX4) imgKey = 'x4';
    else if (val == kX8) imgKey = 'x8';
    else if (val == kX16) imgKey = 'x16';
    else if (val == kMegaBomb) imgKey = 'megabomb';

    if (imgKey != null && _blockImages.containsKey(imgKey)) {
      final img = _blockImages[imgKey]!;
      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = Rect.fromLTWH(x+pad, y+pad, kCell-pad*2, kCell-pad*2);
      canvas.drawImageRect(img, src, dst,
        Paint()..filterQuality = FilterQuality.medium
               ..color = Colors.white.withValues(alpha: alpha));
      return;
    }

    final glowPic = _glowCache.putIfAbsent(color.value, () => _buildGlowPicture(color));
    canvas.save();
    canvas.translate(x, y);
    canvas.drawPicture(glowPic);
    canvas.restore();

    // Ana dolgu — hafif koyu alt, parlak üst gradient hissi
    canvas.drawRRect(rect, Paint()..color=color.withValues(alpha:alpha));

    // Üst 1/3 — açık ton (3D tepe ışığı)
    final lightColor = HSVColor.fromColor(color)
      .withValue((HSVColor.fromColor(color).value + 0.25).clamp(0,1))
      .withSaturation((HSVColor.fromColor(color).saturation - 0.15).clamp(0,1))
      .toColor();
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+pad, y+pad, kCell-pad*2, (kCell-pad*2)*0.45),
      const Radius.circular(8)),
      Paint()..color=lightColor.withValues(alpha:0.55*alpha));

    // Alt 1/4 — koyu ton (3D gölge)
    final darkColor = HSVColor.fromColor(color)
      .withValue((HSVColor.fromColor(color).value - 0.25).clamp(0,1))
      .toColor();
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+pad, y+kCell-pad-(kCell-pad*2)*0.28, kCell-pad*2, (kCell-pad*2)*0.28),
      const Radius.circular(8)),
      Paint()..color=darkColor.withValues(alpha:0.6*alpha));

    // Sol üst köşe parlama — spot ışığı hissi
    canvas.drawCircle(
      Offset(x+pad+7, y+pad+7), 9,
      Paint()..color=Colors.white.withValues(alpha:0.35*alpha)
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal,6));

    // İnce parlak üst kenar çizgisi
    canvas.drawLine(
      Offset(x+pad+8, y+pad+1.5),
      Offset(x+kCell-pad-8, y+pad+1.5),
      Paint()..color=Colors.white.withValues(alpha:0.5*alpha)..strokeWidth=1.5);

    // Dış kenarlık — ince, parlak
    canvas.drawRRect(rect,
      Paint()..color=Colors.white.withValues(alpha:0.22*alpha)
             ..style=PaintingStyle.stroke..strokeWidth=1.2);

    // İç kenarlık — rengin açık tonu
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+pad+1.5, y+pad+1.5, kCell-pad*2-3, kCell-pad*2-3),
      const Radius.circular(6)),
      Paint()..color=lightColor.withValues(alpha:0.18*alpha)
             ..style=PaintingStyle.stroke..strokeWidth=0.8);

    // Label
    final label = _getTileLabel(val);
    final fontSize = val < 0 ? (label.length > 2 ? 13.0 : 19.0)
        : (val >= 10000 ? 10.0 : val >= 1000 ? 12.0 : val >= 100 ? 15.0 : 19.0);
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(
        fontFamily: 'monospace', fontSize: fontSize, fontWeight: FontWeight.bold,
        color: Colors.white.withValues(alpha:alpha),
        shadows: [Shadow(color:Colors.black.withValues(alpha:0.9),blurRadius:4,offset:const Offset(0,2)), Shadow(color:color,blurRadius:10)],
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x+kCell/2-tp.width/2, y+kCell/2-tp.height/2+1));
  }

  String _getTileLabel(int val) {
    switch (val) {
      case kJoker:      return '★';
      case kBomb:       return '💣';
      case kMegaBomb:   return '💥';
      case kIce:        return '❄';
      case kX2:         return '×2';
      case kX4:         return '×4';
      case kX8:         return '×8';
      case kX16:        return '×16';
      case kStar:       return '✦';
      case kShuffleRow: return '↔';
      case kShuffleCol: return '↕';
      case kStone:      return '⬛';
      case kLocked:     return '🔒';
      case kDoubleHit:  return '💢';
      case kSpinner:    return '↺';
      case kDark:       return '?';
      default:          return val > 0 ? val.toString() : '';
    }
  }

  void _drawGhost(Canvas canvas) {
    if (_mysteryActive) return; // gizem mevsiminde ghost yok
    if (!gameActive) return;
    int gy = currentPiece.y;
    while (_valid(currentPiece.shape, currentPiece.x, gy+1)) {
      gy++;
    }
    if (gy == currentPiece.y) return;
    for (int r = 0; r < currentPiece.shape.length; r++) {
      for (int c = 0; c < currentPiece.shape[r].length; c++) {
        final v = currentPiece.shape[r][c];
        if (v != 0) _drawTile(canvas, boardX+(currentPiece.x+c)*kCell, boardY+(gy+r)*kCell, v, 0.18, ghost:true);
      }
    }
  }

  void _drawPiece(Canvas canvas) {
    if (!gameActive) return;
    final offsetY = (pieceVisualY - pieceVisualY.floorToDouble()) * kCell;
    for (int r = 0; r < currentPiece.shape.length; r++) {
      for (int c = 0; c < currentPiece.shape[r].length; c++) {
        final v = currentPiece.shape[r][c];
        if (v != 0) {
          final px = boardX + (currentPiece.x + c) * kCell;
          final py = boardY + (pieceVisualY.floorToDouble() + r) * kCell + offsetY;
          _drawTile(canvas, px, py, v, 1.0);

          // Frozen parça — üzerine buz efekti çiz
          if (currentPiece.frozen) {
            _drawFrozenOverlayAt(canvas, px, py);
          }
        }
      }
    }
  }

  void _drawUI(Canvas canvas) {
    final bw = kCols * kCell;
    final rpW = 80.0;
    final rpX = boardX + bw - 4;

    // === SKOR PANELİ ===
    if (_scoreBoxImage != null) {
      final scoreStr = displayScore.toInt().toString();
      const scoreFontSize = 16.0;
      final sw = bw * 0.48;
      final sh = sw * (_scoreBoxImage!.height / _scoreBoxImage!.width);
      canvas.drawImageRect(_scoreBoxImage!,
        Rect.fromLTWH(0, 0, _scoreBoxImage!.width.toDouble(), _scoreBoxImage!.height.toDouble()),
        Rect.fromLTWH(boardX, boardY - sh - 8, sw, sh),
        Paint());
      _drawTextCentered(canvas, scoreStr, boardX + sw/2 + 2, boardY - sh/2 - 10, scoreFontSize,
        const Color(0xFFFFC944), bold: true, fontWeight: FontWeight.w800);
    }

    if (_bestScoreBoxImage != null) {
      final bestStr = best.toString();
      const bestFontSize = 16.0;
      final bsw = bw * 0.48;
      final bsh = bsw * (_bestScoreBoxImage!.height / _bestScoreBoxImage!.width);
      canvas.drawImageRect(_bestScoreBoxImage!,
        Rect.fromLTWH(0, 0, _bestScoreBoxImage!.width.toDouble(), _bestScoreBoxImage!.height.toDouble()),
        Rect.fromLTWH(boardX + bw * 0.52, boardY - bsh - 8, bsw, bsh),
        Paint());
      _drawTextCentered(canvas, bestStr, boardX + bw * 0.52 + bsw/2 + 10, boardY - bsh/2 - 10, bestFontSize,
        const Color(0xFFFFC944), bold: true, fontWeight: FontWeight.w800);
    }

    // === SAĞ PANEL: MEVSİM ===
    if (activeSeason != null && seasonTurnsLeft > 0) {
      final si = kSeasons.firstWhere((s) => s.key == activeSeason, orElse: () => kSeasons[0]);
      final sColor = si.color;
      final pulse = 0.7 + sin(animTime * 3) * 0.3;
      const siH = 54.0;
      final siY = boardY + 123;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(rpX, siY, rpW, siH), const Radius.circular(10)),
        Paint()..color = sColor.withValues(alpha: 0.15));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(rpX, siY, rpW, siH), const Radius.circular(10)),
        Paint()..color = sColor.withValues(alpha: pulse * 0.8)
               ..style = PaintingStyle.stroke..strokeWidth = 1.5);
      _drawTextCentered(canvas, '${si.emoji} ${si.name}',
          rpX + rpW / 2, siY + 18, 8, sColor.withValues(alpha: pulse), bold: true);
      _drawTextCentered(canvas, '$seasonTurnsLeft TUR',
          rpX + rpW / 2, siY + 36, 9, sColor.withValues(alpha: pulse), bold: true);
    }

  }

  void _drawRightBox(Canvas canvas, double x, double y, double w, double h, String label) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(10)),
      Paint()..color = const Color(0xFF1E64C8).withValues(alpha: 0.68));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(10)),
      Paint()..color = const Color(0xFF4A9EFF).withValues(alpha: 0.72)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawTextCentered(canvas, label, x + w / 2, y + 14, 9, Colors.white.withValues(alpha: 0.85));
  }

  double _getLevelProgress() {
    final lv = level;
    final cur = lv-1 < kLevelScores.length ? kLevelScores[lv-1] : 0;
    final next = lv < kLevelScores.length ? kLevelScores[lv] : kLevelScores.last;
    return ((score-cur)/(next-cur)).clamp(0.0, 1.0);
  }

  void _drawMiniTile(Canvas canvas, double x, double y, int val) {
    final color = tileColor(val);
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x,y,18,18), const Radius.circular(4));
    canvas.drawRRect(rect, Paint()..color=color);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+1,y+1,16,6), const Radius.circular(3)),
      Paint()..color=Colors.white.withValues(alpha:0.32));
    canvas.drawRRect(rect, Paint()..color=Colors.white.withValues(alpha:0.18)..style=PaintingStyle.stroke..strokeWidth=1);
  }

  void _drawTextCentered(Canvas canvas, String text, double cx, double cy, double size, Color color, {bool bold=false, FontWeight? fontWeight}) {
    final tp = TextPainter(text:TextSpan(text:text,style:GoogleFonts.poppins(textStyle:TextStyle(fontSize:size,fontWeight:fontWeight ?? (bold ? FontWeight.w800 : FontWeight.w600),color:color))),textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx-tp.width/2, cy-tp.height/2));
  }

  void _drawMenuButton(Canvas canvas, double cx, double cy, double w, double h, String label, Color color) {
    final pulse = 0.65 + sin(animTime * 3.2) * 0.35;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      const Radius.circular(9));
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.15 * pulse));
    canvas.drawRRect(rect, Paint()
      ..color = color.withValues(alpha: 0.50 * pulse)
      ..style = PaintingStyle.stroke..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawRRect(rect, Paint()
      ..color = color.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke..strokeWidth = 1.2);
    _drawTextCentered(canvas, label, cx, cy, 11, color, bold: true);
  }

  void _drawOverlays(Canvas canvas) {
    final bw = kCols*kCell, bh = kRows*kCell;

    // Pause
    if (paused && gameActive) {
      canvas.drawRect(Rect.fromLTWH(boardX, boardY, bw, bh),
        Paint()..color = Colors.black.withValues(alpha: 0.85));
      const pw = 196.0, ph = 186.0;
      final pcx = boardX + bw / 2;
      final prx = pcx - pw / 2, pry = boardY + bh / 2 - ph / 2;
      // Panel dış glow
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(prx - 10, pry - 10, pw + 20, ph + 20), const Radius.circular(20)),
        Paint()..color = const Color(0xFFC87FFF).withValues(alpha: 0.15)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
      // Panel
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(prx, pry, pw, ph), const Radius.circular(14)),
        Paint()..color = const Color(0xFF0C0820));
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(prx, pry, pw, ph), const Radius.circular(14)),
        Paint()..color = const Color(0xFFC87FFF).withValues(alpha: 0.55)
               ..style = PaintingStyle.stroke..strokeWidth = 2.0);
      // Başlık
      _drawTextCentered(canvas, '⏸  DURAKLATILDI', pcx, pry + 30, 17,
        const Color(0xFFC87FFF), bold: true);
      // Ayırıcı
      canvas.drawLine(Offset(prx + 14, pry + 52), Offset(prx + pw - 14, pry + 52),
        Paint()..color = const Color(0xFFC87FFF).withValues(alpha: 0.28)..strokeWidth = 1);
      // Butonlar
      _drawMenuButton(canvas, pcx, pry + 90, 162, 36, '[ESC]  DEVAM ET', const Color(0xFF5CF5E0));
      _drawMenuButton(canvas, pcx, pry + 140, 162, 36, '[M]  ANA MENÜ', const Color(0xFFFF8800));
    }

    // Game over
    if (!gameActive) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Colors.black.withValues(alpha: 0.92));
      const pw = 216.0, ph = 248.0;
      final gcx = size.x / 2;
      final grx = gcx - pw / 2, gry = size.y / 2 - ph / 2 - 8;
      // Panel dış glow
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(grx - 10, gry - 10, pw + 20, ph + 20), const Radius.circular(22)),
        Paint()..color = const Color(0xFFFF3366).withValues(alpha: 0.14)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26));
      // Panel
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(grx, gry, pw, ph), const Radius.circular(16)),
        Paint()..color = const Color(0xFF0A0618));
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(grx, gry, pw, ph), const Radius.circular(16)),
        Paint()..color = const Color(0xFFFF3366).withValues(alpha: 0.60)
               ..style = PaintingStyle.stroke..strokeWidth = 2.0);
      // Başlık — nabzeden
      final gPulse = 0.65 + sin(animTime * 2.8) * 0.35;
      _drawTextCentered(canvas, 'OYUN BİTTİ', gcx, gry + 30, 20,
        const Color(0xFFFF3366).withValues(alpha: gPulse), bold: true);
      // Ayırıcı
      canvas.drawLine(Offset(grx + 16, gry + 52), Offset(grx + pw - 16, gry + 52),
        Paint()..color = const Color(0xFFFF3366).withValues(alpha: 0.30)..strokeWidth = 1);
      // Skor
      _drawTextCentered(canvas, 'SKOR', gcx, gry + 72, 9, const Color(0xFF5CF5E0));
      _drawTextCentered(canvas, displayScore.toInt().toString(), gcx, gry + 96, 26,
        Colors.white, bold: true);
      // En iyi skor karşılaştırması
      final isNewBest = score > 0 && score >= best;
      if (isNewBest) {
        final nbPulse = 0.75 + sin(animTime * 5.0) * 0.25;
        _drawTextCentered(canvas, '★  YENİ REKOR!  ★', gcx, gry + 120, 10,
          const Color(0xFFFFD700).withValues(alpha: nbPulse), bold: true);
      } else {
        _drawTextCentered(canvas, 'EN YÜKSEK: $best', gcx, gry + 120, 10,
          const Color(0xFFF5E05C));
      }
      // Ayırıcı
      canvas.drawLine(Offset(grx + 16, gry + 138), Offset(grx + pw - 16, gry + 138),
        Paint()..color = Colors.white.withValues(alpha: 0.10)..strokeWidth = 1);
      // Combo
      _drawTextCentered(canvas, 'EN İYİ COMBO: x$bestCombo', gcx, gry + 158, 10,
        const Color(0xFFFFD700));
      // Tekrar oyna butonu
      _drawMenuButton(canvas, gcx, gry + 208, 178, 36, '[R]  TEKRAR OYNA',
        const Color(0xFF5CF5E0));
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
  _PendingSeasonDrop({required this.row, required this.col, required this.type}) : timer = 0.60;
}