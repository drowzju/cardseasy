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

class CardPreviewScreen extends StatefulWidget {
  final CardModel card;
  
  const CardPreviewScreen({
    super.key,
    required this.card,
  });
  
  @override
  State<CardPreviewScreen> createState() => _CardPreviewScreenState();
}

class _CardPreviewScreenState extends State<CardPreviewScreen> with SingleTickerProviderStateMixin {
  bool _isPreviewMode = true;
  late TabController _tabController;
  final Map<String, bool> _sectionVisibility = {};  // 用于存储每个章节的可见性状态
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _isPreviewMode = _tabController.index == 0;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 添加编辑按钮
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '编辑卡片',
            onPressed: _editCard,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.preview),
              text: '预览',
            ),
            Tab(
              icon: Icon(Icons.quiz),
              text: '自测',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPreviewTab(),
          _buildSelfTestTab(),
        ],
      ),
    );
  }
  
  Widget _buildPreviewTab() {
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 预览区域标题栏
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        MarkdownRenderer(
                          data: widget.card.content,
                          selectable: true,
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
            margin: const EdgeInsets.all(16.0),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 自测区域标题栏
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.quiz, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '自测模式',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
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
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Markdown内容
                        MarkdownRenderer(data: widget.card.content),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              ),
              child: Row(
                children: [
                  Icon(
                    _sectionVisibility['整体概念']! 
                        ? Icons.keyboard_arrow_down 
                        : Icons.keyboard_arrow_right,
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '整体概念',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
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
    final subSections = sections.where((s) => 
        s.parentTitle == sectionTitle && s.level == 2).toList();
    
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
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
          ...subSections.map((section) => _buildSubSection(section, sectionTitle)),
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
              _sectionVisibility[section.title] = !_sectionVisibility[section.title]!;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(
                  _sectionVisibility[section.title]! 
                      ? Icons.keyboard_arrow_down 
                      : Icons.keyboard_arrow_right,
                  color: _getSectionColor(parentTitle),
                ),
                const SizedBox(width: 8),
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
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _sectionVisibility[section.title] = !_sectionVisibility[section.title]!;
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
  
  // 获取不同部分的颜色
  Color _getSectionColor(String title) {
    switch (title) {
      case '整体概念':
        return Colors.purple.shade700;
      case '关键知识点':
        return Colors.blue.shade700;
      case '理解与关联':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
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
      .map((s) => KeyPoint(id: const Uuid().v4(), title: s.title, content: s.content))
      .toList();
  
  // 提取理解与关联
  final understandings = sections
      .where((s) => s.level == 2 && s.parentTitle == '理解与关联')
      .map((s) => Understanding(id: const Uuid().v4(), title: s.title, content: s.content))
      .toList();
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CardCreateScreen(
        initialSaveDirectory: path.dirname(widget.card.filePath),
        initialTitle: widget.card.title,
        initialContent: conceptContent,        
        initialKeyPoints: keyPoints,
        initialUnderstandings: understandings,
        isEditMode: true,
      ),
    ),
  ).then((_) {
    // 刷新卡片内容
    setState(() {});
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


