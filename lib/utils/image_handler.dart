import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:pasteboard/pasteboard.dart';

class ImageHandler {
  /// 选择并处理图片
  static Future<void> selectAndProcessImage({
    required TextEditingController contentController,
    required String? saveDirectory,
    required String? cardTitle,    
    required Function(String) showErrorDialog,    
    bool useObsidianStyle = true, // 添加参数控制是否使用Obsidian风格
  }) async {
    try {
      // 检查保存目录和卡片标题
      if (saveDirectory == null) {
        showErrorDialog('请先选择保存目录');
        return;
      }
      
      if (cardTitle == null || cardTitle.trim().isEmpty) {
        showErrorDialog('请先输入卡片标题');
        return;
      }
      
      // 创建卡片目录
      final String cardDirName = _sanitizeFileName(cardTitle);
      final String cardDirPath = path.join(saveDirectory, cardDirName);
      final Directory cardDir = Directory(cardDirPath);
      
      if (!await cardDir.exists()) {
        await cardDir.create(recursive: true);
      }

      // 选择图片文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // 用户取消了选择
      }

      // 获取选中的文件路径
      final String? filePath = result.files.first.path;
      if (filePath == null) {
        showErrorDialog('无法获取所选图片的路径');
        return;
      }

      // 复制图片到卡片目录
      final String fileName = path.basename(filePath);
      final String destPath = path.join(cardDirPath, fileName);
      
      // 如果目标路径与源路径不同，则复制文件
      if (filePath != destPath) {
        await File(filePath).copy(destPath);
      }                  
      
      // 根据选择的风格创建图片链接
      String markdownImageLink;
      if (useObsidianStyle) {
        // Obsidian风格的链接
        markdownImageLink = '![[${fileName}]]';
      } else {
        // 标准Markdown风格的链接
        markdownImageLink = '![${path.basenameWithoutExtension(fileName)}](${fileName})';
      }
      
      // 获取当前光标位置
      final TextSelection selection = contentController.selection;
      final String currentText = contentController.text;
      
      // 在光标位置插入图片链接
      final String newText = currentText.replaceRange(
        selection.baseOffset, 
        selection.extentOffset, 
        markdownImageLink
      );
      
      // 更新编辑器内容
      contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset + markdownImageLink.length
        ),
      );
    } catch (e) {
      showErrorDialog('处理图片时出错: $e');
    }
  }
  
  // 清理文件名
  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  /// 处理粘贴的图片
  static Future<bool> handlePastedImage({
    required TextEditingController contentController,
    required String? saveDirectory,    
    bool useObsidianStyle = true,
  }) async {
    try {      
      // 尝试从剪贴板获取图片数据
      final Uint8List? imageBytes = await Pasteboard.image;
      if (imageBytes == null || imageBytes.isEmpty) {
        return false; // 剪贴板中没有图片数据
      }      
      // 检查保存目录和卡片标题
      if (saveDirectory == null) {        
        return false;
      }
      // 创建卡片目录      
      final Directory cardDir = Directory(saveDirectory);
      
      if (!await cardDir.exists()) {
        await cardDir.create(recursive: true);
      }

      // 生成唯一的文件名（使用时间戳）
      final String timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final String fileName = 'Pasted_image_$timestamp.png';
      final String destPath = path.join(saveDirectory, fileName);
      
      // 保存图片到卡片目录
      await File(destPath).writeAsBytes(imageBytes);
      
      // 根据选择的风格创建图片链接
      String markdownImageLink;
      if (useObsidianStyle) {
        // Obsidian风格的链接
        markdownImageLink = '![[${fileName}]]';
      } else {
        // 标准Markdown风格的链接
        markdownImageLink = '![${path.basenameWithoutExtension(fileName)}](${fileName})';
      }
      
      // 获取当前光标位置
      final TextSelection selection = contentController.selection;
      final String currentText = contentController.text;
      
      // 在光标位置插入图片链接
      final String newText = currentText.replaceRange(
        selection.baseOffset, 
        selection.extentOffset, 
        markdownImageLink
      );
      
      // 更新编辑器内容
      contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset + markdownImageLink.length
        ),
      );
      
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}