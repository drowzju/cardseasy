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
  final String? cardDirectoryPath;
  
  const MarkdownRenderer({
    super.key,
    required this.data,
    this.selectable = true,
    this.textStyle,
    this.customStyleSheet,
    this.cardDirectoryPath,
  });
  
  // 处理Obsidian风格的链接
  String _processObsidianLinks(String markdown) {
    final RegExp obsidianImgRegExp = RegExp(r'!\[\[(.*?)\]\]');
    
    return markdown.replaceAllMapped(obsidianImgRegExp, (Match match) {
      final String fileName = match.group(1) ?? '';
      if (fileName.isEmpty) return match.group(0) ?? '';
      
      if (cardDirectoryPath != null && cardDirectoryPath!.isNotEmpty) {
        final String imagePath = path.join(cardDirectoryPath!, fileName);
        final File imageFile = File(imagePath);
        if (imageFile.existsSync()) {
          return '![${path.basenameWithoutExtension(fileName)}](${imageFile.uri.toString()})';
        }
      }
      
      return match.group(0) ?? '';
    });
  }
  
  // 检查文本是否包含高亮语法
  bool _hasHighlightSyntax(String text) {
    return text.contains(RegExp(r'==.+=='));
  }
  
  // 构建包含高亮的富文本
  Widget _buildRichTextWithHighlight(String text, BuildContext context) {
    final List<TextSpan> spans = [];
    final RegExp highlightRegExp = RegExp(r'==(.*?)==');
    final RegExp boldRegExp = RegExp(r'\*\*(.*?)\*\*');
    final RegExp italicRegExp = RegExp(r'_(.*?)_');
    
    // 简化处理：先处理高亮，再处理其他格式
    String processedText = text;
    final List<HighlightMatch> highlights = [];
    
    // 收集所有高亮匹配
    for (final Match match in highlightRegExp.allMatches(text)) {
      highlights.add(HighlightMatch(
        start: match.start,
        end: match.end,
        text: match.group(1) ?? '',
        originalMatch: match.group(0) ?? '',
      ));
    }
    
    // 从后往前替换，避免位置偏移
    highlights.sort((a, b) => b.start.compareTo(a.start));
    for (final highlight in highlights) {
      processedText = processedText.replaceRange(
        highlight.start,
        highlight.end,
        '🔆HIGHLIGHT:${highlight.text}🔆',
      );
    }
    
    // 现在处理所有格式
    _parseFormattedText(processedText, spans, context);
    
    return SelectableText.rich(
      TextSpan(children: spans),
      style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
    );
  }
  
  void _parseFormattedText(String text, List<TextSpan> spans, BuildContext context) {
    final RegExp combinedRegExp = RegExp(r'(🔆HIGHLIGHT:(.*?)🔆|\*\*(.*?)\*\*|_(.*?)_)');
    
    int lastEnd = 0;
    
    for (final Match match in combinedRegExp.allMatches(text)) {
      // 添加匹配前的普通文本
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
        ));
      }
      
      // 根据匹配类型添加格式化文本
      if (match.group(0)!.startsWith('🔆HIGHLIGHT:')) {
        // 高亮文本
        spans.add(TextSpan(
          text: match.group(2) ?? '',
          style: (textStyle ?? Theme.of(context).textTheme.bodyLarge!).copyWith(
            backgroundColor: Colors.yellow.withOpacity(0.3),
            color: Colors.black87,
          ),
        ));
      } else if (match.group(3) != null) {
        // 粗体文本
        spans.add(TextSpan(
          text: match.group(3) ?? '',
          style: (textStyle ?? Theme.of(context).textTheme.bodyLarge!).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(4) != null) {
        // 斜体文本
        spans.add(TextSpan(
          text: match.group(4) ?? '',
          style: (textStyle ?? Theme.of(context).textTheme.bodyLarge!).copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      }
      
      lastEnd = match.end;
    }
    
    // 添加剩余的普通文本
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
      ));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    String processedData = _processObsidianLinks(data);
    
    // 检查是否包含高亮语法
    if (_hasHighlightSyntax(processedData)) {
      // 对于包含高亮的文本，使用自定义富文本渲染
      return _buildRichTextWithHighlight(processedData, context);
    }
    
    // 对于不包含高亮的文本，使用标准 MarkdownBody
    return MarkdownBody(
      data: processedData,
      selectable: selectable,
      imageBuilder: (uri, title, alt) {
        try {
          String filePath;
          
          if (uri.scheme == 'file') {
            filePath = uri.toFilePath();
          } else if (uri.path.isNotEmpty && cardDirectoryPath != null && cardDirectoryPath!.isNotEmpty) {
            filePath = path.join(cardDirectoryPath!, uri.path);
          } else {
            filePath = uri.path;
          }
          
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
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

// 高亮匹配数据类
class HighlightMatch {
  final int start;
  final int end;
  final String text;
  final String originalMatch;
  
  HighlightMatch({
    required this.start,
    required this.end,
    required this.text,
    required this.originalMatch,
  });
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