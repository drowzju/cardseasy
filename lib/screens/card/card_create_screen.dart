import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

// 导入提取的工具类
import '../../utils/markdown_formatter.dart';
import '../../utils/image_handler.dart';
import '../../utils/card_saver.dart';
import '../../widgets/markdown_toolbar.dart';

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

  // 选择保存目录
  Future<void> _selectSaveDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _saveDirectory = selectedDirectory;
      });
    }
  }

  // 选择图片
  Future<void> _selectImage() async {
    await ImageHandler.selectAndProcessImage(
      contentController: _contentController,
      saveDirectory: _saveDirectory,
      selectSaveDirectory: _selectSaveDirectory,
      imageFiles: _imageFiles,
      showErrorDialog: _showErrorDialog,
      updateImageFiles: (files) {
        setState(() {
          _imageFiles.clear();
          _imageFiles.addAll(files);
        });
      },
    );
  }

  // 插入Markdown格式
  void _insertMarkdownFormat(String format) {
    MarkdownFormatter.formatText(
      controller: _contentController,
      format: format,
      showFormatHint: _showFormatHintDialog,
    );
    
    // 更新当前编辑模式
    setState(() {
      _currentEditMode = format;
    });
  }
  
  // 显示格式提示
  void _showFormatHintDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '了解',
          onPressed: () {},
        ),
      ),
    );
  }

  // 保存卡片
  Future<void> _saveCard() async {
    setState(() {
      _isSaving = true;
    });

    final bool success = await CardSaver.saveCard(
      title: _titleController.text,
      content: _contentController.text,
      saveDirectory: _saveDirectory,
      imageFiles: _imageFiles,
      showErrorDialog: _showErrorDialog,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('卡片保存成功')),
        );
        Navigator.pop(context);
      }
    }
  }

  // 显示错误对话框
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
          _buildHeaderSection(),
          
          // 主体区域：左侧编辑，右侧预览
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 左侧编辑区
                _buildEditorSection(),
                
                // 右侧预览区
                _buildPreviewSection(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveCard,
        icon: _isSaving 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(_isSaving ? '保存中...' : '保存卡片'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  // 构建头部区域
  Widget _buildHeaderSection() {
    return Padding(
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
    );
  }

  // 构建编辑区域
  Widget _buildEditorSection() {
    return Expanded(
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
                children: const [
                  Text('整体概念', 
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
              child: MarkdownToolbar(
                currentEditMode: _currentEditMode,
                onFormatSelected: _insertMarkdownFormat,
                onImageSelected: _selectImage,
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
                    hintText: '在这里输入概念内容。支持文本和图片\n选中文字后点击上方按钮可应用粗体、斜体等格式',
                    border: OutlineInputBorder(),
                  ),
                  expands: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建预览区域
  Widget _buildPreviewSection() {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预览标签
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('预览', 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
            
            // Markdown预览
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Markdown(
                  data: _contentController.text,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 16),
                    h1: GoogleFonts.notoSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: GoogleFonts.notoSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: GoogleFonts.notoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    code: GoogleFonts.firaCode(
                      backgroundColor: Colors.grey.shade200,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  imageBuilder: (uri, title, alt) {
                    return Image.file(
                      File(uri.toString()),
                      errorBuilder: (context, error, stackTrace) {
                        return Text('无法加载图片: ${uri.toString()}');
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}