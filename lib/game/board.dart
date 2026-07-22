import 'dart:math';
import 'package:flutter/foundation.dart';
import 'constants.dart';

class Board {
  List<List<int>> cells;

  Board() : cells = List.generate(kRows, (_) => List.filled(kCols, 0));

  void reset() {
    cells = List.generate(kRows, (_) => List.filled(kCols, 0));
  }

  int get(int r, int c) => cells[r][c];
  void set(int r, int c, int v) => cells[r][c] = v;

  bool isSolid(int r, int c) {
    if (r < 0 || r >= kRows || c < 0 || c >= kCols) return true;
    return cells[r][c] != 0;
  }

  void applyGravity(Map<String, int> frozenSet) {
    for (int c = 0; c < kCols; c++) {
      int empty = kRows - 1;
      for (int r = kRows - 1; r >= 0; r--) {
        final v = cells[r][c];
        if (v != 0 && !isObstacle(v)) {
          if (empty != r) {
            cells[empty][c] = v;
            cells[r][c] = 0;
            final ok = '$r,$c', nk = '$empty,$c';
            if (frozenSet.containsKey(ok)) {
              frozenSet[nk] = frozenSet[ok]!;
              frozenSet.remove(ok);
            }
          }
          empty--;
        } else if (isObstacle(v)) {
          empty = r - 1;
        }
      }
    }
  }

  void flipVertical(Map<String, int> frozenSet) {
    debugPrint(
      'flipVertical çağrıldı — cells[0][0]=${cells[0][0]}, cells[${kRows - 1}][0]=${cells[kRows - 1][0]}',
    );
    for (int c = 0; c < kCols; c++) {
      int top = 0;
      int bottom = kRows - 1;
      while (top < bottom) {
        final tmp = cells[top][c];
        cells[top][c] = cells[bottom][c];
        cells[bottom][c] = tmp;

        final tk = '$top,$c';
        final bk = '$bottom,$c';
        final tFrozen = frozenSet[tk];
        final bFrozen = frozenSet[bk];
        frozenSet.remove(tk);
        frozenSet.remove(bk);
        if (tFrozen != null) frozenSet[bk] = tFrozen;
        if (bFrozen != null) frozenSet[tk] = bFrozen;

        top++;
        bottom--;
      }
    }
    debugPrint(
      'flipVertical sonrası — cells[0][0]=${cells[0][0]}, cells[${kRows - 1}][0]=${cells[kRows - 1][0]}',
    );
  }

  void applyReverseGravity(Map<String, int> frozenSet) {
    for (int c = 0; c < kCols; c++) {
      int writeRow = 0; // üstten başla — bloklar yukarı çekilir
      for (int r = 0; r < kRows; r++) {
        final v = cells[r][c];
        if (v != 0 && !isObstacle(v)) {
          if (writeRow != r) {
            cells[writeRow][c] = v;
            cells[r][c] = 0;
            final ok = '$r,$c', nk = '$writeRow,$c';
            if (frozenSet.containsKey(ok)) {
              frozenSet[nk] = frozenSet[ok]!;
              frozenSet.remove(ok);
            }
          }
          writeRow++;
        } else if (isObstacle(v)) {
          writeRow = r + 1;
        }
      }
    }
  }

  List<MergeEvent> resolveMerges(
    Map<String, int> frozenSet,
    Map<int, int> frozenCols,
    List<MultiplierLine> multiplierLines, {
    bool reverseGravity = false,
  }) {
    final events = <MergeEvent>[];
    bool anyMerged = true;
    int cycles = 0;

    while (anyMerged && cycles < 10) {
      anyMerged = false;
      cycles++;

      // Önce dikey birleşme
      for (int c = 0; c < kCols; c++) {
        for (int r = kRows - 2; r >= 0; r--) {
          final v = cells[r][c];
          if (v > 0 &&
              v == cells[r + 1][c] &&
              v < 8589934592 &&
              !frozenCols.containsKey(c) &&
              !frozenSet.containsKey('$r,$c') &&
              !frozenSet.containsKey('${r + 1},$c') &&
              !isObstacle(v) &&
              !isObstacle(cells[r + 1][c])) {
            final newVal = v * 2;
            cells[r + 1][c] = newVal;
            cells[r][c] = 0;
            frozenSet.remove('${r + 1},$c');
            frozenSet.remove('$r,$c');
            final scoreVal = _scoreForMerge(newVal);
            events.add(
              MergeEvent(
                cx: c * kCell + kCell / 2,
                cy: (r + 1) * kCell + kCell / 2,
                val: newVal,
                baseScore: scoreVal,
                mult: 1,
                bigBonus: 0,
              ),
            );
            anyMerged = true;
          }
        }
      }

      // Sonra yatay birleşme
      for (int r = 0; r < kRows; r++) {
        for (int c = 0; c < kCols - 1; c++) {
          final v = cells[r][c];
          if (v > 0 &&
              v == cells[r][c + 1] &&
              v < 8589934592 &&
              !frozenCols.containsKey(c) &&
              !frozenCols.containsKey(c + 1) &&
              !frozenSet.containsKey('$r,$c') &&
              !frozenSet.containsKey('$r,${c + 1}') &&
              !isObstacle(v)) {
            final newVal = v * 2;
            cells[r][c + 1] = newVal;
            cells[r][c] = 0;
            frozenSet.remove('$r,${c + 1}');
            frozenSet.remove('$r,$c');
            final scoreVal = _scoreForMerge(newVal);
            events.add(
              MergeEvent(
                cx: (c + 1) * kCell + kCell / 2,
                cy: r * kCell + kCell / 2,
                val: newVal,
                baseScore: scoreVal,
                mult: 1,
                bigBonus: 0,
              ),
            );
            anyMerged = true;
          }
        }
      }

      if (reverseGravity) {
        applyReverseGravity(frozenSet);
      } else {
        applyGravity(frozenSet);
      }
    }

    return events;
  }

  int _scoreForMerge(int newVal) {
    final logBase = log(newVal) / log(2);
    double scoreVal = newVal * (4.0 / logBase);
    if (newVal > 1000000) {
      // 1 milyon üzeri her blokta puan %16'dan başlayıp %2 artan oranda azaltılır
      final stepsAbove = logBase.round() - 20;
      final reduction = (0.16 + 0.02 * stepsAbove).clamp(0.0, 0.9);
      scoreVal *= (1 - reduction);
    }
    return scoreVal.round();
  }

  int _getMultiplier(int r, int c, List<MultiplierLine> lines) {
    int best = 1;
    for (final ml in lines) {
      final hit = ml.isRow ? r == ml.index : c == ml.index;
      if (hit && ml.mult > best) best = ml.mult;
    }
    return best;
  }
}

class MergeEvent {
  final double cx, cy;
  final int val, baseScore, mult, bigBonus;
  MergeEvent({
    required this.cx,
    required this.cy,
    required this.val,
    required this.baseScore,
    this.mult = 1,
    this.bigBonus = 0,
  });
}

class MultiplierLine {
  final bool isRow;
  final int index, mult;
  MultiplierLine({
    required this.isRow,
    required this.index,
    required this.mult,
  });
}
