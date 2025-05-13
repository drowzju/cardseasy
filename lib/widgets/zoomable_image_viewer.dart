import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class ZoomableImageViewer extends StatefulWidget {
  final String imagePath;
  final double initialScale;
  final double minScale;
  final double maxScale;

  const ZoomableImageViewer({
    super.key,
    required this.imagePath,
    this.initialScale = 1.0,
    this.minScale = 0.5,
    this.maxScale = 3.0,
  });

  @override
  State<ZoomableImageViewer> createState() => _ZoomableImageViewerState();
}

class _ZoomableImageViewerState extends State<ZoomableImageViewer> {
  late double _scale;
  late double _minScale;
  late double _maxScale;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _minScale = widget.minScale;
    _maxScale = widget.maxScale;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          setState(() {
            // 计算缩放因子
            final double delta = pointerSignal.scrollDelta.dy > 0 ? -0.1 : 0.1;
            _scale = (_scale + delta).clamp(_minScale, _maxScale);
          });
        }
      },
      child: Center(
        child: Transform.scale(
          scale: _scale,
          child: Image.file(
            File(widget.imagePath),
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.broken_image, size: 100),
          ),
        ),
      ),
    );
  }
}