import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'board.dart';
import 'piece.dart';
import 'constants.dart';
import 'special_resolver.dart';
import 'sound_manager.dart';
import 'particle_system.dart';
import 'max_explosion.dart';

class TetrisGame extends FlameGame with KeyboardEvents {
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

  double boardX = 0;
  double boardY = 0;
  MaxExplosion? _maxExplosion;

  @override
  Color backgroundColor() => const Color(0xFF04040E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    board = Board();
    SoundManager.init().then((_) => SoundManager.playGameMusic());
    await _loadBest();
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

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    boardX = (size.x - kCols * kCell) / 2 - 60;
    boardY = (size.y - kRows * kCell) / 2;
  }

  void _initGame() {
    board.reset();
    score = 0; displayScore = 0;
    level = 1; combo = 1;
    streak = 0; streakTimer = 0;
    moveCount = 0; totalMoves = 0;
    speed = 540; dropTimer = 0;
    frozenSet = {}; frozenCols = {};
    comboHeat = 0; pieceVisualY = 0; screenShake = 0;
    seenMilestones = {}; maxTile = 0;
    activeSeason = null; seasonTurnsLeft = 0; _seasonBombTimer = 0;
    multiplierLines.clear();
    popCells.clear();
    _pendingDrops.clear();

    currentPiece = PieceGenerator.generate(score, moveCount, season: activeSeason);
    nextPiece = PieceGenerator.generate(score, moveCount, season: activeSeason);
    nextQueue.clear();
    nextQueue.add(PieceGenerator.generate(score, moveCount, season: activeSeason));
    nextQueue.add(PieceGenerator.generate(score, moveCount, season: activeSeason));
    pieceVisualY = currentPiece.y.toDouble();
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
  void goToMenu() { gameActive = false; paused = true; onPause?.call(); }

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
    if      (_valid(rot.shape, rot.x,   rot.y)) { currentPiece = rot; }
    else if (_valid(rot.shape, rot.x-1, rot.y)) { currentPiece = rot; currentPiece.x--; }
    else if (_valid(rot.shape, rot.x+1, rot.y)) { currentPiece = rot; currentPiece.x++; }
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
        _endSeason();
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
      particles.addNotification('COMBO x$combo!', comboColor);
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
      particles.addNotification('🔥 5 STREAK! +500', const Color(0xFFFF8040));
      particles.spawnConfetti(kCols*kCell/2, kRows*kCell/2);
    } else if (streak == 10) {
      _addScore(2000);
      particles.addNotification('⚡ 10 STREAK! +2000', const Color(0xFFFFCC00));
      particles.spawnConfetti(kCols*kCell/2, kRows*kCell/2); screenShake = 0.35;
    } else if (streak == 20) {
      _addScore(10000);
      particles.addNotification('🌟 20 STREAK! +10000', const Color(0xFFC87FFF));
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
      SoundManager.milestone(val);
      particles.addMilestoneBanner(val, msgs[val] ?? '', tileColor(val));
      if (val >= 2048) {
        particles.spawnConfetti(kCols*kCell/2, kRows*kCell/2);
        screenShake = 0.5;
      }
    }

