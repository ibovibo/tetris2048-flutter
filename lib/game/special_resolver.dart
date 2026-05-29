import 'dart:math';
import 'board.dart';
import 'constants.dart';

class SpecialResolver {
  final Board board;
  final Map<String, int> frozenSet;
  final Map<int, int> frozenCols;
  final void Function(int score) addScore;
  final void Function(double cx, double cy, int val) spawnParticle;
  final void Function(String msg) showFloat;
  final void Function()? playBombSfx;
  final void Function()? playMegaBombSfx;
  final void Function()? playIceJokerSfx;
  final void Function()? playStarSfx;
  final void Function()? onJokerTriggered;
  final void Function(double gain)? onMeterGain;

  SpecialResolver({
    required this.board,
    required this.frozenSet,
    required this.frozenCols,
    required this.addScore,
    required this.spawnParticle,
    required this.showFloat,
    this.playBombSfx,
    this.playMegaBombSfx,
    this.playIceJokerSfx,
    this.playStarSfx,
    this.onJokerTriggered,
    this.onMeterGain,
  });

  void resolveAll() {
    _resolveBombs();
    _resolveMegaBombs();
    _resolveIce();
    _resolveChaos();
    _resolveJokers();
    _resolveStar();
    _resolveMultipliers(kX2, 2);
    _resolveMultipliers(kX4, 4);
    _resolveMultipliers(kX8, 8);
    _resolveMultipliers(kX16, 16);
  }

