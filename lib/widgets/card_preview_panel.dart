import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';
import '../widgets/markdown_renderer.dart';
import 'package:path/path.dart' as path;

class CardPreviewPanel extends StatelessWidget {
  final String title;
  final String content;  
  final String? cardDirectoryPath; // 添加卡片目录路径参数
  
  const CardPreviewPanel({
    super.key,
    required this.title,
    required this.content,    
    this.cardDirectoryPath, // 添加卡片目录路径参数
  });
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.fromLTRB(8, 16, 16, 16),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预览区域标题栏
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.preview, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '预览',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 预览内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 16),
                    MarkdownRenderer(
                      data: content,
                      selectable: true,
                      cardDirectoryPath: cardDirectoryPath, // 传递卡片目录路径
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}