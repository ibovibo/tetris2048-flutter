import 'dart:math';
import 'constants.dart';

class Piece {
  List<List<int>> shape;
  int x;
  int y;
  bool frozen;

  Piece({
    required this.shape,
    required this.x,
    this.y = 0,
    this.frozen = false,
  });

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

  Piece rotatedReverse() {
    final rows = shape.length;
    final cols = shape[0].length;
    final newShape = List.generate(
      cols,
      (c) => List.generate(rows, (r) => shape[r][cols - 1 - c]),
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
    final List<Map<String, dynamic>> pool;

    if (score < 25000) {
      pool = [
        {'v': 2, 'w': 100},
        {'v': 4, 'w': 60},
        {'v': 8, 'w': 30},
        {'v': 16, 'w': 20},
        {'v': 32, 'w': 15},
        {'v': 64, 'w': 10},
      ];
    } else if (score < 50000) {
      pool = [
        {'v': 2, 'w': 100},
        {'v': 4, 'w': 60},
        {'v': 8, 'w': 30},
        {'v': 16, 'w': 20},
        {'v': 32, 'w': 15},
        {'v': 64, 'w': 10},
        {'v': 128, 'w': 7},
        {'v': 256, 'w': 4},
      ];
    } else if (score < 100000) {
      pool = [
        {'v': 2, 'w': 100},
        {'v': 4, 'w': 60},
        {'v': 8, 'w': 30},
        {'v': 16, 'w': 20},
        {'v': 32, 'w': 15},
        {'v': 64, 'w': 10},
        {'v': 128, 'w': 7},
        {'v': 256, 'w': 4},
        {'v': 512, 'w': 2},
      ];
    } else if (score < 500000) {
      pool = [
        {'v': 2, 'w': 70},
        {'v': 4, 'w': 50},
        {'v': 8, 'w': 40},
        {'v': 16, 'w': 30},
        {'v': 32, 'w': 25},
        {'v': 64, 'w': 20},
        {'v': 128, 'w': 15},
        {'v': 256, 'w': 10},
        {'v': 512, 'w': 5},
      ];
    } else if (score < 1000000) {
      pool = [
        {'v': 2, 'w': 40},
        {'v': 4, 'w': 40},
        {'v': 8, 'w': 40},
        {'v': 16, 'w': 35},
        {'v': 32, 'w': 30},
        {'v': 64, 'w': 25},
        {'v': 128, 'w': 20},
        {'v': 256, 'w': 15},
        {'v': 512, 'w': 10},
        {'v': 1024, 'w': 5},
      ];
    } else if (score < 5000000) {
      pool = [
        {'v': 4, 'w': 30},
        {'v': 8, 'w': 40},
        {'v': 16, 'w': 35},
        {'v': 32, 'w': 30},
        {'v': 64, 'w': 25},
        {'v': 128, 'w': 20},
        {'v': 256, 'w': 15},
        {'v': 512, 'w': 12},
        {'v': 1024, 'w': 10},
      ];
    } else if (score < 10000000) {
      pool = [
        {'v': 8, 'w': 30},
        {'v': 16, 'w': 35},
        {'v': 32, 'w': 30},
        {'v': 64, 'w': 25},
        {'v': 128, 'w': 20},
        {'v': 256, 'w': 18},
        {'v': 512, 'w': 15},
        {'v': 1024, 'w': 12},
        {'v': 2048, 'w': 8},
      ];
    } else if (score < 20000000) {
      pool = [
        {'v': 16, 'w': 30},
        {'v': 32, 'w': 30},
        {'v': 64, 'w': 28},
        {'v': 128, 'w': 25},
        {'v': 256, 'w': 22},
        {'v': 512, 'w': 18},
        {'v': 1024, 'w': 15},
        {'v': 2048, 'w': 10},
        {'v': 4096, 'w': 5},
      ];
    } else if (score < 30000000) {
      pool = [
        {'v': 32, 'w': 25},
        {'v': 64, 'w': 28},
        {'v': 128, 'w': 25},
        {'v': 256, 'w': 22},
        {'v': 512, 'w': 20},
        {'v': 1024, 'w': 18},
        {'v': 2048, 'w': 15},
        {'v': 4096, 'w': 10},
        {'v': 8192, 'w': 5},
      ];
    } else if (score < 50000000) {
      pool = [
        {'v': 64, 'w': 25},
        {'v': 128, 'w': 25},
        {'v': 256, 'w': 22},
        {'v': 512, 'w': 20},
        {'v': 1024, 'w': 18},
        {'v': 2048, 'w': 15},
        {'v': 4096, 'w': 12},
        {'v': 8192, 'w': 8},
        {'v': 16384, 'w': 5},
      ];
    } else {
      pool = [
        {'v': 128, 'w': 20},
        {'v': 256, 'w': 20},
        {'v': 512, 'w': 20},
        {'v': 1024, 'w': 18},
        {'v': 2048, 'w': 16},
        {'v': 4096, 'w': 14},
        {'v': 8192, 'w': 10},
        {'v': 16384, 'w': 8},
        {'v': 32768, 'w': 5},
        {'v': 65536, 'w': 3},
        {'v': 131072, 'w': 2},
      ];
    }

    final total = pool.fold(0, (s, p) => s + (p['w'] as int));
    int r = _rng.nextInt(total);
    for (final p in pool) {
      r -= p['w'] as int;
      if (r <= 0) return p['v'] as int;
    }
    return pool.first['v'] as int;
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
        final pBomb = noBomb
            ? 0.0
            : (0.02 + (s / 8000) * 0.02).clamp(0.0, 0.04);
        final pMegaBomb = noBomb ? 0.0 : 0.03;
        final pIce = (0.01 + (s / 10000) * 0.03).clamp(0.0, 0.04);
        final pX2 = (0.03 + (s / 6000) * 0.05).clamp(0.0, 0.08);
        final pX4 = (0.02 + (s / 8000) * 0.03).clamp(0.0, 0.05);
        final pX8 = (0.005 + (s / 12000) * 0.01).clamp(0.0, 0.015);
        final pX16 = (0.0025 + (s / 20000) * 0.005).clamp(0.0, 0.0075);
        final pJoker = (0.04 + (s / 12000) * 0.06).clamp(0.0, 0.10);
        final pStar = 0.04;

        if (roll < pBomb) return _single(kBomb);
        if (roll < pBomb + pMegaBomb) return _single(kMegaBomb);
        if (roll < pBomb + pMegaBomb + pIce) return _single(kIce);
        if (roll < pBomb + pMegaBomb + pIce + pX2) {
          return _multiType(kX2, season: season);
        }
        if (roll < pBomb + pMegaBomb + pIce + pX2 + pX4) {
          return _multiType(kX4, season: season);
        }
        if (roll < pBomb + pMegaBomb + pIce + pX2 + pX4 + pX8) {
          return _multiType(kX8, season: season);
        }
        if (roll < pBomb + pMegaBomb + pIce + pX2 + pX4 + pX8 + pX16) {
          return _multiType(kX16, season: season);
        }
        if (_rng.nextDouble() < pJoker) return _single(kJoker);
        if (_rng.nextDouble() < pStar) return _single(kStar);
        if (_rng.nextDouble() < 0.05) return _single(kChaos);
      }
    }

