// lib/utils/card_saver.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class CardSaver {
  static Future<bool> saveCard({
    required String title,
    required String fullMarkdown,
    required String? saveDirectory,
    required List<String> imageFiles,
    required Function(String) showErrorDialog,
  }) async {
    if (saveDirectory == null) {
      showErrorDialog('请先选择保存目录');
      return false;
    }

    if (title.trim().isEmpty) {
      showErrorDialog('请输入卡片标题');
      return false;
    }

    try {
      // 创建卡片目录
      final String cardDirName = _sanitizeFileName(title);
      final String cardDirPath = path.join(saveDirectory, cardDirName);
      final Directory cardDir = Directory(cardDirPath);

      if (!await cardDir.exists()) {
        await cardDir.create(recursive: true);
      }

      // 创建图片目录
      final String imagesDirPath = path.join(cardDirPath, 'images');
      final Directory imagesDir = Directory(imagesDirPath);

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // 复制图片到目标目录
      for (String imagePath in imageFiles) {
        final String fileName = path.basename(imagePath);
        final String destPath = path.join(imagesDirPath, fileName);
        
        if (!imagePath.startsWith(imagesDirPath)) {
          await File(imagePath).copy(destPath);
        }
      }

      // 保存为单个markdown文件
      final File cardFile = File(path.join(cardDirPath, '$cardDirName.md'));
      await cardFile.writeAsString(fullMarkdown);

      return true;
    } catch (e) {
      showErrorDialog('保存卡片时出错: $e');
      return false;
    }
  }

  // 清理文件名
  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}