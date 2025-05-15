import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/card_model.dart';
import '../../widgets/markdown_renderer.dart';
import 'card_create_screen.dart';
import '../../utils/card_parser.dart';
import 'package:uuid/uuid.dart';
import '../../models/key_point.dart';
import '../../models/understanding.dart';
import 'package:path/path.dart' as path;
import '../../utils/metadata_manager.dart';
import '../../models/card_metadata.dart';

class CardPreviewScreen extends StatefulWidget {
  final CardModel card;

  const CardPreviewScreen({
    super.key,
    required this.card,
  });

  @override
  State<CardPreviewScreen> createState() => _CardPreviewScreenState();
}

class _CardPreviewScreenState extends State<CardPreviewScreen> {
  bool _isPreviewMode = true; // 默认为预览模式
  final Map<String, bool> _sectionVisibility = {}; // 用于存储每个章节的可见性状态
  CardMetadata? _metadata; // 添加元数据属性

  @override
  void initState() {
    super.initState();
    // 加载卡片元数据
    _loadCardMetadata();
  }

  // 加载卡片元数据
  Future<void> _loadCardMetadata() async {
    final metadata = await MetadataManager.loadMetadata(
      cardFilePath: widget.card.filePath,
    );

    if (mounted) {
      setState(() {
        _metadata = metadata;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 预览按钮
          TextButton.icon(
            icon: Icon(
              Icons.preview,
              color: _isPreviewMode
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            label: Text(
              '预览',
              style: TextStyle(
                color: _isPreviewMode
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                fontWeight:
                    _isPreviewMode ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onPressed: () {
              setState(() {
                _isPreviewMode = true;
              });
            },
          ),
          // 自测按钮
          TextButton.icon(
            icon: Icon(
              Icons.quiz,
              color: !_isPreviewMode
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            label: Text(
              '自测',
              style: TextStyle(
                color: !_isPreviewMode
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                fontWeight:
                    !_isPreviewMode ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onPressed: () {
              setState(() {
                _isPreviewMode = false;
              });
            },
          ),
          // 编辑按钮
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '编辑卡片',
            onPressed: _editCard,
          ),
          const SizedBox(width: 8), // 右侧边距
        ],
      ),
      body: _isPreviewMode ? _buildPreviewTab() : _buildSelfTestTab(),
      // 添加悬浮按钮，仅在自测模式下显示
    );
  }

  // 显示自测评分对话框
  void _showSelfTestRatingDialog() {
    int selectedScore = _metadata?.selfTestScore ?? 5;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自测评价'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('请为您对这个知识点的掌握程度打分：'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$selectedScore',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        )),
                    const Text(' / 10'),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: selectedScore.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: selectedScore.toString(),
                  onChanged: (value) {
                    setState(() {
                      selectedScore = value.round();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('不熟悉', style: TextStyle(color: Colors.red)),
                    const Text('完全掌握', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _saveSelfTestScore(selectedScore);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 保存自测评分
  Future<void> _saveSelfTestScore(int score) async {
    final metadata = CardMetadata(
      selfTestScore: score,
      lastTestDate: DateTime.now(),
    );

    final success = await MetadataManager.saveMetadata(
      cardFilePath: widget.card.filePath,
      metadata: metadata,
    );

    if (success && mounted) {
      setState(() {
        _metadata = metadata;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('自测评分已保存')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存评分失败')),
      );
    }
  }

  Widget _buildPreviewTab() {
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 预览区域标题栏
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.preview, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '预览',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 预览内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.card.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        MarkdownRenderer(
                          data: widget.card.content,
                          selectable: true,
                          cardDirectoryPath: path.dirname(widget.card.filePath),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelfTestTab() {
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 自测区域标题栏
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.quiz, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '自测模式',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                    const Spacer(), // 添加空白区域，将评分和按钮推到右侧
                    // 显示当前评分（如果有）- 移到右侧
                    if (_metadata != null && _metadata!.selfTestScore > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: _showSelfTestRatingDialog,
                          icon: const Icon(Icons.star, size: 16),
                          label: Text(
                            '评分: ${_metadata!.selfTestScore}/10',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    // 添加自测评价按钮
                    ElevatedButton.icon(
                      onPressed: _showSelfTestRatingDialog,
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text(
                        '自测评价',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                const Divider(height: 1),
                // 自测内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题
                        Text(
                          widget.card.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        // 使用分段内容显示
                        _buildSelfTestContent(widget.card.content),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelfTestContent(String markdownContent) {
    // 解析markdown内容，提取各部分内容
    final sections = _parseSections(markdownContent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 整体概念区域
        _buildConceptSection(sections),

        const SizedBox(height: 16),

        // 关键知识点区域
        _buildPointsSection(sections, '关键知识点'),

        const SizedBox(height: 16),

        // 理解与关联区域
        _buildPointsSection(sections, '理解与关联'),
      ],
    );
  }

  // 构建整体概念部分
  Widget _buildConceptSection(List<Section> sections) {
    // 查找整体概念部分
    final conceptSection = sections.firstWhere(
      (s) => s.title == '整体概念',
      orElse: () => Section(title: '整体概念', content: '', level: 1),
    );

    // 确保整体概念有对应的可见性状态
    _sectionVisibility.putIfAbsent('整体概念', () => true); // 默认展开

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 整体概念标题栏
          InkWell(
            onTap: () {
              setState(() {
                _sectionVisibility['整体概念'] = !_sectionVisibility['整体概念']!;
              });
            },
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(7)),
              ),
              child: Row(
                children: [
                  Icon(
                    _sectionVisibility['整体概念']!
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.blue.shade700, // 将紫色改为蓝色
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '整体概念',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700, // 将紫色改为蓝色
                        ),
                  ),
                ],
              ),
            ),
          ),
          // 整体概念内容
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.all(16),
              child: MarkdownRenderer(
                data: conceptSection.content,
                textStyle: Theme.of(context).textTheme.bodyLarge,
                cardDirectoryPath: path.dirname(widget.card.filePath),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _sectionVisibility['整体概念']!
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // 构建知识点或理解关联部分
  Widget _buildPointsSection(List<Section> sections, String sectionTitle) {
    // 查找该部分下的所有子条目
    final subSections = sections
        .where((s) => s.parentTitle == sectionTitle && s.level == 2)
        .toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark,
                  color: sectionTitle == '关键知识点'
                      ? Colors.blue.shade700
                      : Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  sectionTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: sectionTitle == '关键知识点'
                            ? Colors.blue.shade700
                            : Colors.green.shade700,
                      ),
                ),
              ],
            ),
          ),
          // 子条目列表
          ...subSections
              .map((section) => _buildSubSection(section, sectionTitle)),
        ],
      ),
    );
  }

  // 构建子条目
  Widget _buildSubSection(Section section, String parentTitle) {
    // 确保每个章节都有对应的可见性状态
    _sectionVisibility.putIfAbsent(section.title, () => false); // 默认折叠

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分隔线
        const Divider(height: 1, thickness: 1),
        // 标题栏
        InkWell(
          onTap: () {
            setState(() {
              _sectionVisibility[section.title] =
                  !_sectionVisibility[section.title]!;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(
                  _sectionVisibility[section.title]!
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: _getSectionColor(parentTitle),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getSectionColor(parentTitle),
                        ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _sectionVisibility[section.title]!
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _sectionVisibility[section.title] =
                          !_sectionVisibility[section.title]!;
                    });
                  },
                  tooltip: _sectionVisibility[section.title]! ? '隐藏内容' : '显示内容',
                ),
              ],
            ),
          ),
        ),
        // 内容区域
        AnimatedCrossFade(
          firstChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(5),
              ),
            ),
            child: MarkdownRenderer(
              data: section.content,
              textStyle: Theme.of(context).textTheme.bodyLarge,
              cardDirectoryPath: path.dirname(widget.card.filePath),
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _sectionVisibility[section.title]!
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  // 根据章节类型获取颜色
  Color _getSectionColor(String sectionTitle) {
    switch (sectionTitle) {
      case '关键知识点':
        return Colors.blue.shade700; // 保持蓝色
      case '理解与关联':
        return Colors.green.shade700; // 保持绿色
      default:
        return Colors.blue.shade700; // 将紫色改为蓝色
    }
  }

  // 解析Markdown内容，提取各部分
  List<Section> _parseSections(String markdown) {
    final List<Section> sections = [];
    final RegExp headerRegex = RegExp(r'^(#+)\s+(.+)$', multiLine: true);

    // 分割内容为行
    final lines = markdown.split('\n');

    Section? currentSection;
    String? currentParentTitle;
    int currentLevel = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = headerRegex.firstMatch(line);

      if (match != null) {
        // 找到标题行
        final String headerMarks = match.group(1)!;
        final String title = match.group(2)!;
        final int level = headerMarks.length;

        // 如果是一级标题，可能是整体概念
        if (level == 1) {
          if (title == '整体概念') {
            currentParentTitle = null;
            currentLevel = 1;

            // 收集整体概念的内容
            final contentBuilder = StringBuffer();
            int j = i + 1;
            while (j < lines.length) {
              final nextLine = lines[j];
              final nextMatch = headerRegex.firstMatch(nextLine);

              if (nextMatch != null) {
                break; // 遇到下一个标题，结束收集
              }

              contentBuilder.writeln(nextLine);
              j++;
            }

            currentSection = Section(
              title: title,
              content: contentBuilder.toString().trim(),
              level: level,
            );

            sections.add(currentSection);
          } else if (title == '关键知识点' || title == '理解与关联') {
            currentParentTitle = title;
            currentLevel = 1;
          }
        } else if (level == 2 && currentParentTitle != null) {
          // 二级标题，属于关键知识点或理解与关联
          final contentBuilder = StringBuffer();
          int j = i + 1;
          while (j < lines.length) {
            final nextLine = lines[j];
            final nextMatch = headerRegex.firstMatch(nextLine);

            if (nextMatch != null) {
              break; // 遇到下一个标题，结束收集
            }

            contentBuilder.writeln(nextLine);
            j++;
          }

          currentSection = Section(
            title: title,
            content: contentBuilder.toString().trim(),
            level: level,
            parentTitle: currentParentTitle,
          );

          sections.add(currentSection);
        }
      }
    }

    return sections;
  }

// 添加编辑卡片方法
  void _editCard() {
    // 解析卡片内容
    final sections = _parseSections(widget.card.content);

    // 提取整体概念
    final conceptContent = sections
        .where((s) => s.level == 1 && s.title == '整体概念')
        .map((s) => s.content)
        .join('\n');

    // 提取关键知识点
    final keyPoints = sections
        .where((s) => s.level == 2 && s.parentTitle == '关键知识点')
        .map((s) =>
            KeyPoint(id: const Uuid().v4(), title: s.title, content: s.content))
        .toList();

    // 提取理解与关联
    final understandings = sections
        .where((s) => s.level == 2 && s.parentTitle == '理解与关联')
        .map((s) => Understanding(
            id: const Uuid().v4(), title: s.title, content: s.content))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardCreateScreen(
          initialSaveDirectory: path.dirname(widget.card.filePath),          
          initialContent: conceptContent,
          initialKeyPoints: keyPoints,
          initialUnderstandings: understandings,
          isEditMode: true,
        ),
      ),
    ).then((_) async {
      widget.card.content = await CardParser.getCardContent(widget.card.filePath);
      // 刷新卡片内容
      setState(()  {
      });
    });
  }
}

// 用于存储解析后的章节信息
class Section {
  final String title;
  final String content;
  final int level;
  final String? parentTitle;

  Section({
    required this.title,
    required this.content,
    required this.level,
    this.parentTitle,
  });
}
