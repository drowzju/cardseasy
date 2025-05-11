import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 导入提取的工具类
import '../../utils/markdown_formatter.dart';
import '../../utils/image_handler.dart';
import '../../utils/card_saver.dart';
import '../../widgets/markdown_toolbar.dart';
import '../../models/key_point.dart';

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

  // 关键知识点列表
  final List<KeyPoint> _keyPoints = [];
  // 关键知识点控制器映射
  final Map<String, TextEditingController> _keyPointControllers = {};
  // 当前编辑的关键知识点ID
  String? _currentKeyPointId;

  // 当前编辑模式
  String _currentEditMode = 'text'; // 'text', 'bold', 'italic', 'heading', 'list'

  // 添加滚动控制器
  final ScrollController _scrollController = ScrollController();

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
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();

    // 释放所有关键知识点控制器
    for (var controller in _keyPointControllers.values) {
      controller.dispose();
    }

    // 释放滚动控制器
    _scrollController.dispose();

    super.dispose();
  }

  // 添加关键知识点
  void _addKeyPoint() {
    final TextEditingController dialogController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('输入知识点标题'),
        content: TextField(
          controller: dialogController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入知识点标题',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final String title = dialogController.text;
              if (title.trim().isNotEmpty) {
                Navigator.pop(context, title);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入标题')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    ).then((title) {
      if (title != null && title.trim().isNotEmpty) {
        final String id = const Uuid().v4();
        final keyPoint = KeyPoint(id: id, title: title);
        final controller = TextEditingController();

        controller.addListener(() {
          final int index = _keyPoints.indexWhere((kp) => kp.id == id);
          if (index != -1) {
            setState(() {
              _keyPoints[index].content = controller.text;
            });
          }
        });

        setState(() {
          _keyPoints.add(keyPoint);
          _keyPointControllers[id] = controller;
          _currentKeyPointId = id;
          _isKeyPointsExpanded = true;
          _keyPointExpandedStates[id] = true;
        });

        // 添加延迟以确保布局已更新
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  // 删除关键知识点
  void _deleteKeyPoint(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个关键知识点吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              final controller = _keyPointControllers[id];
              if (controller != null) {
                controller.dispose();
                _keyPointControllers.remove(id);
              }

              setState(() {
                _keyPoints.removeWhere((kp) => kp.id == id);

                if (_currentKeyPointId == id) {
                  _currentKeyPointId = _keyPoints.isNotEmpty ? _keyPoints.first.id : null;
                }
              });
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 设置当前编辑的关键知识点
  void _setCurrentKeyPoint(String id) {
    setState(() {
      _currentKeyPointId = id;
      _currentEditMode = 'text';

      _keyPointExpandedStates[id] = true;
      _isKeyPointsExpanded = true;

      _scrollToCurrentEditor();
    });
  }

  // 切换到整体概念编辑
  void _switchToConceptEditing() {
    setState(() {
      _currentKeyPointId = null;
      _currentEditMode = 'text';
      _isConceptExpanded = true;
      _scrollToCurrentEditor();
    });
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

  // 添加标志防止重复调用图片选择
  bool _isSelectingImage = false;

  // 选择图片
  Future<void> _selectImage() async {
    if (_isSelectingImage) return;
    _isSelectingImage = true;

    try {
      final TextEditingController currentController = _currentKeyPointId != null
          ? _keyPointControllers[_currentKeyPointId]!
          : _contentController;

      await ImageHandler.selectAndProcessImage(
        contentController: currentController,
        saveDirectory: _saveDirectory,
        selectSaveDirectory: _selectSaveDirectory,
        imageFiles: _imageFiles,
        showErrorDialog: _showErrorDialog,
        updateImageFiles: (files) {
          if (mounted) {
            setState(() {
              _imageFiles.clear();
              _imageFiles.addAll(files);

              _isConceptExpanded = true;
              if (_currentKeyPointId != null) {
                _isKeyPointsExpanded = true;
                _keyPointExpandedStates[_currentKeyPointId!] = true;
              }
            });
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingImage = false;
        });
      }
    }
  }

  // 插入Markdown格式
  void _insertMarkdownFormat(String format) {
    try {
      final TextEditingController currentController = _currentKeyPointId != null
          ? _keyPointControllers[_currentKeyPointId]!
          : _contentController;

      setState(() {
        _currentEditMode = format;
      });

      MarkdownFormatter.insertFormat(currentController, format);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _currentEditMode = 'text';
          });
        }
      });
    } catch (e) {
      _showErrorDialog('格式化文本时出错: $e');
    }
  }

  // 显示格式提示
  void _showFormatHintDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: '了解', onPressed: () {}),
      ),
    );
  }

  // 保存卡片
  Future<void> _saveCard() async {
    setState(() {
      _isSaving = true;
    });

    final String fullMarkdown = _generateFullMarkdown();

    final bool success = await CardSaver.saveCard(
      title: _titleController.text,
      fullMarkdown: fullMarkdown,
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
          _buildHeaderSection(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEditorSection(),
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
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '卡片标题',
              border: OutlineInputBorder(),
            ),
            maxLength: 80,
          ),
          const SizedBox(height: 8),
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

  // 折叠状态变量
  bool _isConceptExpanded = true;
  bool _isKeyPointsExpanded = true;
  final Map<String, bool> _keyPointExpandedStates = {};

  // 构建编辑区域
  Widget _buildEditorSection() {
    return Expanded(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isConceptExpanded = !_isConceptExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: SvgPicture.asset(
                              _isConceptExpanded
                                  ? 'assets/icons/expand_less.svg'
                                  : 'assets/icons/expand_more.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const Text(
                            '整体概念',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _isConceptExpanded
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: MarkdownToolbar(
                                  currentEditMode: _currentEditMode,
                                  onFormatSelected: _insertMarkdownFormat,
                                  onImageSelected: _selectImage,
                                ),
                              ),
                              GestureDetector(
                                onTap: _switchToConceptEditing,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Container(
                                    height: 150,
                                    child: TextField(
                                      controller: _contentController,
                                      maxLines: null,
                                      expands: true,
                                      decoration: const InputDecoration(
                                        hintText:
                                            '在这里输入概念内容。支持文本和图片\n选中文字后点击上方按钮可应用粗体、斜体等格式',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isKeyPointsExpanded = !_isKeyPointsExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: SvgPicture.asset(
                              _isKeyPointsExpanded
                                  ? 'assets/icons/expand_less.svg'
                                  : 'assets/icons/expand_more.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const Text(
                            '关键知识点',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/add_key_point.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            tooltip: '添加关键知识点',
                            onPressed: _addKeyPoint,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _isKeyPointsExpanded ? _buildKeyPointsList() : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 提取关键知识点列表构建为单独方法
  Widget _buildKeyPointsList() {
    if (_keyPoints.isEmpty) {
      return const Center(child: Text('点击 + 添加关键知识点'));
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _keyPoints.length,
        itemBuilder: (context, index) {
          final keyPoint = _keyPoints[index];
          final bool isSelected = _currentKeyPointId == keyPoint.id;

          _keyPointExpandedStates.putIfAbsent(keyPoint.id, () => true);
          final bool isExpanded = _keyPointExpandedStates[keyPoint.id]!;

          return Column(
            children: [
              ListTile(
                leading: IconButton(
                  icon: SvgPicture.asset(
                    isExpanded
                        ? 'assets/icons/expand_less.svg'
                        : 'assets/icons/expand_more.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  tooltip: isExpanded ? '折叠' : '展开',
                  onPressed: () {
                    setState(() {
                      _keyPointExpandedStates[keyPoint.id] = !isExpanded;
                      if (!isExpanded && !isSelected) {
                        _setCurrentKeyPoint(keyPoint.id);
                      }
                    });
                  },
                ),
                title: Text(keyPoint.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/remove_key_point.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.error,
                          BlendMode.srcIn,
                        ),
                      ),
                      tooltip: '删除此知识点',
                      onPressed: () => _deleteKeyPoint(keyPoint.id),
                    ),
                  ],
                ),
                onTap: () {
                  _setCurrentKeyPoint(keyPoint.id);
                  if (!isExpanded) {
                    setState(() {
                      _keyPointExpandedStates[keyPoint.id] = true;
                    });
                  }
                },
                selected: isSelected,
                selectedTileColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ),
              if (isSelected && isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      MarkdownToolbar(
                        currentEditMode: _currentEditMode,
                        onFormatSelected: _insertMarkdownFormat,
                        onImageSelected: _selectImage,
                      ),
                      Container(
                        height: 150,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          controller: _keyPointControllers[keyPoint.id],
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            hintText: '输入关键知识点内容...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // 滚动到当前编辑区域
  void _scrollToCurrentEditor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? context = this.context;
      if (context == null || !_scrollController.hasClients) return;

      final RenderBox box = context.findRenderObject() as RenderBox;
      final Offset position = box.localToGlobal(Offset.zero);

      _scrollController.animateTo(
        position.dy.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/preview.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '预览',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Markdown(
                  data: _generateFullMarkdown(),
                  styleSheet: MarkdownStyleSheet(
                    h1: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold),
                    h2: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold),
                    h3: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold),
                    p: GoogleFonts.notoSans(fontSize: 16),
                  ),
                  imageBuilder: (uri, _, __) {
                    if (uri.scheme == 'file') {
                      return Image.file(File(uri.toFilePath()),
                          fit: BoxFit.contain);
                    }
                    return Image.network(uri.toString(), fit: BoxFit.contain);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 生成完整的Markdown内容
  String _generateFullMarkdown() {
    final StringBuffer markdown = StringBuffer();
    
    // 添加标题
    markdown.writeln('# ${_titleController.text}\n');
    
    // 添加整体概念
    if (_contentController.text.isNotEmpty) {
      markdown.writeln('# 整体概念\n');
      markdown.writeln('${_contentController.text}\n');
    }
    
    // 添加关键知识点
    if (_keyPoints.isNotEmpty) {
      markdown.writeln('# 关键知识点\n');
      
      for (final keyPoint in _keyPoints) {
        final String content = _keyPointControllers[keyPoint.id]?.text ?? '';
        if (content.isNotEmpty) {
          markdown.writeln('## ${keyPoint.title}\n');
          markdown.writeln('$content\n');
        }
      }
    }
    
    return markdown.toString();
  }
}