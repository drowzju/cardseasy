import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
          return Image.file(
            File(filePath),
            errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image),
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