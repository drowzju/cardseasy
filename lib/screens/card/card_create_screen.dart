import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // 当前编辑模式
  String _currentEditMode = 'text'; // 'text', 'bold', 'italic', 'heading', 'list'

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {
        // 触发重建以更新预览
      });
    });
  }

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
        
        // 在文本中插入图片引用 - 使用绝对路径以确保预览正常
        final String imageRef = '![图片]($destPath)';
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
      _showErrorDialog('选择图片失败: $e');
    }
  }

  // 插入Markdown格式文本
  void _insertMarkdownFormat(String format) {
    final TextEditingValue currentValue = _contentController.value;
    final int selectionStart = currentValue.selection.baseOffset;
    final int selectionEnd = currentValue.selection.extentOffset;
    
    if (selectionStart < 0 || selectionEnd < 0) {
      return;
    }
    
    String selectedText = '';
    String newText = '';
    String prefix = '';
    String suffix = '';
    
    // 获取选中的文本
    if (selectionStart != selectionEnd) {
      selectedText = currentValue.text.substring(selectionStart, selectionEnd);
    }
    
    // 根据不同的格式设置前缀和后缀
    switch (format) {
      case 'bold':
        prefix = '**';
        suffix = '**';
        break;
      case 'italic':
        prefix = '_';
        suffix = '_';
        break;
      case 'heading1':
        prefix = '# ';
        suffix = '';
        break;
      case 'heading2':
        prefix = '## ';
        suffix = '';
        break;
      case 'heading3':
        prefix = '### ';
        suffix = '';
        break;
      case 'list':
        prefix = '- ';
        suffix = '';
        break;
      case 'numbered_list':
        prefix = '1. ';
        suffix = '';
        break;
      case 'code':
        prefix = '`';
        suffix = '`';
        break;
      case 'codeblock':
        prefix = '```\n';
        suffix = '\n```';
        break;
      case 'link':
        prefix = '[';
        suffix = '](链接URL)';
        break;
      case 'table':
        prefix = '| 列1 | 列2 | 列3 |\n| --- | --- | --- |\n| 内容1 | 内容2 | 内容3 |\n';
        suffix = '';
        break;
      case 'quote':
        prefix = '> ';
        suffix = '';
        break;
      case 'hr':
        prefix = '\n---\n';
        suffix = '';
        break;
    }
    
    // 构建新文本
    if (selectedText.isEmpty) {
      newText = currentValue.text.substring(0, selectionStart) + 
                prefix + suffix + 
                currentValue.text.substring(selectionEnd);
      
      // 设置新的光标位置
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selectionStart + prefix.length),
      );
    } else {
      newText = currentValue.text.substring(0, selectionStart) + 
                prefix + selectedText + suffix + 
                currentValue.text.substring(selectionEnd);
      
      // 设置新的选择范围
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selectionStart + prefix.length,
          extentOffset: selectionStart + prefix.length + selectedText.length,
        ),
      );
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
      // 替换图片路径为相对路径，以便在其他设备上也能正确显示
      String content = _contentController.text;
      
      // 替换所有绝对路径为相对路径
      for (String imagePath in _imageFiles) {
        final String relativePath = 'images/${path.basename(imagePath)}';
        content = content.replaceAll(imagePath, relativePath);
      }
      
      final file = File(filePath);
      await file.writeAsString('# 整体概念\n\n$content');
      
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
      body: Column(
        children: [
          // 顶部区域：标题和保存位置
          Padding(
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
                  ),
                  maxLength: 80,
                ),
                const SizedBox(height: 8),
                
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
              ],
            ),
          ),
          
          // 主体区域：左侧编辑，右侧预览
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 左侧编辑区
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 整体概念标签
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('整体概念', 
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Markdown编辑工具栏
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.format_bold),
                                  tooltip: '粗体',
                                  onPressed: () => _insertMarkdownFormat('bold'),
                                  color: _currentEditMode == 'bold' ? Colors.blue : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.format_italic),
                                  tooltip: '斜体',
                                  onPressed: () => _insertMarkdownFormat('italic'),
                                  color: _currentEditMode == 'italic' ? Colors.blue : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.title),
                                  tooltip: '一级标题',
                                  onPressed: () => _insertMarkdownFormat('heading1'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.text_fields),
                                  tooltip: '二级标题',
                                  onPressed: () => _insertMarkdownFormat('heading2'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.format_list_bulleted),
                                  tooltip: '无序列表',
                                  onPressed: () => _insertMarkdownFormat('list'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.format_list_numbered),
                                  tooltip: '有序列表',
                                  onPressed: () => _insertMarkdownFormat('numbered_list'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.code),
                                  tooltip: '代码',
                                  onPressed: () => _insertMarkdownFormat('code'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.table_chart),
                                  tooltip: '表格',
                                  onPressed: () => _insertMarkdownFormat('table'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.link),
                                  tooltip: '链接',
                                  onPressed: () => _insertMarkdownFormat('link'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.format_quote),
                                  tooltip: '引用',
                                  onPressed: () => _insertMarkdownFormat('quote'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.horizontal_rule),
                                  tooltip: '分割线',
                                  onPressed: () => _insertMarkdownFormat('hr'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.image),
                                  tooltip: '插入图片',
                                  onPressed: _selectImage,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // 整体概念输入框
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 右侧预览区
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 预览标题
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            '预览',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        
                        // 预览内容
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            margin: const EdgeInsets.all(16.0),
                            child: Markdown(
                              data: '# 整体概念\n\n${_contentController.text}',
                              selectable: true,
                              // 添加图片构建器以处理本地图片
                              imageBuilder: (uri, title, alt) {
                                // 处理本地文件路径
                                if (uri.scheme == 'file' || uri.scheme == '') {
                                  String imagePath = uri.toString();
                                  // 如果是相对路径，转换为绝对路径
                                  if (!imagePath.startsWith('file:') && !path.isAbsolute(imagePath)) {
                                    if (_saveDirectory != null) {
                                      imagePath = '$_saveDirectory${Platform.pathSeparator}$imagePath';
                                    }
                                  }
                                  
                                  // 移除 file:// 前缀
                                  if (imagePath.startsWith('file://')) {
                                    imagePath = imagePath.substring(7);
                                  }
                                  
                                  // 检查文件是否存在
                                  final file = File(imagePath);
                                  if (file.existsSync()) {
                                    return Image.file(
                                      file,
                                      fit: BoxFit.contain,
                                    );
                                  } else {
                                    return Container(
                                      color: Colors.grey[300],
                                      height: 150,
                                      child: Center(
                                        child: Text('图片不存在: $imagePath', 
                                          style: const TextStyle(color: Colors.red),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
                                }
                                
                                // 处理网络图片
                                return Image.network(
                                  uri.toString(),
                                  fit: BoxFit.contain,
                                );
                              },
                              styleSheet: MarkdownStyleSheet(
                                h1: GoogleFonts.notoSerif(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo[800],
                                ),
                                h2: GoogleFonts.notoSerif(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo[700],
                                ),
                                h3: GoogleFonts.notoSerif(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo[600],
                                ),
                                p: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                strong: const TextStyle(fontWeight: FontWeight.bold),
                                em: const TextStyle(fontStyle: FontStyle.italic),
                                blockquote: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[700],
                                ),
                                blockSpacing: 16.0,
                                listIndent: 24.0,
                                listBullet: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                tableHead: const TextStyle(fontWeight: FontWeight.bold),
                                tableBorder: TableBorder.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                tableBody: GoogleFonts.notoSans(
                                  fontSize: 16,
                                ),
                                code: GoogleFonts.firaCode(
                                  fontSize: 14,
                                  backgroundColor: Colors.grey[200],
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 底部按钮区域
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
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
    );
  }
}