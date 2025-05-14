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
// 修改可缩放图片组件
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
  bool _showControls = false;
  
  void _zoomIn() {
    setState(() {
      _scale = (_scale + 0.1).clamp(0.5, 3.0);
    });
  }
  
  void _zoomOut() {
    setState(() {
      _scale = (_scale - 0.1).clamp(0.5, 3.0);
    });
  }
  
  void _resetZoom() {
    setState(() {
      _scale = 1.0;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _showControls = true),
      onExit: (_) => setState(() => _showControls = false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 图片显示
          AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Image.file(
              widget.imageFile,
              errorBuilder: (context, error, stackTrace) => widget.errorWidget,
            ),
          ),
          
          // 缩放控制按钮
          if (_showControls)
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  // 放大按钮
                  FloatingActionButton.small(
                    heroTag: "zoom_in_${widget.imageFile.path}",
                    onPressed: _zoomIn,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    foregroundColor: Colors.black87,
                    elevation: 4,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  // 缩小按钮
                  FloatingActionButton.small(
                    heroTag: "zoom_out_${widget.imageFile.path}",
                    onPressed: _zoomOut,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    foregroundColor: Colors.black87,
                    elevation: 4,
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 8),
                  // 重置按钮
                  FloatingActionButton.small(
                    heroTag: "zoom_reset_${widget.imageFile.path}",
                    onPressed: _resetZoom,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    foregroundColor: Colors.black87,
                    elevation: 4,
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}