import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/gestures.dart';
import 'package:path/path.dart' as path;

class MarkdownRenderer extends StatelessWidget {
  final String data;
  final bool selectable;
  final TextStyle? textStyle;
  final MarkdownStyleSheet? customStyleSheet;
  final String? cardDirectoryPath; // 添加卡片目录路径参数
  
  const MarkdownRenderer({
    super.key,
    required this.data,
    this.selectable = true,
    this.textStyle,
    this.customStyleSheet,
    this.cardDirectoryPath, // 添加卡片目录路径参数
  });
  
  // 处理Obsidian风格的链接
  String _processObsidianLinks(String markdown) {
    // 匹配Obsidian风格的图片链接: ![[filename.png]]
    final RegExp obsidianImgRegExp = RegExp(r'!\[\[(.*?)\]\]');
    
    return markdown.replaceAllMapped(obsidianImgRegExp, (Match match) {
      final String fileName = match.group(1) ?? '';
      if (fileName.isEmpty) return match.group(0) ?? '';
      

      // 如果有卡片目录路径，使用相对路径，否则使用文件名
      if (cardDirectoryPath != null && cardDirectoryPath!.isNotEmpty) {
        final String imagePath = path.join(cardDirectoryPath!, fileName);
        final File imageFile = File(imagePath);
        if (imageFile.existsSync()) {
          // 转换为标准Markdown格式
          return '![${path.basenameWithoutExtension(fileName)}](${imageFile.uri.toString()})';
        }
      }
      
      // 如果找不到文件或没有目录路径，保持原样
      return match.group(0) ?? '';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // 处理Obsidian风格的链接
    final String processedData = _processObsidianLinks(data);
    
    return MarkdownBody(
      data: processedData,
      selectable: selectable,
      imageBuilder: (uri, title, alt) {
        try {
          String filePath;
          
          // 处理不同类型的路径
          if (uri.scheme == 'file') {
            // 文件协议路径
            filePath = uri.toFilePath();
          } else if (uri.path.isNotEmpty && cardDirectoryPath != null && cardDirectoryPath!.isNotEmpty) {
            // 相对路径，结合卡片目录
            filePath = path.join(cardDirectoryPath!, uri.path);
          } else {
            // 其他情况，直接使用路径
            filePath = uri.path;
          }
          
          // 检查文件是否存在
          final File imageFile = File(filePath);
          if (!imageFile.existsSync()) {
            return Text('图片不存在: $filePath');
          }
          
          return ZoomableImage(
            imageFile: imageFile,
            errorWidget: const Icon(Icons.broken_image),
          );
        } catch (e) {
          return Text('图片加载失败: ${uri.path} (错误: $e)');
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