  // ── BOMB — 3x3 alan ──────────────────────────────────────
  void _resolveBombs() {
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (board.get(r, c) != kBomb) continue;
        board.set(r, c, 0);
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final nr = r + dr, nc = c + dc;
            if (nr < 0 || nr >= kRows || nc < 0 || nc >= kCols) continue;
            if (board.get(nr, nc) != 0) {
              spawnParticle(nc * kCell + kCell/2, nr * kCell + kCell/2, 32);
              board.set(nr, nc, 0);
            }
          }
        }
        addScore(500);
        showFloat('💣 BOOM!');
        playBombSfx?.call();
        board.applyGravity(frozenSet);
      }
    }
  }

  // ── MEGABOMB — 4x4 alan ──────────────────────────────────
  void _resolveMegaBombs() {
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (board.get(r, c) != kMegaBomb) continue;
        board.set(r, c, 0);
        int totalVal = 0;
        for (int dr = -1; dr <= 2; dr++) {
          for (int dc = -1; dc <= 2; dc++) {
            final nr = r + dr, nc = c + dc;
            if (nr < 0 || nr >= kRows || nc < 0 || nc >= kCols) continue;
            totalVal += board.get(nr, nc).clamp(0, 999999);
            if (board.get(nr, nc) != 0) {
              spawnParticle(nc * kCell + kCell/2, nr * kCell + kCell/2, 64);
            }
            board.set(nr, nc, 0);
          }
        }
        final bonus = max(2000, totalVal * 2);
        addScore(bonus);
        showFloat('💥 DEV PATLAMA!');
        playMegaBombSfx?.call();
        board.applyGravity(frozenSet);
      }
    }
  }

  // ── ICE — sütunu 3 tur dondur ────────────────────────────
  void _resolveIce() {
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (board.get(r, c) != kIce) continue;
        board.set(r, c, 0);
        frozenCols[c] = 3;
        for (int row = 0; row < kRows; row++) {
          if (board.get(row, c) > 0) {
            frozenSet['$row,$c'] = 3;
          }
        }
        playIceJokerSfx?.call();
        showFloat('❄ DONDURULDU!');
      }
    }
  }

  void _resolveChaos() {
    final rng = Random();
    bool triggered = false;
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (board.get(r, c) == kChaos) {
          board.set(r, c, 0);
          triggered = true;
        }
      }
    }
    if (!triggered) return;

    // Tüm board'daki blokları topla
    final vals = <int>[];
    final positions = <List<int>>[];
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        final v = board.get(r, c);
        if (v != 0 && !isObstacle(v)) {
          vals.add(v);
          positions.add([r, c]);
          board.set(r, c, 0);
        }
      }
    }

    // Rastgele karıştır ve geri yerleştir
    vals.shuffle(rng);
    for (int i = 0; i < positions.length; i++) {
      board.set(positions[i][0], positions[i][1], vals[i]);
    }

    showFloat('💥 KAOS!');
  }

  // ── JOKER — komşu max değeri 2 katlar ────────────────────
  void _resolveJokers() {
    final claimed = <String>{};
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (board.get(r, c) != kJoker) continue;
        board.set(r, c, 0);
        int bestVal = 0, bestR = -1, bestC = -1;
        for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
          final nr = r + d[0], nc = c + d[1];
          if (nr < 0 || nr >= kRows || nc < 0 || nc >= kCols) continue;
          final v = board.get(nr, nc);
          if (v <= 0 || isObstacle(v)) continue;
          if (claimed.contains('$nr,$nc')) continue;
          if (v > bestVal) { bestVal = v; bestR = nr; bestC = nc; }
        }
        if (bestR >= 0) {
          claimed.add('$bestR,$bestC');
          final newVal = bestVal * 2;
          board.set(bestR, bestC, newVal);
          addScore(bestVal);
          spawnParticle(bestC * kCell + kCell/2, bestR * kCell + kCell/2, newVal);
          onMeterGain?.call(_getMergeFillStatic(newVal));
          onJokerTriggered?.call();
          showFloat('JOKER!');
        }
      }
    }
    board.applyGravity(frozenSet);
  }

  void _resolveStar() {
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (board.get(r, c) != kStar) continue;
        board.set(r, c, 0);

        int targetVal = 0;

        // Komşulardaki MIN değeri bul (en düşük öncelik)
        int minNeighbor = 999999;
        for (final d in [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]]) {
          final nr = d[0], nc = d[1];
          if (nr < 0 || nr >= kRows || nc < 0 || nc >= kCols) continue;
          final v = board.get(nr, nc);
          if (v > 0 && !isObstacle(v) && v < minNeighbor) minNeighbor = v;
        }

        if (minNeighbor < 999999) {
          targetVal = minNeighbor;
        } else {
          continue; // komsu yoksa hicbir sey yapma
        }

        // Tüm targetVal'ları sil ve say
        int count = 0;
        playStarSfx?.call();
        for (int rr = 0; rr < kRows; rr++) {
          for (int cc = 0; cc < kCols; cc++) {
            if (board.get(rr, cc) == targetVal) {
              board.set(rr, cc, 0);
              count++;
              spawnParticle(cc * kCell + kCell/2, rr * kCell + kCell/2, targetVal);
            }
          }
        }

        board.applyGravity(frozenSet);

        // Puan: targetVal × count × 50
        final bonus = targetVal * count * 50;
        addScore(bonus);
        showFloat('✦ $targetVal×$count×50 = +$bonus!');
      }
    }
  }

  // ── X2 / X4 / X8 / X16 ───────────────────────────────────
  void _resolveMultipliers(int type, int mult) {
    final claimed = <String>{};
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (board.get(r, c) != type) continue;
        board.set(r, c, 0);
        bool hit = false;
        for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
          final nr = r + d[0], nc = c + d[1];
          if (nr < 0 || nr >= kRows || nc < 0 || nc >= kCols) continue;
          final v = board.get(nr, nc);
          if (v <= 0 || isObstacle(v)) continue;
          if (claimed.contains('$nr,$nc')) continue;
          claimed.add('$nr,$nc');
          final newVal = (v * mult).clamp(0, 4194304);
          board.set(nr, nc, newVal);
          addScore(newVal);
          spawnParticle(nc * kCell + kCell/2, nr * kCell + kCell/2, newVal);
          onMeterGain?.call(_getMergeFillStatic(newVal));
          hit = true;
        }
        // Komşu yoksa sütunun en altından al
        if (!hit) {
          for (int nr = kRows - 1; nr >= 0; nr--) {
            final v = board.get(nr, c);
            if (v > 0 && !isObstacle(v) && !claimed.contains('$nr,$c')) {
              claimed.add('$nr,$c');
              final newVal = (v * mult).clamp(0, 4194304);
              board.set(nr, c, newVal);
              onMeterGain?.call(_getMergeFillStatic(newVal));
              break;
            }
          }
        }
        showFloat('×$mult!');
      }
    }
  }

  static double _getMergeFillStatic(int value) {
    const table = {
      4: 0.5,
      8: 0.75,
      16: 1.0,
      32: 1.25,
      64: 1.5,
      128: 2.0,
      256: 2.75,
      512: 3.75,
      1024: 5.0,
      2048: 6.5,
      4096: 8.5,
      8192: 11.0,
      16384: 14.0,
      32768: 17.5,
    };
    if (table.containsKey(value)) return table[value]!;
    if (value > 32768) {
      return 17.5 + (log(value / 32768) / log(2)) * 5.0;
    }
    return 0.5;
  }
}