import 'package:flutter/material.dart';

// Board boyutları
const int kCols = 6;
const int kRows = 12;
const double kCell = 48.0;

// Özel parça tipleri
const int kJoker = -1;
const int kBomb = -2;
const int kIce = -3;
const int kX2 = -4;
const int kChaos = -5;
const int kStone = -7;
const int kLocked = -8;
const int kDoubleHit = -9;
const int kSpinner = -10;
const int kDark = -11;
const int kMegaBomb = -12;
const int kX4 = -13;
const int kX8 = -14;
const int kX16 = -15;
const int kStar = -16;

// Normal tile renkleri
const List<int> NORMAL_VALUES = [
  2,
  4,
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
  32768,
  65536,
  131072,
  262144,
  524288,
  1048576,
  2097152,
  4194304,
];

const Map<int, Color> kTileColors = {
  2: Color(0xFF5599FF),
  4: Color(0xFF33FFCC),
  8: Color(0xFFBB55FF),
  16: Color(0xFFFF3366),
  32: Color(0xFFFF8833),
  64: Color(0xFFFFCC11),
  128: Color(0xFFFF44CC),
  256: Color(0xFF11DDFF),
  512: Color(0xFF44FF99),
  1024: Color(0xFFFF6600),
  2048: Color(0xFFFFEE33),
  4096: Color(0xFFFF1188),
  8192: Color(0xFF00FFEE),
  16384: Color(0xFFFF9900),
  32768: Color(0xFFCC44FF),
  65536: Color(0xFF00FF88),
  131072: Color(0xFFFF2255),
  262144: Color(0xFFFFFFFF),
  524288: Color(0xFF00CCFF),
  1048576: Color(0xFFFFAA00),
  2097152: Color(0xFF44FF44),
  4194304: Color(0xFFFF4444),
};

// Level skor eşikleri
const List<int> kLevelScores = [
  0,
  2000,
  6000,
  15000,
  35000,
  80000,
  140000,
  220000,
  320000,
  450000,
  650000,
  900000,
  1200000,
  1600000,
  2100000,
  2700000,
  3500000,
  4500000,
  5700000,
  7200000,
  9000000,
  11200000,
  14000000,
  17500000,
  22000000,
  27500000,
  34000000,
  42000000,
  52000000,
  65000000,
  80000000,
  100000000,
  125000000,
  155000000,
  190000000,
  235000000,
  290000000,
  360000000,
  445000000,
  550000000,
];

Color tileColor(int val) {
  if (kTileColors.containsKey(val)) return kTileColors[val]!;
  switch (val) {
    case kJoker:
      return const Color(0xFFFFD700);
    case kBomb:
      return const Color(0xFFFF4400);
    case kMegaBomb:
      return const Color(0xFFFF1100);
    case kIce:
      return const Color(0xFF88EEFF);
    case kX2:
      return const Color(0xFFFFFF00);
    case kX4:
      return const Color(0xFFFF8C00);
    case kX8:
      return const Color(0xFFFF3CB4);
    case kX16:
      return const Color(0xFFC87FFF);
    case kStar:
      return const Color(0xFFE8E8FF);
    case kChaos:
      return const Color(0xFFFF88FF);
    case kStone:
      return const Color(0xFF888888);
    case kLocked:
      return const Color(0xFF6633AA);
    case kDoubleHit:
      return const Color(0xFFAA6633);
    case kSpinner:
      return const Color(0xFF33AAFF);
    case kDark:
      return const Color(0xFF222233);
    default:
      return const Color(0xFF888888);
  }
}

bool isObstacle(int v) =>
    v == kStone ||
    v == kLocked ||
    v == kDoubleHit ||
    v == kSpinner ||
    v == kDark;

bool isSpecial(int v) => v < 0 && !isObstacle(v);
