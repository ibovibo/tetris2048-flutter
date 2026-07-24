import 'dart:io';

import 'package:flutter/material.dart';

import '../block_skin_manager.dart';

/// Özel bloğun (bomba, buz, yıldız vb.) güncel görselini gösterir.
/// Kullanıcının özelleştirdiği bir görsel varsa onu, yoksa varsayılan asset'i çizer.
class BlockDisplay extends StatelessWidget {
  final SpecialBlockType type;
  final double size;

  const BlockDisplay({super.key, required this.type, required this.size});

  Widget _defaultAsset() => Image.asset(
        BlockSkinManager.defaultAssets[type]!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );

  @override
  Widget build(BuildContext context) {
    final custom = BlockSkinManager.customSkins[type];
    if (custom == null) return _defaultAsset();

    // Aynı dosya yoluna her seferinde kaydedildiği için Image.file'ın
    // ImageProvider'ı path bazlı eşitlik yüzünden değişikliği fark etmez.
    // Bytes'ı doğrudan okuyup Image.memory ile göstermek her setState'te
    // güncel görseli garanti eder.
    try {
      final bytes = File(custom).readAsBytesSync();
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _defaultAsset(),
      );
    } catch (_) {
      return _defaultAsset();
    }
  }
}
