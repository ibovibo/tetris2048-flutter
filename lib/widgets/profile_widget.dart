import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n.dart';
import 'avatar_display.dart';

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({
    super.key,
    required this.userName,
    required this.level,
    required this.xpProgress,
    this.avatarPath,
    this.avatarIndex,
    required this.onEditAvatar,
  });

  final String userName;
  final int level;
  final double xpProgress;
  final String? avatarPath;
  final int? avatarIndex;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 920 / 330,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Profile circle (pixel-perfect circle: dimensions in width units)
          final photoDiameter = w * 0.265;
          final photoRadius = photoDiameter / 2;
          const circleCenterXPct = 0.17;
          const circleCenterYPct = 0.44;
          final circleCenterX = w * circleCenterXPct;
          final circleCenterY = h * circleCenterYPct;

          // Edit button: bottom-right of circle at 45°
          final editSize = (photoDiameter * 0.197).clamp(22.0, 37.4);
          const diag = 0.7071; // cos/sin 45°
          final editLeft = circleCenterX + photoRadius * diag - editSize / 2;
          final editTop = circleCenterY + photoRadius * diag - editSize / 2;

          // Content area
          final contentLeft = w * 0.365;
          final contentRight = w * 0.05;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Background frame
              Positioned.fill(
                child: Image.asset(
                  'assets/images/profil.png',
                  fit: BoxFit.fill,
                ),
              ),

              // Profile photo overlay
              Positioned(
                left: circleCenterX - photoRadius,
                top: circleCenterY - photoRadius,
                width: photoDiameter,
                height: photoDiameter,
                child: AvatarDisplay(
                  size: photoDiameter,
                  customPhotoPath: avatarPath,
                  avatarIndex: avatarIndex,
                ),
              ),

              // Edit button
              Positioned(
                left: editLeft,
                top: editTop,
                width: editSize,
                height: editSize,
                child: GestureDetector(
                  onTap: onEditAvatar,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF59E0B),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: editSize * 0.50,
                    ),
                  ),
                ),
              ),

              // User name
              Positioned(
                left: contentLeft,
                top: h * 0.06,
                right: contentRight,
                child: Text(
                  userName,
                  textScaler: TextScaler.noScaling,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: h * 0.24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.55),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Level label
              Positioned(
                left: contentLeft,
                top: h * 0.38,
                right: contentRight,
                child: Text(
                  '${L10n.t('level')} $level',
                  textScaler: TextScaler.noScaling,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: h * 0.155,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),

              // XP bar
              Positioned(
                left: contentLeft,
                right: contentRight,
                top: h * 0.61,
                height: h * 0.30,
                child: _XpBar(xpProgress: xpProgress),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.xpProgress});
  final double xpProgress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final pct = (xpProgress.clamp(0.0, 1.0) * 100).round();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Star icon
            Icon(
              Icons.star_rounded,
              color: const Color(0xFFF59E0B),
              size: h * 0.92,
            ),
            SizedBox(width: w * 0.015),

            // Progress bar
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: xpProgress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Container(
                    height: h * 0.72,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(h * 0.36),
                    ),
                    child: Stack(
                      children: [
                        // Gradient fill
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF22D3EE),
                                  Color(0xFF3B82F6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Glassmorphic top highlight
                        Positioned(
                          top: h * 0.06,
                          left: h * 0.10,
                          right: h * 0.10,
                          height: h * 0.20,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(h * 0.10),
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SizedBox(width: w * 0.02),

            // Percentage capsule
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.025,
                vertical: h * 0.06,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(h * 0.36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '%$pct',
                textScaler: TextScaler.noScaling,
                style: GoogleFonts.poppins(
                  fontSize: h * 0.60,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A8A),
                  height: 1.0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