    if (val >= 32768) {
      if (_maxExplosion == null) {
        _triggerMaxExplosion();
      }
    }

  }

  void _triggerMaxExplosion() {
    // Mevcut mevsimi hemen bitir
    if (activeSeason != null) _endSeason();
    SoundManager.maxExplosion32k();

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

  void _startRandomSeason() {
    activeSeason = kSeasons[_pendingSeasonIdx].key;
    seasonTurnsLeft = 10;
    _seasonBombTimer = 2.0;

    if (activeSeason == 'speed') {
      speed = (speed / 2).clamp(50, 270);
    }

    // Kuyruktaki eski parçaları yeni mevsime göre yenile
    nextPiece = PieceGenerator.generate(score, moveCount, season: activeSeason);
    nextQueue.clear();
    nextQueue.add(PieceGenerator.generate(score, moveCount, season: activeSeason));
    nextQueue.add(PieceGenerator.generate(score, moveCount, season: activeSeason));

    particles.addNotification(
      '${kSeasons[_pendingSeasonIdx].emoji} ${kSeasons[_pendingSeasonIdx].name} MEVSİMİ!',
      kSeasons[_pendingSeasonIdx].color,
    );
  }

  void _endSeason() {
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
    particles.addNotification('Mevsim bitti!', const Color(0xFF5CF5E0));
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
      particles.addLevelTransition(level, const Color(0xFFF0C040));
      particles.spawnConfetti(kCols*kCell/2, 0);
      screenShake = 0.3;
    }
  }

  Future<void> _endGame() async {
    gameActive = false;
    await SoundManager.stopMusic();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await SoundManager.gameOver();
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
      // Animasyon bitti — şimdi mevsimi başlat
      _startRandomSeason();
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

    if (screenShake > 0) {
      final dx = (_rng.nextDouble()-0.5)*screenShake*14;
      final dy = (_rng.nextDouble()-0.5)*screenShake*14;
      canvas.save();
      canvas.translate(dx, dy);
    }

    _drawBackground(canvas);
    _drawMultiplierLines(canvas);
    _drawBoard(canvas);
    _drawGhost(canvas);
    _drawPiece(canvas);
    _drawUI(canvas);
    _drawOverlays(canvas);
    particles.render(canvas, boardX, boardY, screenW: size.x, screenH: size.y);

    if (screenShake > 0) canvas.restore();

    // Süper patlama — her şeyin üstünde
    _maxExplosion?.render(canvas, size.x, size.y);
  }

  void _drawBackground(Canvas canvas) {
    final s = size;
    final gridPaint = Paint()..color = const Color(0xFF1A1040).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke..strokeWidth = 0.5;
    for (double x = 0; x < s.x; x += kCell) {
      canvas.drawLine(Offset(x,0), Offset(x,s.y), gridPaint);
    }
    for (double y = 0; y < s.y; y += kCell) {
      canvas.drawLine(Offset(0,y), Offset(s.x,y), gridPaint);
    }
  }

  void _drawMultiplierLines(Canvas canvas) {
    for (final ml in multiplierLines) {
      final pulse = 0.5 + sin(animTime*3 + ml.index*0.5)*0.5;
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
      canvas.drawRect(rect, Paint()..color = lc.withValues(alpha: 0.09*pulse));
      canvas.drawRect(rect, Paint()..color = lc.withValues(alpha: 0.55*pulse)..style=PaintingStyle.stroke..strokeWidth=1.5);
      final tp = TextPainter(text: TextSpan(text:'×${ml.mult}', style:TextStyle(fontFamily:'monospace',fontSize:10,fontWeight:FontWeight.bold,color:lc.withValues(alpha:0.9))), textDirection:TextDirection.ltr)..layout();
      final tx = ml.isRow ? boardX+kCols*kCell-tp.width-4 : boardX+ml.index*kCell+(kCell-tp.width)/2;
      final ty = ml.isRow ? boardY+ml.index*kCell+(kCell-tp.height)/2 : boardY+4;
      tp.paint(canvas, Offset(tx, ty));
    }
  }

  void _drawBoard(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(boardX, boardY, kCols*kCell, kRows*kCell),
      Paint()..color = const Color(0xFF060418));

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
        if (v == maxTile && maxTile >= 8) _drawMaxTileGlow(canvas, c, r, v);

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
        Paint()..color = color.withValues(alpha: alpha * 0.35)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));

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

    // Board kenarlık
    final borderCol = comboHeat > 0.4 ? const Color(0xFFFF4488) : const Color(0xFFAA44FF);
    canvas.drawRect(Rect.fromLTWH(boardX, boardY, kCols*kCell, kRows*kCell),
      Paint()..color = borderCol.withValues(alpha:0.9)..style=PaintingStyle.stroke..strokeWidth=2);
    canvas.drawRect(Rect.fromLTWH(boardX-3, boardY-3, kCols*kCell+6, kRows*kCell+6),
      Paint()..color = borderCol.withValues(alpha:0.2)..style=PaintingStyle.stroke..strokeWidth=5);
  }

  // Max tile etrafında dönen parçacıklar + halo
  void _drawMaxTileGlow(Canvas canvas, int c, int r, int val) {
    final cx = boardX + c*kCell + kCell/2;
    final cy = boardY + r*kCell + kCell/2;
    final color = tileColor(val);
    final tier = (log(val.toDouble()) / log(2)).round();
    final t = animTime;

    // Halo
    final haloR = kCell*0.62 + (tier-3)*3 + sin(t*2)*4;
    canvas.drawCircle(Offset(cx, cy), haloR,
      Paint()..color = color.withValues(alpha:0.30)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    // Parlak kenarlık nabzı
    canvas.drawRect(Rect.fromLTWH(boardX+c*kCell+1, boardY+r*kCell+1, kCell-2, kCell-2),
      Paint()..color = color.withValues(alpha:0.65+sin(t*3)*0.35)
             ..style=PaintingStyle.stroke..strokeWidth=2.5
             ..maskFilter=const MaskFilter.blur(BlurStyle.normal, 6));

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
    final pulse = 0.42 + sin(t * 2) * 0.06;

    // Buz tabakası
    canvas.drawRect(Rect.fromLTWH(x+1, y+1, kCell-2, kCell-2),
      Paint()..color = const Color(0xFF8CD2FF).withValues(alpha: pulse));

    // Kristal parlaması sol üst
    canvas.drawRect(Rect.fromLTWH(x+3, y+3, (kCell-2)*0.4, (kCell-2)*0.2),
      Paint()..color = Colors.white.withValues(alpha: 0.32));

    // Buz kenarlık nabzı
    canvas.drawRect(Rect.fromLTWH(x+1, y+1, kCell-2, kCell-2),
      Paint()..color = const Color(0xFFA0E6FF).withValues(alpha: 0.8 + sin(t * 2) * 0.2)
             ..style = PaintingStyle.stroke..strokeWidth = 2
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Çatlak çizgileri
    final crackPaint = Paint()
      ..color = const Color(0xFFDCF5FF).withValues(alpha: 0.55 + sin(t) * 0.15)
      ..strokeWidth = 0.9;
    canvas.drawLine(Offset(x+5, y+4), Offset(x+kCell/2, y+kCell/2), crackPaint);
    canvas.drawLine(Offset(x+kCell/2, y+kCell/2), Offset(x+kCell-6, y+kCell-5), crackPaint);
    canvas.drawLine(Offset(x+kCell-5, y+5), Offset(x+kCell/2-2, y+kCell/2+2), crackPaint);
    canvas.drawLine(Offset(x+kCell/2-2, y+kCell/2+2), Offset(x+4, y+kCell-5), crackPaint);
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

    // Dış neon glow
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+pad-3, y+pad-3, kCell-pad*2+6, kCell-pad*2+6), const Radius.circular(10)),
      Paint()..color=color.withValues(alpha:0.35*alpha)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));

    // Ana dolgu
    canvas.drawRRect(rect, Paint()..color=color.withValues(alpha:alpha));

    // Glass üst şerit
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+pad+2, y+pad+2, kCell-pad*2-4, (kCell-pad*2)*0.42), const Radius.circular(6)),
      Paint()..color=Colors.white.withValues(alpha:0.38*alpha));

    // Alt koyu
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x+pad, y+kCell-pad-10, kCell-pad*2, 10), const Radius.circular(5)),
      Paint()..color=Colors.black.withValues(alpha:0.38*alpha));

    // Kenarlık
    canvas.drawRRect(rect, Paint()..color=Colors.white.withValues(alpha:0.28*alpha)..style=PaintingStyle.stroke..strokeWidth=1.5);

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
    final px = boardX + kCols*kCell + 14;

    _drawPanel(canvas, px, boardY+0,   112, 68);
    _drawText(canvas, 'SKOR', px+8, boardY+8, 9, const Color(0xFF5CF5E0));
    _drawText(canvas, displayScore.toInt().toString(), px+8, boardY+26, 20, const Color(0xFFC87FFF), bold:true);

    _drawPanel(canvas, px, boardY+75,  112, 52);
    _drawText(canvas, 'EN YÜKSEK', px+8, boardY+83, 8, const Color(0xFF5CF5E0));
    _drawText(canvas, best.toString(), px+8, boardY+97, 16, const Color(0xFFF5E05C), bold:true);

    _drawPanel(canvas, px, boardY+134, 112, 52);
    _drawText(canvas, 'LEVEL', px+8, boardY+142, 9, const Color(0xFF5CF5E0));
    _drawText(canvas, level.toString(), px+8, boardY+156, 20, const Color(0xFFC87FFF), bold:true);

    // Level bar
    canvas.drawRect(Rect.fromLTWH(px, boardY+190, 112, 4), Paint()..color=const Color(0xFF1A0A3A));
    canvas.drawRect(Rect.fromLTWH(px, boardY+190, 112*_getLevelProgress(), 4), Paint()..color=const Color(0xFF5CF5E0));

    _drawPanel(canvas, px, boardY+200, 112, 56);
    _drawText(canvas, 'COMBO', px+8, boardY+208, 9, const Color(0xFF5CF5E0));
    final comboColor = combo >= 12 ? const Color(0xFFFF3366)
        : combo >= 8  ? const Color(0xFFFF6600)
        : combo >= 5  ? const Color(0xFFFFCC00)
        : combo >= 3  ? const Color(0xFF88FF44)
        :               const Color(0xFFC87FFF);
    final comboSize = combo >= 12 ? 28.0
        : combo >= 8  ? 26.0
        : combo >= 5  ? 24.0
        : combo >= 3  ? 22.0
        :               20.0;

    if (combo >= 3) {
      final pulse = 0.5 + sin(animTime * (combo >= 8 ? 6 : 4)) * 0.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(px, boardY+200, 112, 56), const Radius.circular(6)),
        Paint()..color = comboColor.withValues(alpha: 0.15 * pulse),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(px, boardY+200, 112, 56), const Radius.circular(6)),
        Paint()..color = comboColor.withValues(alpha: 0.6 * pulse)
               ..style = PaintingStyle.stroke..strokeWidth = combo >= 8 ? 2.5 : 1.5,
      );
    }

    _drawText(canvas, 'x$combo', px+8, boardY+222, comboSize, comboColor, bold: true);
    if (streak > 0) _drawText(canvas, '🔥$streak', px+72, boardY+225, 13, const Color(0xFFFF8040), bold: true);

    _drawPanel(canvas, px, boardY+262, 112, 52);
    _drawText(canvas, 'EN İYİ COMBO', px+8, boardY+270, 8, const Color(0xFF5CF5E0));
    _drawText(canvas, 'x$bestCombo', px+8, boardY+284, 16, const Color(0xFFFFD700), bold:true);

    _drawPanel(canvas, px, boardY+320, 112, 88);
    _drawText(canvas, 'SONRAKİ', px+8, boardY+328, 8, const Color(0xFF5CF5E0));
    for (int r = 0; r < nextPiece.shape.length; r++) {
      for (int c = 0; c < nextPiece.shape[r].length; c++) {
        final v = nextPiece.shape[r][c];
        if (v != 0) _drawMiniTile(canvas, px+8+c*20, boardY+343+r*20, v);
      }
    }

    _drawTextCentered(canvas, '2048 × TETRİS', boardX+kCols*kCell/2, boardY-28, 15, const Color(0xFFC87FFF), bold:true);

    // Mevsim göstergesi
    if (activeSeason != null && seasonTurnsLeft > 0) {
      final si = kSeasons.firstWhere((s) => s.key == activeSeason,
          orElse: () => kSeasons[0]);
      final sColor = si.color;
      final sName = '${si.emoji} ${si.name}';
      final pulse = 0.7 + sin(animTime * 3) * 0.3;

      final sw = 180.0, sh = 28.0;
      final sx = boardX + kCols * kCell / 2 - sw / 2;
      final sy = boardY - 58.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(sx, sy, sw, sh), const Radius.circular(6)),
        Paint()..color = sColor.withValues(alpha: 0.15),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(sx, sy, sw, sh), const Radius.circular(6)),
        Paint()..color = sColor.withValues(alpha: pulse * 0.8)
               ..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );
      _drawTextCentered(canvas,
        '$sName  $seasonTurnsLeft TUR',
        boardX + kCols * kCell / 2, sy + sh / 2,
        10, sColor.withValues(alpha: pulse),
        bold: true,
      );
    }

    _drawText(canvas, '⏸ [ESC]', boardX, boardY-28, 10, const Color(0xFF5858A0));
  }

  void _drawPanel(Canvas canvas, double x, double y, double w, double h) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h), const Radius.circular(6)),
      Paint()..color=const Color(0xFF0C0820));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h), const Radius.circular(6)),
      Paint()..color=const Color(0xFF5CF5E0).withValues(alpha:0.15)..style=PaintingStyle.stroke..strokeWidth=1);
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

  void _drawText(Canvas canvas, String text, double x, double y, double size, Color color, {bool bold=false}) {
    final tp = TextPainter(text:TextSpan(text:text,style:TextStyle(fontFamily:'monospace',fontSize:size,fontWeight:bold?FontWeight.bold:FontWeight.normal,color:color)),textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x,y));
  }

  void _drawTextCentered(Canvas canvas, String text, double cx, double cy, double size, Color color, {bool bold=false}) {
    final tp = TextPainter(text:TextSpan(text:text,style:TextStyle(fontFamily:'monospace',fontSize:size,fontWeight:bold?FontWeight.bold:FontWeight.normal,color:color)),textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx-tp.width/2, cy-tp.height/2));
  }

  void _drawOverlays(Canvas canvas) {
    final bw = kCols*kCell, bh = kRows*kCell;

    // Combo heat overlay — sol/sağ kenar gradyan
    if (comboHeat > 0) {
      final pulse = 0.5 + sin(dangerPulse*4)*0.5;
      final h = comboHeat;
      // Mor→pembe→beyaz geçiş
      final r = (180+h*75).clamp(0,255).toInt();
      final g = (h*100).clamp(0,255).toInt();
      final b = (255-h*55).clamp(0,255).toInt();
      final heatColor = Color.fromARGB(255, r, g, b);

      canvas.drawRect(Rect.fromLTWH(boardX, boardY, 4, bh),
        Paint()..color=heatColor.withValues(alpha:h*0.7*pulse)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
      canvas.drawRect(Rect.fromLTWH(boardX+bw-4, boardY, 4, bh),
        Paint()..color=heatColor.withValues(alpha:h*0.7*pulse)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));

      // Board kenar nabzı
      canvas.drawRect(Rect.fromLTWH(boardX, boardY, bw, bh),
        Paint()..color=heatColor.withValues(alpha:h*0.75*pulse)..style=PaintingStyle.stroke..strokeWidth=5+h*8);
    }

    // Danger vignette
    int dangerCount = 0;
    for (int r = 0; r < 4; r++) for (int c = 0; c < kCols; c++) {
      if (board.get(r,c) != 0) dangerCount++;
    }
    if (dangerCount > 0) {
      final intensity = (dangerCount/8).clamp(0.0,1.0);
      final pulse = 0.5 + sin(dangerPulse*3)*0.5;
      canvas.drawRect(Rect.fromLTWH(boardX,boardY,bw,bh),
        Paint()..color=const Color(0xFFDD1422).withValues(alpha:intensity*pulse*0.9)..style=PaintingStyle.stroke..strokeWidth=7+intensity*8);
      canvas.drawRect(Rect.fromLTWH(boardX,boardY,bw,6),
        Paint()..color=const Color(0xFFDD1422).withValues(alpha:intensity*pulse*0.7));
    }

    // Pause
    if (paused && gameActive) {
      canvas.drawRect(Rect.fromLTWH(boardX,boardY,bw,bh), Paint()..color=Colors.black.withValues(alpha:0.82));
      _drawTextCentered(canvas,'⏸ DURAKLATILDI',boardX+bw/2,boardY+bh/2-44,20,const Color(0xFFC87FFF),bold:true);
      _drawTextCentered(canvas,'[ESC] DEVAM ET',boardX+bw/2,boardY+bh/2-6,13,const Color(0xFF5CF5E0));
      _drawTextCentered(canvas,'[M] ANA MENÜ',boardX+bw/2,boardY+bh/2+22,13,const Color(0xFFFF8800));
    }

    // Game over
    if (!gameActive) {
      canvas.drawRect(Rect.fromLTWH(boardX,boardY,bw,bh), Paint()..color=Colors.black.withValues(alpha:0.90));
      _drawTextCentered(canvas,'BİTTİ',boardX+bw/2,boardY+bh/2-60,36,const Color(0xFFFF3366),bold:true);
      _drawTextCentered(canvas,'SKOR: $score',boardX+bw/2,boardY+bh/2-14,20,Colors.white);
      _drawTextCentered(canvas,'EN YÜKSEK: $best',boardX+bw/2,boardY+bh/2+18,14,const Color(0xFFF5E05C));
      _drawTextCentered(canvas,'EN İYİ COMBO: x$bestCombo',boardX+bw/2,boardY+bh/2+42,12,const Color(0xFFFFD700));
      _drawTextCentered(canvas,'[R] TEKRAR OYNA',boardX+bw/2,boardY+bh/2+68,14,const Color(0xFF5CF5E0));
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