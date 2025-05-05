import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class CardCreateScreen extends StatefulWidget {
  const CardCreateScreen({super.key});

  @override
  State<CardCreateScreen> createState() => _CardCreateScreenState();
}

class _CardCreateScreenState extends State<CardCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _saveDirectory;
  bool _isSaving = false;
  final List<String> _imageFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectSaveDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _saveDirectory = selectedDirectory;
      });
    }
  }

  // 使用 FilePicker 替代 ImagePicker
  Future<void> _selectImage() async {
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
        
        if (_saveDirectory == null) {
          await _selectSaveDirectory();
          if (_saveDirectory == null) return;
        }
        
        // 创建图片目录
        final String imageDir = '$_saveDirectory${Platform.pathSeparator}images';
        final Directory imageDirObj = Directory(imageDir);
        if (!await imageDirObj.exists()) {
          await imageDirObj.create(recursive: true);
        }
        
        // 复制图片到目标目录
        final String destPath = '$imageDir${Platform.pathSeparator}$newFileName';
        await File(filePath).copy(destPath);
        
        // 添加到图片列表
        setState(() {
          _imageFiles.add(destPath);
        });
        
        // 在文本中插入图片引用
        final String imageRef = '![图片](images/$newFileName)';
        final TextEditingValue currentValue = _contentController.value;
        final int cursorPos = currentValue.selection.baseOffset >= 0 
            ? currentValue.selection.baseOffset 
            : currentValue.text.length;
        final String newText = currentValue.text.substring(0, cursorPos) + 
                              imageRef + 
                              currentValue.text.substring(cursorPos);
        
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursorPos + imageRef.length),
        );
      }
    } catch (e) {
      print('选择图片失败: $e');
    }
  }

  Future<void> _saveCard() async {
    if (_titleController.text.isEmpty) {
      _showErrorDialog('请输入卡片标题');
      return;
    }

    if (_saveDirectory == null) {
      _showErrorDialog('请选择保存位置');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final fileName = _generateFileName(_titleController.text);
      final filePath = '$_saveDirectory${Platform.pathSeparator}$fileName';
      
      // 修改保存内容格式：不包含卡片标题，整体概念作为一级标题
      final file = File(filePath);
      await file.writeAsString('# 整体概念\n\n${_contentController.text}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('卡片保存成功')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog('发生错误: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _generateFileName(String title) {
    // 移除不合法的文件名字符
    final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '$sanitizedTitle.md';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建新卡片'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题输入框
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '卡片标题',
                border: OutlineInputBorder(),
                helperText: '最多输入80个字符（仅用于文件命名，不会记录在内容中）',
              ),
              maxLength: 80,
            ),
            const SizedBox(height: 16),
            
            // 保存位置选择
            Row(
              children: [
                Expanded(
                  child: Text(
                    '保存位置: ${_saveDirectory ?? "未选择"}',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectSaveDirectory,
                  child: const Text('选择文件夹'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 整体概念标签和图片选择按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('整体概念', style: TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.image),
                  tooltip: '插入图片',
                  onPressed: _selectImage,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 整体概念输入框
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: '在这里输入概念内容。支持文本和图片',
                  border: OutlineInputBorder(),
                ),
                expands: true,
              ),
            ),
            
            // 底部按钮区域
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveCard,
                    child: _isSaving 
                      ? const CircularProgressIndicator(strokeWidth: 2.0)
                      : const Text('保存'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}