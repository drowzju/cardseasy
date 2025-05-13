import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/gestures.dart';

class MarkdownRenderer extends StatelessWidget {
  final String data;
  final bool selectable;
  final TextStyle? textStyle;
  final MarkdownStyleSheet? customStyleSheet;
  
  const MarkdownRenderer({
    super.key,
    required this.data,
    this.selectable = true,
    this.textStyle,
    this.customStyleSheet,
  });
  
  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: selectable,
      imageBuilder: (uri, title, alt) {
        try {
          final filePath = uri.toFilePath();
          return ZoomableImage(
            imageFile: File(filePath),
            errorWidget: const Icon(Icons.broken_image),
          );
        } catch (e) {
          return Text('图片加载失败: ${uri.path}');
        }
      },
      styleSheet: customStyleSheet ?? _getDefaultStyleSheet(context),
    );
  }
  
  MarkdownStyleSheet _getDefaultStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      h1: Theme.of(context).textTheme.headlineMedium,
      h2: Theme.of(context).textTheme.titleLarge,
      h3: Theme.of(context).textTheme.titleMedium,
      p: textStyle ?? Theme.of(context).textTheme.bodyLarge,
      code: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.secondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

// 添加可缩放图片组件
class ZoomableImage extends StatefulWidget {
  final File imageFile;
  final Widget errorWidget;

  const ZoomableImage({
    super.key,
    required this.imageFile,
    required this.errorWidget,
  });

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  final TransformationController _transformationController = TransformationController();

  void _onDoubleTap() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_scale * details.scale).clamp(0.5, 3.0);
      _offset += details.focalPointDelta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      onScaleUpdate: _onScaleUpdate,
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            setState(() {
              final double delta = pointerSignal.scrollDelta.dy < 0 ? 0.1 : -0.1;
              _scale = (_scale + delta).clamp(0.5, 3.0);
            });
          }
        },
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Transform.translate(
            offset: _offset,
            child: Image.file(
              widget.imageFile,
              errorBuilder: (context, error, stackTrace) => widget.errorWidget,
            ),
          ),
        ),
      ),
    );
  }
}