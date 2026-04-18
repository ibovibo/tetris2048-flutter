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
  });

  void resolveAll() {
    _resolveBombs();
    _resolveMegaBombs();
    _resolveIce();
    _resolveShuffles();
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

  // ── SHUFFLE ──────────────────────────────────────────────
  void _resolveShuffles() {
    final rng = Random();
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (board.get(r, c) == kShuffleRow) {
          board.set(r, c, 0);
          final vals = <int>[];
          for (int cc = 0; cc < kCols; cc++) {
            if (board.get(r, cc) != 0) vals.add(board.get(r, cc));
          }
          vals.shuffle(rng);
          int idx = 0;
          for (int cc = 0; cc < kCols; cc++) {
            if (board.get(r, cc) != 0) { board.set(r, cc, vals[idx++]); }
          }
          showFloat('↔ KARISTIRILDI!');
        }
        if (board.get(r, c) == kShuffleCol) {
          board.set(r, c, 0);
          final vals = <int>[];
          for (int rr = 0; rr < kRows; rr++) {
            if (board.get(rr, c) != 0) vals.add(board.get(rr, c));
          }
          vals.shuffle(rng);
          int idx = 0;
          for (int rr = 0; rr < kRows; rr++) {
            if (board.get(rr, c) != 0) { board.set(rr, c, vals[idx++]); }
          }
          showFloat('↕ KARISTIRILDI!');
        }
      }
    }
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
          board.set(bestR, bestC, bestVal * 2);
          addScore(bestVal);
          spawnParticle(bestC * kCell + kCell/2, bestR * kCell + kCell/2, bestVal * 2);
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
          // Komşu yoksa boarddaki en sık değeri al
          final freq = <int, int>{};
          for (int rr = 0; rr < kRows; rr++) {
            for (int cc = 0; cc < kCols; cc++) {
              final v = board.get(rr, cc);
              if (v > 0 && !isObstacle(v)) freq[v] = (freq[v] ?? 0) + 1;
            }
          }
          if (freq.isEmpty) continue;
          targetVal = freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        }

        // Tüm targetVal'ları sil ve say
        int count = 0;
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
          final newVal = (v * mult).clamp(0, 32768);
          board.set(nr, nc, newVal);
          addScore(newVal);
          spawnParticle(nc * kCell + kCell/2, nr * kCell + kCell/2, newVal);
          hit = true;
        }
        // Komşu yoksa sütunun en altından al
        if (!hit) {
          for (int nr = kRows - 1; nr >= 0; nr--) {
            final v = board.get(nr, c);
            if (v > 0 && !isObstacle(v) && !claimed.contains('$nr,$c')) {
              claimed.add('$nr,$c');
              board.set(nr, c, (v * mult).clamp(0, 32768));
              break;
            }
          }
        }
        showFloat('×$mult!');
      }
    }
  }
}