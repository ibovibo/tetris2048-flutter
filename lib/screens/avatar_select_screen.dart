import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../avatar_manager.dart';
import '../l10n.dart';
import '../widgets/avatar_display.dart';

class AvatarSelectScreen extends StatefulWidget {
  const AvatarSelectScreen({super.key});

  @override
  State<AvatarSelectScreen> createState() => _AvatarSelectScreenState();
}

class _AvatarSelectScreenState extends State<AvatarSelectScreen> {
  int? _selectedIndex;     // 1-15, preset
  String? _customPath;     // kendi fotoğrafı

  @override
  void initState() {
    super.initState();
    _selectedIndex = AvatarManager.avatarIndex;
    _customPath = AvatarManager.avatarPath;
  }

  // ── Fotoğraf seçimi ───────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final savedPath = '${appDir.path}/avatar.png';
    await File(image.path).copy(savedPath);
    setState(() {
      _customPath = savedPath;
      _selectedIndex = null;
    });
  }


  // ── Kaydet ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_customPath != null) {
      await AvatarManager.setAvatar(_customPath!);
    } else if (_selectedIndex != null) {
      await AvatarManager.setAvatarIndex(_selectedIndex!);
    } else {
      await AvatarManager.resetToDefault();
    }
    if (mounted) Navigator.pop(context);
  }

  // ── Önizleme widget ───────────────────────────────────────────────────────

  Widget _buildPreview(double size) {
    return AvatarDisplay(
      size: size,
      customPhotoPath: _customPath,
      avatarIndex: _selectedIndex,
    );
  }

  // ── Galeri/kamera seçim dialogu ──────────────────────────────────────────

  Future<void> _showPickerDialog() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E3A8A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
              title: Text(L10n.t('gallery'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              title: Text(L10n.t('camera'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
          ],
        ),
      ),
    );
  }

  // ── Kamera/galeri hücresi (pp1 slotu) ────────────────────────────────────

  Widget _buildCameraCell(double cellW, double cellH) {
    final isSelected = _customPath != null;
    final avatarSize = cellH * 0.970;
    final iconSize = avatarSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showPickerDialog,
      child: SizedBox(
        width: cellW,
        height: cellH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Fotoğraf veya pp1.png
            if (isSelected)
              ClipOval(
                child: Image.file(
                  File(_customPath!),
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                ),
              )
            else
              AvatarDisplay(size: avatarSize, avatarIndex: 1),

            // Seçili halkası
            if (isSelected)
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2563EB), width: 3),
                ),
              ),

            // Kamera ikonu — orta
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.60),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: iconSize * 0.58),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid hücresi (index 2-12 = pp2-pp12) ─────────────────────────────────

  Widget _buildCell(int avatarIdx, double cellW, double cellH) {
    final isSelected = _selectedIndex == avatarIdx;
    final base = cellH * 0.970;
    final avatarSize = avatarIdx <= 2 ? base : base * 1.1025;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _selectedIndex = avatarIdx;
        _customPath = null;
      }),
      child: SizedBox(
        width: cellW,
        height: cellH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            avatarIdx <= 2
                ? AvatarDisplay(size: avatarSize, avatarIndex: avatarIdx)
                : OverflowBox(
                    maxWidth: avatarSize,
                    maxHeight: avatarSize,
                    child: AvatarDisplay(size: avatarSize, avatarIndex: avatarIdx),
                  ),

            if (isSelected)
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2563EB), width: 3),
                ),
              ),
            if (isSelected)
              Positioned(
                right: cellW * 0.07,
                top: cellH * 0.40,
                child: Container(
                  width: cellW * 0.19,
                  height: cellW * 0.19,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2563EB),
                  ),
                  child: Icon(Icons.check_rounded,
                      color: Colors.white, size: cellW * 0.12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Grid koordinatları — 3 sütun, 5 satır
          const List<double> colXPct = [0.22, 0.50, 0.78];
          const List<double> rowYPct = [0.415, 0.545, 0.675, 0.805];
          final cellW = w * 0.32;
          final cellH = h * 0.11;

          return Stack(
            children: [
              // ── Arka plan ────────────────────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  'assets/images/pp_ekran.png',
                  fit: BoxFit.fill,
                ),
              ),

              // ── Başlık ───────────────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                top: h * 0.04,
                child: Text(
                  L10n.t('choose_avatar'),
                  textScaler: TextScaler.noScaling,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: h * 0.028,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ),

              // ── Önizleme dairesi — asset'teki büyük dairenin üstüne ────
              Positioned(
                left: w * 0.50 - w * 0.215,
                top: h * 0.21 - w * 0.215,
                width: w * 0.43,
                height: w * 0.43,
                child: _buildPreview(w * 0.43),
              ),

              // ── Grid hücreleri — 3 sütun x 4 satır (pp1-pp12) ──────────
              for (int row = 0; row < 4; row++)
                for (int col = 0; col < 3; col++)
                  Positioned(
                    left: w * colXPct[col] - cellW / 2,
                    top: h * rowYPct[row] - cellH / 2,
                    width: cellW,
                    height: cellH,
                    child: row == 0 && col == 0
                        ? _buildCameraCell(cellW, cellH)
                        : _buildCell(
                            row * 3 + col + 1,
                            cellW,
                            cellH,
                          ),
                  ),

              // ── Geri butonu hit area ──────────────────────────────────────
              Positioned(
                left: 0,
                top: h * 0.005,
                width: w * 0.20,
                height: h * 0.10,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                ),
              ),

              // ── SAVE butonu yazısı ────────────────────────────────────────
              Positioned(
                left: w * 0.20,
                right: w * 0.20,
                top: h * 0.924,
                height: h * 0.05,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _save,
                  child: Center(
                    child: Text(
                      L10n.t('save'),
                      textScaler: TextScaler.noScaling,
                      style: GoogleFonts.poppins(
                        fontSize: h * 0.0308,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
