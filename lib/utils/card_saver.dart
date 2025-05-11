import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class CardSaver {
  // 保存卡片
  static Future<bool> saveCard({
    required String title,
    required String content,
    required String? saveDirectory,
    required List<String> imageFiles,
    required Function(String) showErrorDialog,
  }) async {
    if (title.isEmpty) {
      showErrorDialog('请输入卡片标题');
      return false;
    }

    if (saveDirectory == null) {
      showErrorDialog('请选择保存位置');
      return false;
    }

    try {
      final fileName = _generateFileName(title);
      final filePath = '$saveDirectory${Platform.pathSeparator}$fileName';
      
      // 替换图片路径为相对路径，以便在其他设备上也能正确显示
      String processedContent = content;
      
      // 替换所有绝对路径为相对路径
      for (String imagePath in imageFiles) {
        final String relativePath = 'images/${path.basename(imagePath)}';
        processedContent = processedContent.replaceAll(imagePath, relativePath);
      }
      
      final file = File(filePath);
      await file.writeAsString('# 整体概念\n\n$processedContent');
      
      return true;
    } catch (e) {
      showErrorDialog('发生错误: $e');
      return false;
    }
  }
  
  // 生成文件名
  static String _generateFileName(String title) {
    // 移除不合法的文件名字符
    final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '$sanitizedTitle.md';
  }
}