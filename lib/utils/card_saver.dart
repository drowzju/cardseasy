import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class CardSaver {
  static Future<bool> saveCard({
    required String title,
    required String content,
    required List<Map<String, String>> keyPoints,
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

      // 解析所有图片链接（新增正则匹配逻辑）
      final imageRegex = RegExp(r'!\[.*?\]\((.*?)\)');
      final Set<String> allImagePaths = {};
      
      // 收集内容中的图片链接
      void collectImagePaths(String text) {
        for (final match in imageRegex.allMatches(text)) {
          final url = match.group(1)!;
          if (url.startsWith('file://')) {
            allImagePaths.add(Uri.parse(url).toFilePath());
          }
        }
      }

      collectImagePaths(content);
      keyPoints.forEach((kp) => collectImagePaths(kp['content'] ?? ''));

      // 合并用户选择的图片和内容中的图片
      final Set<String> processedImages = {
        ...imageFiles,
        ...allImagePaths.where((p) => File(p).existsSync())
      };

      String updatedContent = content;
      final List<String> copiedImages = [];

      // 处理图片复制和路径更新（修改后的逻辑）
      for (String imagePath in processedImages) {
        final String fileName = path.basename(imagePath);
        final String destPath = path.join(imagesDirPath, fileName);

        // 仅当图片不在目标目录时复制
        if (!imagePath.startsWith(imagesDirPath)) {
          await File(imagePath).copy(destPath);
          copiedImages.add(destPath);
        }

        // 更新所有匹配的图片路径（改进替换逻辑）
        final patterns = [
          Uri.file(imagePath).toString(),  // file://路径
          imagePath,                        // 原始路径
          path.relative(imagePath, from: cardDirPath) // 相对路径
        ];

        for (final pattern in patterns) {
          updatedContent = updatedContent.replaceAllMapped(
            RegExp(r'!\[(.*?)\]\((' + RegExp.escape(pattern) + r')\)'),
            (match) => '![${match.group(1)}](images/$fileName)'
          );
        }
      }

      // 更新关键知识点中的图片路径
      final List<Map<String, String>> updatedKeyPoints = keyPoints.map((kp) {
        String updatedKeyPointContent = kp['content'] ?? '';
        
        for (String imagePath in imageFiles) {
          final String fileName = path.basename(imagePath);
          final String oldPath = 'file://$imagePath';
          final String newPath = 'images/$fileName';
          updatedKeyPointContent = updatedKeyPointContent.replaceAll(oldPath, newPath);
        }
        
        return {
          'title': kp['title'] ?? '',
          'content': updatedKeyPointContent,
        };
      }).toList();

      // 保存卡片内容
      final File contentFile = File(path.join(cardDirPath, 'content.md'));
      await contentFile.writeAsString(updatedContent);

      // 保存关键知识点
      for (int i = 0; i < updatedKeyPoints.length; i++) {
        final Map<String, String> kp = updatedKeyPoints[i];
        final String keyPointFileName = 'keypoint_${i + 1}.md';
        final File keyPointFile = File(path.join(cardDirPath, keyPointFileName));
        
        final String keyPointContent = '# ${kp['title']}\n\n${kp['content']}';
        await keyPointFile.writeAsString(keyPointContent);
      }

      // 保存元数据
      final File metaFile = File(path.join(cardDirPath, 'meta.json'));
      // 更新元数据包含图片信息（新增）
      final String metaContent = '{\n'
          '  "title": "$title",\n'
          '  "created": "${DateTime.now().toIso8601String()}",\n'
          '  "keyPoints": ${updatedKeyPoints.length},\n'
          '  "images": [\n'
          '    ${copiedImages.map((p) => '"${path.basename(p)}"').join(',\n    ')}\n'
          '  ]\n'
          '}';
      await metaFile.writeAsString(metaContent);

      return true;
    } catch (e) {
      showErrorDialog('保存卡片时出错: $e');
      return false;
    }
  }

  // 清理文件名，移除不允许的字符
  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}