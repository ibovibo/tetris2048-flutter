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

  List<MergeEvent> resolveMerges(
    Map<String, int> frozenSet,
    Map<int, int> frozenCols,
    List<MultiplierLine> multiplierLines,
  ) {
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
            if (v > 0 && v == cells[r + 1][c] && v < 32768 &&
              !frozenCols.containsKey(c) &&
              !frozenSet.containsKey('$r,$c') &&
              !frozenSet.containsKey('${r + 1},$c') &&
              !isObstacle(v) && !isObstacle(cells[r + 1][c])) {
            final newVal = v * 2;
            cells[r + 1][c] = newVal;
            cells[r][c] = 0;
            frozenSet.remove('${r + 1},$c');
            frozenSet.remove('$r,$c');
            final mult = _getMultiplier(r, c, multiplierLines);
            final bigBonus = newVal >= 4096 ? newVal : (newVal >= 2048 ? newVal ~/ 2 : 0);
            events.add(MergeEvent(
              cx: c * kCell + kCell / 2,
              cy: (r + 1) * kCell + kCell / 2,
              val: newVal,
              baseScore: newVal * mult + bigBonus,
              mult: mult,
              bigBonus: bigBonus,
            ));
            anyMerged = true;
          }
        }
      }

      // Sonra yatay birleşme
      for (int r = 0; r < kRows; r++) {
        for (int c = 0; c < kCols - 1; c++) {
          final v = cells[r][c];
            if (v > 0 && v == cells[r][c + 1] && v < 32768 &&
              !frozenCols.containsKey(c) && !frozenCols.containsKey(c + 1) &&
              !frozenSet.containsKey('$r,$c') &&
              !frozenSet.containsKey('$r,${c + 1}') &&
              !isObstacle(v)) {
            final newVal = v * 2;
            cells[r][c + 1] = newVal;
            cells[r][c] = 0;
            frozenSet.remove('$r,${c + 1}');
            frozenSet.remove('$r,$c');
            final mult = _getMultiplier(r, c, multiplierLines);
            final bigBonus = newVal >= 4096 ? newVal : (newVal >= 2048 ? newVal ~/ 2 : 0);
            events.add(MergeEvent(
              cx: (c + 1) * kCell + kCell / 2,
              cy: r * kCell + kCell / 2,
              val: newVal,
              baseScore: newVal * mult + bigBonus,
              mult: mult,
              bigBonus: bigBonus,
            ));
            anyMerged = true;
          }
        }
      }

      applyGravity(frozenSet);
    }

    return events;
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
    required this.cx, required this.cy, required this.val,
    required this.baseScore, this.mult = 1, this.bigBonus = 0,
  });
}

class MultiplierLine {
  final bool isRow;
  final int index, mult;
  MultiplierLine({required this.isRow, required this.index, required this.mult});
}