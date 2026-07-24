import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n.dart';

/// Instagram/WhatsApp tarzı manuel kırpma ekranı — kullanıcı görseli
/// sürükleyip yakınlaştırarak kare alanın neresinin görüneceğini kendi seçer.
/// Native bir eklentiye bağlı olmadığı için tüm platformlarda (masaüstü dahil)
/// aynı şekilde çalışır.
class ManualCropScreen extends StatefulWidget {
  final String imagePath;
  const ManualCropScreen({super.key, required this.imagePath});

  @override
  State<ManualCropScreen> createState() => _ManualCropScreenState();
}

class _ManualCropScreenState extends State<ManualCropScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _controller = TransformationController();

  double? _imgWidth;
  double? _imgHeight;
  bool _centered = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _imgWidth = frame.image.width.toDouble();
      _imgHeight = frame.image.height.toDouble();
    });
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final pixelRatio = 512 / boundary.size.width;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted || byteData == null) return;
      Navigator.pop(context, byteData.buffer.asUint8List());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    iconSize: 28,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  Expanded(
                    child: Text(
                      L10n.t('crop_title'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _saving
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: _imgWidth == null ? null : _confirm,
                          icon: const Icon(Icons.check_rounded, color: Color(0xFFF59E0B)),
                          iconSize: 30,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: _imgWidth == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final squareSize = (constraints.maxWidth < constraints.maxHeight
                                  ? constraints.maxWidth
                                  : constraints.maxHeight) *
                              0.88;
                          final imgAspect = _imgWidth! / _imgHeight!;
                          double childW, childH;
                          if (imgAspect >= 1) {
                            childH = squareSize;
                            childW = squareSize * imgAspect;
                          } else {
                            childW = squareSize;
                            childH = squareSize / imgAspect;
                          }

                          if (!_centered) {
                            _centered = true;
                            final dx = (squareSize - childW) / 2;
                            final dy = (squareSize - childH) / 2;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _controller.value = Matrix4.identity()
                                ..translateByDouble(dx, dy, 0, 1);
                            });
                          }

                          return Container(
                            width: squareSize,
                            height: squareSize,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipRect(
                              child: RepaintBoundary(
                                key: _boundaryKey,
                                child: InteractiveViewer(
                                  transformationController: _controller,
                                  constrained: false,
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  boundaryMargin: EdgeInsets.zero,
                                  clipBehavior: Clip.hardEdge,
                                  child: SizedBox(
                                    width: childW,
                                    height: childH,
                                    child: Image.file(
                                      File(widget.imagePath),
                                      width: childW,
                                      height: childH,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Text(
                L10n.t('crop_hint'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
