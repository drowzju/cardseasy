import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class ImageHandler {
  /// 选择并处理图片
  static Future<void> selectAndProcessImage({
    required TextEditingController contentController,
    required String? saveDirectory,
    required List<String> imageFiles,
    required Function(String) showErrorDialog,
    required Function(List<String>) updateImageFiles,
  }) async {
    try {
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

      // 直接使用原始图片路径，不再复制到本地目录
      final String absolutePath = filePath;
      
      // 更新图片文件列表
      final List<String> updatedImageFiles = List<String>.from(imageFiles);
      updatedImageFiles.add(absolutePath);
      updateImageFiles(updatedImageFiles);
      
      // 在编辑器中插入Markdown格式的图片链接
      // 使用正确的URI格式，确保Windows路径能被正确解析
      final File imageFile = File(absolutePath);
      final String fileName = path.basename(absolutePath);
      
      // 创建正确的URI格式
      final Uri fileUri = imageFile.uri;
      final String markdownImageLink = '![${path.basenameWithoutExtension(fileName)}](${fileUri.toString()})';
      
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
}