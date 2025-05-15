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
import '../../utils/dialog_utils.dart';
import '../../widgets/markdown_toolbar.dart';
import '../../widgets/key_point_list.dart';
import '../../widgets/key_points_header.dart';
import '../../widgets/concept_editor.dart'; // 添加这一行导入
import '../../models/key_point.dart';
import '../../models/understanding.dart';
import '../../widgets/understanding_header.dart';
import '../../widgets/understanding_list.dart';
import '../../widgets/card_preview_panel.dart';
import 'package:path/path.dart' as path;

class CardCreateScreen extends StatefulWidget {
  final String? initialSaveDirectory;
  final String? initialContent; // 添加初始内容
  final List<KeyPoint>? initialKeyPoints; // 添加初始关键知识点
  final List<Understanding>? initialUnderstandings; // 添加初始理解与关联
  final bool isEditMode; // 添加编辑模式标志

  const CardCreateScreen({
    super.key,
    this.initialSaveDirectory,
    this.initialContent,
    this.initialKeyPoints,
    this.initialUnderstandings,
    this.isEditMode = false, // 默认为创建模式
  });

  @override
  State<CardCreateScreen> createState() => _CardCreateScreenState();
}

class _CardCreateScreenState extends State<CardCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  // 移除 String? _saveDirectory; 变量
  bool _isSaving = false;

  // 关键知识点列表
  final List<KeyPoint> _keyPoints = [];
  // 关键知识点控制器映射
  final Map<String, TextEditingController> _keyPointControllers = {};
  // 当前编辑的关键知识点ID
  String? _currentKeyPointId;

  // 理解与关联列表
  final List<Understanding> _understandings = [];
  // 理解与关联控制器映射
  final Map<String, TextEditingController> _understandingControllers = {};
  // 当前编辑的理解与关联ID
  String? _currentUnderstandingId;
  // 理解与关联折叠状态
  bool _isUnderstandingExpanded = true;
  final Map<String, bool> _understandingExpandedStates = {};

  // 当前编辑模式
  String _currentEditMode =
      'text'; // 'text', 'bold', 'italic', 'heading', 'list'

  // 添加滚动控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    if (widget.isEditMode && widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }

    // 初始化关键知识点
    if (widget.isEditMode && widget.initialKeyPoints != null) {
      for (var keyPoint in widget.initialKeyPoints!) {
        final controller = TextEditingController(text: keyPoint.content);
        _keyPoints.add(keyPoint);
        _keyPointControllers[keyPoint.id] = controller;

        controller.addListener(() {
          final int index = _keyPoints.indexWhere((kp) => kp.id == keyPoint.id);
          if (index != -1) {
            setState(() {
              _keyPoints[index].content = controller.text;
            });
          }
        });
      }
    }

    // 初始化理解与关联
    if (widget.isEditMode && widget.initialUnderstandings != null) {
      for (var understanding in widget.initialUnderstandings!) {
        final controller = TextEditingController(text: understanding.content);
        _understandings.add(understanding);
        _understandingControllers[understanding.id] = controller;

        controller.addListener(() {
          final int index =
              _understandings.indexWhere((u) => u.id == understanding.id);
          if (index != -1) {
            setState(() {
              _understandings[index].content = controller.text;
            });
          }
        });
      }
    }

    _contentController.addListener(() {
      setState(() {
        // 触发重建以更新预览
      });
    });

    // 仅在创建模式下弹出标题输入对话框
    if (!widget.isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTitleInputDialog();
      });
    }
  }

  // 显示标题输入对话框
  void _showTitleInputDialog() {
    DialogUtils.showTextInputDialog(
      context: context,
      title: '输入卡片标题',
      hintText: '请输入卡片标题',
      maxLength: 80,
    ).then((title) {
      if (title == null || title.trim().isEmpty) {
        Navigator.pop(context); // 如果没有输入标题，返回上一页
        return;
      }
      setState(() {
        _titleController.text = title;
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

    // 释放所有理解与关联控制器
    for (var controller in _understandingControllers.values) {
      controller.dispose();
    }

    // 释放滚动控制器
    _scrollController.dispose();

    super.dispose();
  }

  // 添加关键知识点
  void _addKeyPoint() {
    DialogUtils.showTextInputDialog(
      context: context,
      title: '输入知识点标题',
      hintText: '请输入知识点标题',
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
    DialogUtils.showConfirmDialog(
      context: context,
      title: '确认删除',
      content: '确定要删除这个关键知识点吗？',
    ).then((confirmed) {
      if (confirmed) {
        final controller = _keyPointControllers[id];
        if (controller != null) {
          controller.dispose();
          _keyPointControllers.remove(id);
        }

        setState(() {
          _keyPoints.removeWhere((kp) => kp.id == id);

          if (_currentKeyPointId == id) {
            _currentKeyPointId =
                _keyPoints.isNotEmpty ? _keyPoints.first.id : null;
          }
        });
      }
    });
  }

  // 设置当前编辑的关键知识点
  void _setCurrentKeyPoint(String id) {
    setState(() {
      _currentKeyPointId = id;
      _currentUnderstandingId = null; // 清除理解与关联选择
      _currentEditMode = 'text';

      _keyPointExpandedStates[id] = true;
      _isKeyPointsExpanded = true;

      _scrollToCurrentEditor();
    });
  }

  // 添加理解与关联
  void _addUnderstanding() {
    DialogUtils.showTextInputDialog(
      context: context,
      title: '输入理解与关联标题',
      hintText: '请输入理解与关联标题',
    ).then((title) {
      if (title != null && title.trim().isNotEmpty) {
        final String id = const Uuid().v4();
        final understanding = Understanding(id: id, title: title);
        final controller = TextEditingController();

        controller.addListener(() {
          final int index = _understandings.indexWhere((u) => u.id == id);
          if (index != -1) {
            setState(() {
              _understandings[index].content = controller.text;
            });
          }
        });

        setState(() {
          _understandings.add(understanding);
          _understandingControllers[id] = controller;
          _currentUnderstandingId = id;
          _isUnderstandingExpanded = true;
          _understandingExpandedStates[id] = true;
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

  // 删除理解与关联
  void _deleteUnderstanding(String id) {
    DialogUtils.showConfirmDialog(
      context: context,
      title: '确认删除',
      content: '确定要删除这个理解与关联吗？',
    ).then((confirmed) {
      if (confirmed) {
        final controller = _understandingControllers[id];
        if (controller != null) {
          controller.dispose();
          _understandingControllers.remove(id);
        }

        setState(() {
          _understandings.removeWhere((u) => u.id == id);

          if (_currentUnderstandingId == id) {
            _currentUnderstandingId =
                _understandings.isNotEmpty ? _understandings.first.id : null;
          }
        });
      }
    });
  }

  // 设置当前编辑的理解与关联
  void _setCurrentUnderstanding(String id) {
    setState(() {
      _currentUnderstandingId = id;
      _currentKeyPointId = null; // 清除关键知识点选择
      _currentEditMode = 'text';

      _understandingExpandedStates[id] = true;
      _isUnderstandingExpanded = true;

      _scrollToCurrentEditor();
    });
  }

  // 切换到整体概念编辑
  void _switchToConceptEditing() {
    setState(() {
      _currentKeyPointId = null;
      _currentUnderstandingId = null;
      _currentEditMode = 'text';
      _isConceptExpanded = true;
      _scrollToCurrentEditor();
    });
  }

  // 添加标志防止重复调用图片选择
  bool _isSelectingImage = false;

  // 选择图片
  Future<void> _selectImage() async {
    if (_isSelectingImage) return;
    _isSelectingImage = true;

    try {
      TextEditingController currentController;

      if (_currentKeyPointId != null) {
        currentController = _keyPointControllers[_currentKeyPointId]!;
      } else if (_currentUnderstandingId != null) {
        currentController = _understandingControllers[_currentUnderstandingId]!;
      } else {
        currentController = _contentController;
      }

      await ImageHandler.selectAndProcessImage(
        contentController: currentController,
        saveDirectory: widget.initialSaveDirectory, // 使用传入的初始保存目录
        cardTitle: _titleController.text,
        showErrorDialog: _showErrorDialog,
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
      TextEditingController currentController;

      if (_currentKeyPointId != null) {
        currentController = _keyPointControllers[_currentKeyPointId]!;
      } else if (_currentUnderstandingId != null) {
        currentController = _understandingControllers[_currentUnderstandingId]!;
      } else {
        currentController = _contentController;
      }

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
    if ((!widget.isEditMode) && (_titleController.text.trim().isEmpty)) {
      _showErrorDialog('请输入卡片标题');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 如果是编辑模式，使用卡片盒目录而不是卡片目录作为保存目录
      String? saveDirectory = widget.initialSaveDirectory;

      if (widget.isEditMode && saveDirectory != null) {
        saveDirectory = path.dirname(saveDirectory);
      }

      final bool success = await CardSaver.saveCard(
        title: widget.isEditMode
            ? path.basename(widget.initialSaveDirectory!)
            : _titleController.text,
        fullMarkdown: _generateFullMarkdown(),
        saveDirectory: saveDirectory,
        showErrorDialog: _showErrorDialog,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('卡片保存成功')),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('保存卡片时出错: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
        title: Text(widget.isEditMode ? '编辑卡片' : '创建卡片'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEditorSection(),
          _buildPreviewSection(),
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

  // 移除 _buildSaveDirectorySection() 方法

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
            ConceptEditor(
              isExpanded: _isConceptExpanded,
              onToggleExpanded: () {
                setState(() {
                  _isConceptExpanded = !_isConceptExpanded;
                });
              },
              contentController: _contentController,
              currentEditMode: _currentEditMode,
              onFormatSelected: _insertMarkdownFormat,
              onImageSelected: _selectImage,
              onTap: _switchToConceptEditing,
              saveDirectory: widget.isEditMode
                  ? widget.initialSaveDirectory
                  : path.join(widget.initialSaveDirectory!,
                      _sanitizeFileName(_titleController.text)),
            ),
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyPointsHeader(
                    isExpanded: _isKeyPointsExpanded,
                    onToggleExpanded: () {
                      setState(() {
                        _isKeyPointsExpanded = !_isKeyPointsExpanded;
                      });
                    },
                    onAddKeyPoint: _addKeyPoint,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _isKeyPointsExpanded
                        ? KeyPointList(
                            keyPoints: _keyPoints,
                            keyPointExpandedStates: _keyPointExpandedStates,
                            keyPointControllers: _keyPointControllers,
                            currentKeyPointId: _currentKeyPointId,
                            currentEditMode: _currentEditMode,
                            onKeyPointSelected: _setCurrentKeyPoint,
                            onKeyPointDeleted: _deleteKeyPoint,
                            onKeyPointToggleExpanded: (id) {
                              setState(() {
                                _keyPointExpandedStates[id] =
                                    !(_keyPointExpandedStates[id] ?? true);
                                if (!(_keyPointExpandedStates[id] ?? true) &&
                                    _currentKeyPointId != id) {
                                  _setCurrentKeyPoint(id);
                                }
                              });
                            },
                            onFormatSelected: _insertMarkdownFormat,
                            onImageSelected: _selectImage,
                            saveDirectory: widget.isEditMode
                                ? widget.initialSaveDirectory
                                : path.join(widget.initialSaveDirectory!,
                                    _sanitizeFileName(_titleController.text)),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            // 添加理解与关联卡片
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UnderstandingHeader(
                    isExpanded: _isUnderstandingExpanded,
                    onToggleExpanded: () {
                      setState(() {
                        _isUnderstandingExpanded = !_isUnderstandingExpanded;
                      });
                    },
                    onAddUnderstanding: _addUnderstanding,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _isUnderstandingExpanded
                        ? UnderstandingList(
                            understandings: _understandings,
                            understandingExpandedStates:
                                _understandingExpandedStates,
                            understandingControllers: _understandingControllers,
                            currentUnderstandingId: _currentUnderstandingId,
                            currentEditMode: _currentEditMode,
                            onUnderstandingSelected: _setCurrentUnderstanding,
                            onUnderstandingDeleted: _deleteUnderstanding,
                            onUnderstandingToggleExpanded: (id) {
                              setState(() {
                                _understandingExpandedStates[id] =
                                    !(_understandingExpandedStates[id] ?? true);
                                if (!(_understandingExpandedStates[id] ??
                                        true) &&
                                    _currentUnderstandingId != id) {
                                  _setCurrentUnderstanding(id);
                                }
                              });
                            },
                            onFormatSelected: _insertMarkdownFormat,
                            onImageSelected: _selectImage,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    // 计算卡片目录路径
    String? cardDirPath;
    if (widget.isEditMode && widget.initialSaveDirectory != null) {
      // 编辑模式下，直接使用原始目录路径
      cardDirPath = widget.initialSaveDirectory;
    } else if (widget.initialSaveDirectory != null &&
        _titleController.text.isNotEmpty) {
      // 创建模式下，基于标题计算目录路径
      final String cardDirName = _sanitizeFileName(_titleController.text);
      cardDirPath = path.join(widget.initialSaveDirectory!, cardDirName);
    }

    return CardPreviewPanel(
      title: _titleController.text,
      content: _generateFullMarkdown(),
      cardDirectoryPath: cardDirPath,
    );
  }

  // 清理文件名（与 ImageHandler 中保持一致）
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  // 生成完整的Markdown内容
  String _generateFullMarkdown() {
    final StringBuffer markdown = StringBuffer();
    // 添加整体概念章节（无论是否有内容）
    markdown.writeln('# 整体概念\n');
    if (_contentController.text.isNotEmpty) {
      markdown.writeln('${_contentController.text}\n');
    }

    // 添加关键知识点章节（无论是否有内容）
    markdown.writeln('# 关键知识点\n');

    if (_keyPoints.isNotEmpty) {
      for (final keyPoint in _keyPoints) {
        final String content = _keyPointControllers[keyPoint.id]?.text ?? '';
        markdown.writeln('## ${keyPoint.title}\n');
        if (content.isNotEmpty) {
          markdown.writeln('$content\n');
        }
      }
    }

    // 添加理解与关联章节（无论是否有内容）
    markdown.writeln('# 理解与关联\n');

    if (_understandings.isNotEmpty) {
      for (final understanding in _understandings) {
        final String content =
            _understandingControllers[understanding.id]?.text ?? '';
        markdown.writeln('## ${understanding.title}\n');
        if (content.isNotEmpty) {
          markdown.writeln('$content\n');
        }
      }
    }

    return markdown.toString();
  }
}