    // Normal parça
    int r = _rng.nextInt(_totalW);
    int size = 1;
    for (final p in _pieceDefs) {
      r -= p['w'] as int;
      if (r <= 0) {
        size = p['size'] as int;
        break;
      }
    }
    return _buildNormal(size, score, moveCount);
  }

  static Piece _single(int type) {
    return Piece(
      shape: [
        [type],
      ],
      x: 2,
    );
  }

  static Piece _multiType(int type, {String? season}) {
    final size = _rng.nextInt(3) + 1;
    if (size == 1) {
      return Piece(
        shape: [
          [type],
        ],
        x: 2,
      );
    }
    if (_rng.nextBool()) {
      return Piece(
        shape: [List.filled(size, type)],
        x: _rng.nextInt(kCols - size + 1),
      );
    } else {
      return Piece(
        shape: List.generate(size, (_) => [type]),
        x: _rng.nextInt(kCols),
      );
    }
  }

  static Piece _buildNormal(int size, int score, int moveCount) {
    int rv() => randomValue(score);
    List<List<int>> shape;

    if (size == 3) {
      final templates = [
        [
          [1, 0],
          [1, 0],
          [1, 1],
        ],
        [
          [1, 1, 1],
          [1, 0, 0],
        ],
        [
          [1, 1],
          [0, 1],
          [0, 1],
        ],
        [
          [0, 0, 1],
          [1, 1, 1],
        ],
      ];
      final t = templates[_rng.nextInt(templates.length)];
      shape = t
          .map((row) => row.map((c) => c != 0 ? rv() : 0).toList())
          .toList();
    } else if (size >= 4) {
      if (_rng.nextBool()) {
        shape = [
          [rv(), rv()],
          [rv(), rv()],
        ];
      } else {
        final templates = [
          [
            [1, 1, 1],
            [1, 0, 0],
          ],
          [
            [1, 1, 1],
            [0, 0, 1],
          ],
          [
            [1, 0, 0],
            [1, 1, 1],
          ],
          [
            [0, 0, 1],
            [1, 1, 1],
          ],
        ];
        final t = templates[_rng.nextInt(templates.length)];
        shape = t
            .map((row) => row.map((c) => c != 0 ? rv() : 0).toList())
            .toList();
      }
    } else if (size == 2) {
      if (_rng.nextBool()) {
        shape = [
          [rv(), rv()],
        ];
      } else {
        shape = [
          [rv()],
          [rv()],
        ];
      }
    } else {
      shape = [
        [rv()],
      ];
    }

    final cols = shape[0].length;
    final startX = _rng.nextInt((kCols - cols).clamp(1, kCols));
    final frozen = moveCount >= 3 && _rng.nextDouble() < 0.15;
    return Piece(shape: shape, x: startX, frozen: frozen);
  }
}
