import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class ImageHandler {
  // 选择并处理图片
  static Future<void> selectAndProcessImage({
    required TextEditingController contentController,
    required String? saveDirectory,
    required Function() selectSaveDirectory,
    required List<String> imageFiles,
    required Function(String) showErrorDialog,
    required Function(List<String>) updateImageFiles,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        final String filePath = result.files.single.path!;
        final String fileName = path.basename(filePath);
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String newFileName = 'image_${timestamp}_$fileName';
        
        String? currentSaveDirectory = saveDirectory;
        if (currentSaveDirectory == null) {
          await selectSaveDirectory();
          currentSaveDirectory = saveDirectory;
          if (currentSaveDirectory == null) return;
        }
        
        // 创建图片目录
        final String imageDir = '$currentSaveDirectory${Platform.pathSeparator}images';
        final Directory imageDirObj = Directory(imageDir);
        if (!await imageDirObj.exists()) {
          await imageDirObj.create(recursive: true);
        }
        
        // 复制图片到目标目录
        final String destPath = '$imageDir${Platform.pathSeparator}$newFileName';
        await File(filePath).copy(destPath);
        
        // 添加到图片列表
        final List<String> updatedImageFiles = List.from(imageFiles);
        updatedImageFiles.add(destPath);
        updateImageFiles(updatedImageFiles);
        
        // 在文本中插入图片引用 - 使用绝对路径以确保预览正常
        final String imageRef = '![图片]($destPath)';
        final TextEditingValue currentValue = contentController.value;
        final int cursorPos = currentValue.selection.baseOffset >= 0 
            ? currentValue.selection.baseOffset 
            : currentValue.text.length;
        final String newText = currentValue.text.substring(0, cursorPos) + 
                              imageRef + 
                              currentValue.text.substring(cursorPos);
        
        contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursorPos + imageRef.length),
        );
      }
    } catch (e) {
      print('选择图片失败: $e');
      showErrorDialog('选择图片失败: $e');
    }
  }
}