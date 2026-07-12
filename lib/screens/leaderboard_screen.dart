import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n.dart';
import '../leaderboard_manager.dart';
import '../widgets/avatar_display.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _tab = 0; // 0=global, 1=yerel, 2=haftalık
  bool _loading = true;
  bool _error = false;
  List<LeaderboardEntry> _entries = const [];

  static const _navyBlue = Color(0xFF1E3A8A);

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _myUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      List<LeaderboardEntry> result;
      switch (_tab) {
        case 1:
          final code = await LeaderboardManager.resolveCountryCode();
          result = await LeaderboardManager.fetchLocal(code);
        case 2:
          result = await LeaderboardManager.fetchWeekly();
        default:
          result = await LeaderboardManager.fetchGlobal();
      }
      if (!mounted) return;
      setState(() {
        _entries = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _selectTab(int tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    _load();
  }

  String _fmtScore(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFDAA520);
      case 2:
        return const Color(0xFF8A96A3);
      case 3:
        return const Color(0xFFB0682E);
      default:
        return _navyBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final myUid = _myUid;

    // Menüdeki alt navigasyon bu ekranın üzerinde her zaman görünür kalır —
    // liste içeriği onun altında kalmasın diye pay bırakılır.
    final navReserve = h * 0.18;
    final listTop = h * 0.305;
    final listBottomInset = navReserve > h * 0.055 ? navReserve : h * 0.055;
    final rowH = h * 0.078;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/siralama.png', fit: BoxFit.fill),
          ),

          // ── Sekmeler ──────────────────────────────────────────────────
          _buildTab(
            index: 0,
            label: L10n.t('lb_global'),
            centerX: w * 0.223,
            centerY: h * 0.254,
            w: w,
            h: h,
          ),
          _buildTab(
            index: 1,
            label: L10n.t('lb_local'),
            centerX: w * 0.494,
            centerY: h * 0.254,
            w: w,
            h: h,
          ),
          _buildTab(
            index: 2,
            label: L10n.t('lb_weekly'),
            centerX: w * 0.776,
            centerY: h * 0.254,
            w: w,
            h: h,
          ),

          // ── Liste alanı ───────────────────────────────────────────────
          Positioned(
            top: listTop,
            left: w * 0.08,
            right: w * 0.08,
            bottom: listBottomInset,
            child: _buildListBody(w, rowH, myUid),
          ),

          // ── Geri butonu ───────────────────────────────────────────────
          Positioned(
            left: w * 0.03,
            top: h * 0.02,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.maybePop(context);
                }
              },
              child: Container(
                width: w * 0.11,
                height: w * 0.11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.85),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(Icons.arrow_back_rounded, color: _navyBlue, size: w * 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required double centerX,
    required double centerY,
    required double w,
    required double h,
  }) {
    final selected = _tab == index;
    final tabW = w * 0.27;
    final tabH = h * 0.052;
    // "YEREL" ve "HAFTALIK" sekmeleri ikona biraz fazla yakın duruyordu — sağa kaydır.
    final extraLeftShift = index == 1
        ? tabW * 0.10
        : index == 2
            ? tabW * 0.04
            : 0.0;
    return Positioned(
      left: centerX - tabW / 2,
      top: centerY - tabH / 2,
      width: tabW,
      height: tabH,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(index),
        child: Padding(
          padding: EdgeInsets.only(
            left: tabW * 0.32 + extraLeftShift,
            right: tabW * 0.08,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textScaler: TextScaler.noScaling,
                style: GoogleFonts.poppins(
                  fontSize: tabH * 0.40,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? const Color(0xFF1D4ED8)
                      : _navyBlue.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListBody(double w, double rowH, String? myUid) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _navyBlue),
      );
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L10n.t('lb_error'),
              textScaler: TextScaler.noScaling,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w700,
                color: _navyBlue,
              ),
            ),
            SizedBox(height: w * 0.03),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _load,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: w * 0.025),
                decoration: BoxDecoration(
                  color: _navyBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  L10n.t('lb_retry'),
                  textScaler: TextScaler.noScaling,
                  style: GoogleFonts.poppins(
                    fontSize: w * 0.034,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.06),
          child: Text(
            L10n.t('lb_empty'),
            textScaler: TextScaler.noScaling,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: w * 0.036,
              fontWeight: FontWeight.w600,
              color: _navyBlue.withValues(alpha: 0.75),
            ),
          ),
        ),
      );
    }

    return ClipRect(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _entries.length,
        itemBuilder: (context, i) {
          final e = _entries[i];
          return SizedBox(
            height: rowH,
            child: _buildRow(e, w, rowH, isMe: e.uid == myUid && myUid != null),
          );
        },
      ),
    );
  }

  Widget _buildRow(LeaderboardEntry e, double w, double rowH, {required bool isMe}) {
    final avatarSize = w * 0.11;
    return Container(
      decoration: isMe
          ? BoxDecoration(
              color: const Color(0xFFFFE082).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      padding: EdgeInsets.symmetric(horizontal: w * 0.02),
      child: Row(
        children: [
          SizedBox(
            width: w * 0.14,
            child: Text(
              '#${e.rank}',
              textScaler: TextScaler.noScaling,
              style: GoogleFonts.poppins(
                fontSize: rowH * 0.32,
                fontWeight: FontWeight.w800,
                color: _rankColor(e.rank),
              ),
            ),
          ),
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: AvatarDisplay(size: avatarSize, avatarIndex: e.avatarIndex),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              e.userName,
              textScaler: TextScaler.noScaling,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: rowH * 0.30,
                fontWeight: FontWeight.w700,
                color: _navyBlue,
              ),
            ),
          ),
          Text(
            _fmtScore(e.score),
            textScaler: TextScaler.noScaling,
            style: GoogleFonts.poppins(
              fontSize: rowH * 0.30,
              fontWeight: FontWeight.w800,
              color: _navyBlue,
            ),
          ),
        ],
      ),
    );
  }
}
