import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../block_skin_manager.dart';
import '../l10n.dart';
import '../widgets/block_display.dart';

class BlockSkinScreen extends StatefulWidget {
  const BlockSkinScreen({super.key});

  @override
  State<BlockSkinScreen> createState() => _BlockSkinScreenState();
}

class _BlockSkinScreenState extends State<BlockSkinScreen> {
  static const _entries = [
    (SpecialBlockType.bomb, 'block_bomb'),
    (SpecialBlockType.megaBomb, 'block_mega_bomb'),
    (SpecialBlockType.ice, 'block_ice'),
    (SpecialBlockType.star, 'block_star'),
    (SpecialBlockType.chaos, 'block_chaos'),
  ];

  bool _busy = false;

  // ── Kaynak seçimi (galeri/kamera) ────────────────────────────────────────

  Future<void> _showSourcePicker(SpecialBlockType type) async {
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
              title: Text(
                L10n.t('gallery'),
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndCrop(type, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              title: Text(
                L10n.t('take_photo'),
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndCrop(type, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: Colors.white70),
              title: Text(
                L10n.t('cancel'),
                style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Seç + kare kırp + kaydet ─────────────────────────────────────────────

  Future<void> _pickAndCrop(SpecialBlockType type, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    String finalPath;
    try {
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: L10n.t('crop_title'),
            toolbarColor: const Color(0xFF1E3A8A),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: L10n.t('crop_title'),
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (cropped == null) return; // kullanıcı kırpmayı iptal etti
      finalPath = cropped.path;
    } on MissingPluginException {
      // image_cropper masaüstünde (macOS/Windows/Linux) desteklenmiyor —
      // test amaçlı, seçilen görsel kırpılmadan doğrudan kullanılır.
      finalPath = picked.path;
    }

    setState(() => _busy = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final savedPath = '${appDir.path}/block_${type.name}.png';
      await File(finalPath).copy(savedPath);
      await BlockSkinManager.setSkin(type, savedPath);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Tek blok sıfırlama ───────────────────────────────────────────────────

  Future<void> _resetOne(SpecialBlockType type) async {
    await BlockSkinManager.resetSkin(type);
    if (mounted) setState(() {});
  }

  // ── Hepsini sıfırla ──────────────────────────────────────────────────────

  Future<void> _confirmResetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          L10n.t('reset_all_skins_title'),
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          L10n.t('reset_all_skins_body'),
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              L10n.t('cancel'),
              style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              L10n.t('confirm'),
              style: GoogleFonts.poppins(color: const Color(0xFFF59E0B), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await BlockSkinManager.resetAll();
      if (mounted) setState(() {});
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildRow(SpecialBlockType type, String labelKey) {
    final hasCustom = BlockSkinManager.hasCustom(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _glassCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BlockDisplay(type: type, size: 72),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  L10n.t(labelKey),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _busy ? null : () => _showSourcePicker(type),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        L10n.t('change_skin'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  if (hasCustom)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SizedBox(
                        height: 32,
                        child: TextButton(
                          onPressed: () => _resetOne(type),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(44, 32),
                          ),
                          child: Text(
                            L10n.t('reset_skin'),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1230), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      iconSize: 28,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                    Expanded(
                      child: Text(
                        L10n.t('block_skins'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    for (final entry in _entries) _buildRow(entry.$1, entry.$2),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _confirmResetAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB91C1C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          L10n.t('reset_all_skins'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
