import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class CardSaver {
  static Future<bool> saveCard({
    required String title,
    required String content,
    List<String> keyPoints = const [],
    String? saveDirectory,
    List<String> imageFiles = const [],
    required Function(String) showErrorDialog,
  }) async {
    try {
      // 验证输入
      if (title.trim().isEmpty) {
        showErrorDialog('请输入卡片标题');
        return false;
      }

      if (content.trim().isEmpty && keyPoints.isEmpty) {
        showErrorDialog('请输入卡片内容或至少一个关键知识点');
        return false;
      }

      if (saveDirectory == null || saveDirectory.isEmpty) {
        showErrorDialog('请选择保存目录');
        return false;
      }

      // 创建卡片目录
      final String sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final String cardDirectory = path.join(saveDirectory, sanitizedTitle);
      
      final Directory directory = Directory(cardDirectory);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      // 保存内容文件
      final File contentFile = File(path.join(cardDirectory, 'content.md'));
      String fullContent = '# $title\n\n## 整体概念\n\n$content\n\n';
      
      // 添加关键知识点
      if (keyPoints.isNotEmpty) {
        fullContent += '## 关键知识点\n\n';
        for (int i = 0; i < keyPoints.length; i++) {
          fullContent += '### 知识点 ${i + 1}\n\n${keyPoints[i]}\n\n';
        }
      }
      
      await contentFile.writeAsString(fullContent);

      // 复制图片文件
      if (imageFiles.isNotEmpty) {
        final String imagesDirectory = path.join(cardDirectory, 'images');
        final Directory imagesDir = Directory(imagesDirectory);
        if (!imagesDir.existsSync()) {
          imagesDir.createSync();
        }

        for (String imagePath in imageFiles) {
          final File imageFile = File(imagePath);
          if (imageFile.existsSync()) {
            final String fileName = path.basename(imagePath);
            final String destPath = path.join(imagesDirectory, fileName);
            await imageFile.copy(destPath);
          }
        }
      }

      return true;
    } catch (e) {
      showErrorDialog('保存卡片时出错: $e');
      return false;
    }
  }
}