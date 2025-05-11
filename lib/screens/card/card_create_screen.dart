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
    
    // 不要在这里调用 _addKeyPoint()
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 移除自动添加知识点的逻辑
    // 不再调用 Future.microtask(() => _addKeyPoint());
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
    // 创建一个局部控制器
    final TextEditingController dialogController = TextEditingController();
    
    // 显示标题输入对话框
    showDialog(
      context: context,
      barrierDismissible: false, // 用户必须输入标题或取消
      builder: (context) => AlertDialog(
        title: const Text('输入知识点标题'),
        content: TextField(
          controller: dialogController, // 使用局部控制器
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
        // 确保 title 不为空
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
          _currentKeyPointId = id; // 设置为当前编辑的关键知识点
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
                
                // 如果删除的是当前编辑的关键知识点，则重置当前编辑ID
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
      _currentEditMode = 'text'; // 重置编辑模式
      
      // 确保展开当前选中的知识点和关键知识点区域
      _keyPointExpandedStates[id] = true;
      _isKeyPointsExpanded = true;
      
      // 滚动到当前编辑区域
      _scrollToCurrentEditor();
    });
  }
  
  // 在切换到整体概念编辑时确保界面展开
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
    // 防止重复调用
    if (_isSelectingImage) return;
    _isSelectingImage = true;
    
    try {
      // 确定当前使用的控制器
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
              
              // 确保编辑区域保持展开状态
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
      // 确定当前使用的控制器
      final TextEditingController currentController = _currentKeyPointId != null
          ? _keyPointControllers[_currentKeyPointId]!
          : _contentController;
      
      // 保存当前编辑模式状态
      setState(() {
        _currentEditMode = format;
      });
      
      MarkdownFormatter.insertFormat(currentController, format);
      
      // 在格式应用后重置为文本模式
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
  
    // 收集所有关键知识点内容
    final List<Map<String, String>> keyPointsData = _keyPoints
        .where((kp) => kp.content.trim().isNotEmpty)
        .map((kp) => {
          'title': kp.title,
          'content': kp.content,
        })
        .toList();
  
    final bool success = await CardSaver.saveCard(
      title: _titleController.text,
      content: _contentController.text,
      keyPoints: keyPointsData,
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

  // 添加折叠状态控制变量
  bool _isConceptExpanded = true;
  bool _isKeyPointsExpanded = true;
  Map<String, bool> _keyPointExpandedStates = {};
  
  // 构建编辑区域
  Widget _buildEditorSection() {
    return Expanded(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 整体概念部分
            Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 整体概念标签 - 添加折叠功能
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
                          // 折叠/展开图标移到左侧
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
                                BlendMode.srcIn
                              ),
                            ),
                          ),
                          const Text('整体概念', 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const Spacer(),
                          // 当前编辑指示器
                          if (_currentKeyPointId == null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('当前编辑', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 使用AnimatedSize实现平滑的折叠/展开效果
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _isConceptExpanded ? Column(
                      children: [
                        // Markdown编辑工具栏
                        if (_currentKeyPointId == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: MarkdownToolbar(
                              currentEditMode: _currentEditMode,
                              onFormatSelected: _insertMarkdownFormat,
                              onImageSelected: _selectImage,
                            ),
                          ),
                        
                        // 整体概念输入框
                        // 在整体概念部分的GestureDetector中
                        GestureDetector(
                          onTap: () {
                            _switchToConceptEditing(); // 使用新方法替代直接设置状态
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              height: 150,
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
                        ),
                      ],
                    ) : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            
            // 关键知识点部分
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 关键知识点标签和添加按钮 - 添加折叠功能
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
                          // 折叠/展开图标移到左侧
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
                                BlendMode.srcIn
                              ),
                            ),
                          ),
                          const Text('关键知识点', 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const Spacer(),
                          // 添加按钮保持在右侧
                          IconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/add_key_point.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary,
                                BlendMode.srcIn
                              ),
                            ),
                            tooltip: '添加关键知识点',
                            onPressed: _addKeyPoint,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 使用AnimatedSize实现平滑的折叠/展开效果
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
    return Container(
      constraints: BoxConstraints(
        minHeight: 100,
        maxHeight: _keyPoints.isEmpty ? 100 : 400,
      ),
      child: _keyPoints.isEmpty
        ? const Center(child: Text('点击 + 添加关键知识点'))
        : ListView.builder(
            shrinkWrap: true,
            itemCount: _keyPoints.length,
            itemBuilder: (context, index) {
              final keyPoint = _keyPoints[index];
              final bool isSelected = _currentKeyPointId == keyPoint.id;
              
              // 确保每个知识点都有折叠状态
              _keyPointExpandedStates.putIfAbsent(keyPoint.id, () => true);
              final bool isExpanded = _keyPointExpandedStates[keyPoint.id]!;
              
              return Column(
                children: [
                  // 关键知识点标题栏
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
                          BlendMode.srcIn
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
                    title: Text(keyPoint.title.isNotEmpty 
                      ? keyPoint.title 
                      : '知识点 ${index + 1}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('当前编辑', style: TextStyle(fontSize: 12)),
                          ),
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/icons/remove_key_point.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.error,
                              BlendMode.srcIn
                            ),
                          ),
                          tooltip: '删除此知识点',
                          onPressed: () => _deleteKeyPoint(keyPoint.id),
                        ),
                      ],
                    ),
                    onTap: () {
                      _setCurrentKeyPoint(keyPoint.id);
                      // 如果折叠了，则展开
                      if (!isExpanded) {
                        setState(() {
                          _keyPointExpandedStates[keyPoint.id] = true;
                        });
                      }
                    },
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ),
                  
                  // 如果是当前选中的知识点且已展开，显示编辑器
                  if (isSelected && isExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          // Markdown工具栏
                          MarkdownToolbar(
                            currentEditMode: _currentEditMode,
                            onFormatSelected: _insertMarkdownFormat,
                            onImageSelected: _selectImage,
                          ),
                          
                          // 编辑框
                          Container(
                            height: 150,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: TextField(
                              controller: _keyPointControllers[keyPoint.id],
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: '输入关键知识点内容...',
                                border: OutlineInputBorder(),
                              ),
                              expands: true,
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
  
  // 添加滚动到当前编辑区域的方法
  void _scrollToCurrentEditor() {
    // 使用Future.delayed确保在布局完成后滚动
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      // 获取当前编辑区域的位置
      double targetPosition = 0;
      
      if (_currentKeyPointId == null) {
        // 如果是编辑整体概念，滚动到顶部
        targetPosition = 0;
      } else {
        // 如果是编辑关键知识点，找到对应的位置
        final int index = _keyPoints.indexWhere((kp) => kp.id == _currentKeyPointId);
        if (index != -1) {
          // 估算位置：每个知识点标题高度约50，加上前面整体概念的高度
          targetPosition = 200 + (index * 50);
        }
      }
      
      // 执行滚动，带有动画效果
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }



// 构建预览区域
Widget _buildPreviewSection() {
  return Expanded(
    child: Card(
      margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预览标题
            Text(
              '预览',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // 预览内容
            Expanded(
              child: _buildPreviewContent(),
            ),
          ],
        ),
      ),
    ),
  );
}

// 构建预览内容
Widget _buildPreviewContent() {
  // 确定当前预览的内容
  final String previewContent = _currentKeyPointId != null
      ? _keyPoints.firstWhere((kp) => kp.id == _currentKeyPointId).content
      : _contentController.text;
  
  return Markdown(
    data: previewContent,
    selectable: true,
    styleSheet: MarkdownStyleSheet(
      h1: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold),
      h2: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold),
      h3: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold),
      p: GoogleFonts.notoSans(fontSize: 16),
      code: GoogleFonts.firaCode(
        fontSize: 14,
        backgroundColor: Colors.grey.shade200,
      ),
      codeblockDecoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    imageBuilder: (uri, title, alt) {
      // 处理本地文件路径
      if (uri.scheme == 'file') {
        return Image.file(
          File(uri.toFilePath()),
          fit: BoxFit.contain,
        );
      }
      // 处理网络图片
      return Image.network(
        uri.toString(),
        fit: BoxFit.contain,
      );
    },
  );
}
}