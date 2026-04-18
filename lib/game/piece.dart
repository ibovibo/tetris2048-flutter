import 'dart:math';
import 'constants.dart';

class Piece {
  List<List<int>> shape;
  int x;
  int y;
  bool frozen;

  Piece({required this.shape, required this.x, this.y = 0, this.frozen = false});

  int get width => shape[0].length;
  int get height => shape.length;

  Piece rotated() {
    final rows = shape.length;
    final cols = shape[0].length;
    final newShape = List.generate(
      cols,
      (c) => List.generate(rows, (r) => shape[rows - 1 - r][c]),
    );
    return Piece(shape: newShape, x: x, y: y, frozen: frozen);
  }

  List<List<int>> get cells => shape;
}

class PieceGenerator {
  static final Random _rng = Random();

  static final List<Map<String, dynamic>> _pieceDefs = [
    {'w': 35, 'size': 1},
    {'w': 30, 'size': 2},
    {'w': 25, 'size': 3},
    {'w': 10, 'size': 4},
  ];
  static final int _totalW = _pieceDefs.fold(0, (s, p) => s + (p['w'] as int));

  static int randomValue(int score) {
    final pool = [
      {'v': 2,   'w': 100},
      {'v': 4,   'w': 60},
      {'v': 8,   'w': score > 100  ? 30 : 5},
      {'v': 16,  'w': score > 300  ? 20 : 3},
      {'v': 32,  'w': score > 700  ? 15 : 2},
      {'v': 64,  'w': score > 1500 ? 10 : 1},
      {'v': 128, 'w': score > 3000 ?  7 : 0},
      {'v': 256, 'w': score > 6000 ?  4 : 0},
      {'v': 512, 'w': score > 12000 ? 2 : 0},
    ];
    final total = pool.fold(0, (s, p) => s + (p['w'] as int));
    int r = _rng.nextInt(total);
    for (final p in pool) {
      r -= p['w'] as int;
      if (r <= 0) return (p['v'] as int).clamp(2, 16384);
    }
    return 2;
  }

  static Piece generate(int score, int moveCount, {String? season}) {
    // Özel parça şansları
    if (moveCount >= 5) {
      final roll = _rng.nextDouble();
      final s = score;
      // Mevsim kısıtlamaları
      final noBomb = season == 'bomb'; // bomba mevsiminde oyuncuya bomba yok
      final noSpecial = season == 'ice'; // buz mevsiminde özellik yok

      if (!noSpecial) {
        final pBomb = noBomb ? 0.0 : (0.02 + (s/8000)*0.02).clamp(0.0, 0.04);
        final pMegaBomb = noBomb ? 0.0 : 0.03;
        final pIce = (0.01 + (s/10000)*0.03).clamp(0.0, 0.04);
        final pX2 = (0.03 + (s/6000)*0.05).clamp(0.0, 0.08);
        final pX4 = (0.02 + (s/8000)*0.03).clamp(0.0, 0.05);
        final pX8 = (0.005 + (s/12000)*0.01).clamp(0.0, 0.015);
        final pX16 = (0.0025 + (s/20000)*0.005).clamp(0.0, 0.0075);
        final pJoker = (0.04 + (s/12000)*0.06).clamp(0.0, 0.10);
        final pStar = 0.04;

        if (roll < pBomb) return _single(kBomb);
        if (roll < pBomb+pMegaBomb) return _single(kMegaBomb);
        if (roll < pBomb+pMegaBomb+pIce) return _single(kIce);
        if (roll < pBomb+pMegaBomb+pIce+pX2) return _multiType(kX2);
        if (roll < pBomb+pMegaBomb+pIce+pX2+pX4) return _multiType(kX4);
        if (roll < pBomb+pMegaBomb+pIce+pX2+pX4+pX8) return _multiType(kX8);
        if (roll < pBomb+pMegaBomb+pIce+pX2+pX4+pX8+pX16) return _multiType(kX16);
        if (_rng.nextDouble() < pJoker) return _multiType(kJoker);
        if (_rng.nextDouble() < pStar) return _single(kStar);
        if (_rng.nextDouble() < 0.05) return _single(_rng.nextBool() ? kShuffleRow : kShuffleCol);
      }
    }

    // Normal parça
    int r = _rng.nextInt(_totalW);
    int size = 1;
    for (final p in _pieceDefs) {
      r -= p['w'] as int;
      if (r <= 0) { size = p['size'] as int; break; }
    }

    return _buildNormal(size, score, moveCount);
  }

  static Piece _single(int type) {
    return Piece(shape: [[type]], x: 2);
  }

  static Piece _multiType(int type) {
    final size = _rng.nextInt(3) + 1;
    if (size == 1) return Piece(shape: [[type]], x: 2);
    if (_rng.nextBool()) {
      return Piece(shape: [List.filled(size, type)], x: _rng.nextInt(kCols - size + 1));
    } else {
      return Piece(shape: List.generate(size, (_) => [type]), x: _rng.nextInt(kCols));
    }
  }

  static Piece _buildNormal(int size, int score, int moveCount) {
    int rv() => randomValue(score);
    List<List<int>> shape;

    if (size == 3) {
      final templates = [
        [[1,0],[1,0],[1,1]],
        [[1,1,1],[1,0,0]],
        [[1,1],[0,1],[0,1]],
        [[0,0,1],[1,1,1]],
      ];
      final t = templates[_rng.nextInt(templates.length)];
      shape = t.map((row) => row.map((c) => c != 0 ? rv() : 0).toList()).toList();
    } else if (size >= 4) {
      if (_rng.nextBool()) {
        shape = [[rv(),rv()],[rv(),rv()]];
      } else {
        final templates = [
          [[1,1,1],[1,0,0]],
          [[1,1,1],[0,0,1]],
          [[1,0,0],[1,1,1]],
          [[0,0,1],[1,1,1]],
        ];
        final t = templates[_rng.nextInt(templates.length)];
        shape = t.map((row) => row.map((c) => c != 0 ? rv() : 0).toList()).toList();
      }
    } else if (size == 2) {
      if (_rng.nextBool()) {
        shape = [[rv(), rv()]];
      } else {
        shape = [[rv()],[rv()]];
      }
    } else {
      shape = [[rv()]];
    }

    final cols = shape[0].length;
    final startX = _rng.nextInt((kCols - cols).clamp(1, kCols));
    final frozen = moveCount >= 3 && _rng.nextDouble() < 0.15;
    return Piece(shape: shape, x: startX, frozen: frozen);
  }
}