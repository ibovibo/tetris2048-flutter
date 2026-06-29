import 'dart:io';

import 'package:flutter/material.dart';

class AvatarDisplay extends StatelessWidget {
  const AvatarDisplay({
    required this.size,
    this.customPhotoPath,
    this.avatarIndex,
    // Geriye dönük uyumluluk için eski parametre adı da desteklenir
    this.avatarPath,
    super.key,
  });

  final double size;
  final String? customPhotoPath;
  final int? avatarIndex;
  final String? avatarPath; // eski API — customPhotoPath ile eş

  static const String _defaultAsset = 'assets/images/anonpp.png';

  String? get _resolvedPath => customPhotoPath ?? avatarPath;

  @override
  Widget build(BuildContext context) {
    // Preset avatar — PNG zaten yuvarlak, ClipOval/cover gerekmez
    if (_resolvedPath == null && avatarIndex != null && avatarIndex! >= 1 && avatarIndex! <= 12) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/ui/avatars/pp$avatarIndex.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Image.asset(_defaultAsset, fit: BoxFit.contain, width: size, height: size),
        ),
      );
    }

    // Kendi fotoğrafı veya default anon — ClipOval ile yuvarlak göster
    Widget child;
    if (_resolvedPath != null) {
      child = Image.file(
        File(_resolvedPath!),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) =>
            Image.asset(_defaultAsset, fit: BoxFit.cover, width: size, height: size),
      );
    } else {
      child = Image.asset(_defaultAsset, fit: BoxFit.contain, width: size, height: size);
    }

    return ClipOval(child: SizedBox(width: size, height: size, child: child));
  }
}
