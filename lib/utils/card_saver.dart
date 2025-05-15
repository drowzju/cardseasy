// lib/utils/card_saver.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class CardSaver {
  static Future<bool> saveCard({
    required String title,
    required String fullMarkdown,
    required String? saveDirectory,    
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

      // 更新Markdown中的图片链接
      String updatedMarkdown = _updateImageLinks(fullMarkdown);
      
      // 转换为Obsidian风格的链接
      updatedMarkdown = _convertToObsidianLinks(updatedMarkdown);

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
  static String _updateImageLinks(String markdown) {
    // 处理标准Markdown格式的图片链接
    String updatedMarkdown = _updateStandardImageLinks(markdown);
    
    // 处理Obsidian风格的图片链接
    updatedMarkdown = _updateObsidianImageLinks(updatedMarkdown);
    
    return updatedMarkdown;
  }
  
  // 处理标准Markdown格式的图片链接
  static String _updateStandardImageLinks(String markdown) {
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
      
      // 直接使用文件名作为相对路径
      return '![$altText]($fileName)';
    });
  }
  
  // 处理Obsidian风格的图片链接
  static String _updateObsidianImageLinks(String markdown) {
    // 匹配Obsidian风格的图片链接: ![[filename.png]]
    final RegExp obsidianImgRegExp = RegExp(r'!\[\[(.*?)\]\]');
    
    return markdown.replaceAllMapped(obsidianImgRegExp, (Match match) {
      final String fileName = match.group(1) ?? '';
      
      // 已经是正确的格式，保持不变
      return '![[${fileName}]]';
    });
  }
  
  // 将标准Markdown链接转换为Obsidian风格
  static String _convertToObsidianLinks(String markdown) {
    // 匹配标准Markdown中的图片链接: ![alt](filename.png)
    final RegExp imgRegExp = RegExp(r'!\[(.*?)\]\((.*?)\)');
    
    return markdown.replaceAllMapped(imgRegExp, (Match match) {
      String imgPath = match.group(2) ?? '';
      
      // 如果是文件协议路径，提取文件名
      if (imgPath.startsWith('file:///')) {
        imgPath = path.basename(Uri.decodeFull(imgPath.substring(8)));
      } else if (imgPath.startsWith('file://')) {
        imgPath = path.basename(Uri.decodeFull(imgPath.substring(7)));
      } else if (!imgPath.contains('/') && !imgPath.contains('\\')) {
        // 如果是简单文件名，直接使用
        // 不做处理
      } else {
        // 其他情况，提取文件名
        imgPath = path.basename(imgPath);
      }
      
      // 转换为Obsidian风格
      return '![[${imgPath}]]';
    });
  }

  // 清理文件名
  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}