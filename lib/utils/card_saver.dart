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

      // 更新Markdown中的图片链接，传入绝对路径
      String updatedMarkdown = _updateImageLinks(fullMarkdown, imageFiles, imagesDirPath);

      // 保存为单个markdown文件
      final File cardFile = File(path.join(cardDirPath, '$cardDirName.md'));
      await cardFile.writeAsString(updatedMarkdown);

      return true;
    } catch (e) {
      showErrorDialog('保存卡片时出错: $e');
      return false;
    }
  }

  // 更新Markdown中的图片链接
  static String _updateImageLinks(String markdown, List<String> imageFiles, String imagesDirPath) {
    // 创建文件名到路径的映射，便于快速查找
    final Map<String, String> fileNameToPath = {};
    for (String imagePath in imageFiles) {
      final String fileName = path.basename(imagePath);
      fileNameToPath[fileName] = imagePath;
    }

    // 匹配Markdown中的图片链接: ![alt](path)
    final RegExp imgRegExp = RegExp(r'!\[(.*?)\]\((.*?)\)');
    
    return markdown.replaceAllMapped(imgRegExp, (Match match) {
      final String altText = match.group(1) ?? '';
      String imgPath = match.group(2) ?? '';
      
      // 处理file:///前缀
      if (imgPath.startsWith('file:///')) {
        imgPath = imgPath.substring(8); // 去除file:///
      } else if (imgPath.startsWith('file://')) {
        imgPath = imgPath.substring(7); // 去除file://
      }
      
      // 处理URL编码
      try {
        imgPath = Uri.decodeFull(imgPath);
      } catch (e) {
        // 解码失败，保持原样
      }
      
      // 获取文件名
      final String fileName = path.basename(imgPath);
      
      // 检查这个文件是否在我们的图片列表中（通过文件名比较）
      if (fileNameToPath.containsKey(fileName)) {
        // 使用绝对路径
        final String absolutePath = path.join(imagesDirPath, fileName);
        // 直接使用新的编码方法
        return '![$altText](${_encodePathForMarkdown(absolutePath)})';
      }
      
      // 如果找不到精确匹配，尝试通过部分匹配查找
      for (String key in fileNameToPath.keys) {
        if (key.contains(fileName) || fileName.contains(key)) {
          // 使用绝对路径
          final String absolutePath = path.join(imagesDirPath, key);
          // 直接使用新的编码方法
          return '![$altText](${_encodePathForMarkdown(absolutePath)})';
        }
      }
      
      // 如果不在图片列表中，保持原样
      return match.group(0) ?? '';
    });
  }

  // 对路径进行编码，适用于Markdown中的图片链接
  static String _encodePathForMarkdown(String pathStr) {
    // 首先确保使用Windows风格的反斜杠
    String normalizedPath = pathStr.replaceAll('/', '\\');
    
    // 处理驱动器部分（如D:）
    final RegExp driveRegex = RegExp(r'^([A-Za-z]:)(.*)$');
    final Match? driveMatch = driveRegex.firstMatch(normalizedPath);
    
    if (driveMatch != null) {
      String drive = driveMatch.group(1) ?? '';
      String remainingPath = driveMatch.group(2) ?? '';
      
      // 确保驱动器后有斜杠
      if (!remainingPath.startsWith('\\')) {
        remainingPath = '\\' + remainingPath;
      }
      
      // 将路径拆分为组件
      List<String> components = remainingPath.split('\\');
      components = components.where((c) => c.isNotEmpty).toList();
      
      // 对每个组件进行编码
      for (int i = 0; i < components.length; i++) {
        components[i] = Uri.encodeComponent(components[i]);
      }
      
      // 重新组合路径，使用正斜杠（URI标准）
      // 注意：驱动器后必须有斜杠
      return 'file:///${drive}/${components.join('/')}';
    } else {
      // 如果没有驱动器部分，直接编码整个路径
      return 'file:///${Uri.encodeComponent(normalizedPath).replaceAll('%5C', '/')}';
    }
  }

  // 清理文件名
  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}