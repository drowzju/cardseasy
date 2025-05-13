import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as path;
import '../../models/card_box.dart';
import '../../models/card_model.dart';
import '../../services/card_service.dart';
import '../card/card_create_screen.dart';  // 添加导入

class CardBoxDetailScreen extends StatefulWidget {
  final CardBox cardBox;
  
  const CardBoxDetailScreen({
    super.key,
    required this.cardBox,
  });
  
  @override
  State<CardBoxDetailScreen> createState() => _CardBoxDetailScreenState();
}

class _CardBoxDetailScreenState extends State<CardBoxDetailScreen> {
  final CardService _cardService = CardService();
  List<CardModel> _allCards = []; // 所有卡片
  List<CardModel> _filteredCards = []; // 筛选后的卡片
  bool _isLoading = true;
  bool _isGridView = true;
  String _searchText = "";
  String _sortBy = "title"; // "title" 或 "createdAt"
  bool _sortAsc = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCards();
    _searchController.addListener(_onSearchChanged);
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final cards = await _cardService.getCardsInBox(widget.cardBox.path);
      if (mounted) {
        setState(() {
          _allCards = cards;
          _applyFilterAndSort();
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('加载卡片失败: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text;
      _applyFilterAndSort();
    });
  }

  void _applyFilterAndSort() {
    List<CardModel> cards = _allCards;
    // 搜索
    if (_searchText.isNotEmpty) {
      cards = cards
          .where((c) => c.title.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    }
    // 排序
    cards.sort((a, b) {
      int cmp;
      if (_sortBy == "title") {
        cmp = a.title.compareTo(b.title);
      } else {
        // 假设CardModel有createdAt字段（DateTime类型），否则请替换为合适字段
        cmp = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAsc ? cmp : -cmp;
    });
    _filteredCards = cards;
  }

  void _toggleSort(String field) {
    setState(() {
      if (_sortBy == field) {
        _sortAsc = !_sortAsc;
      } else {
        _sortBy = field;
        _sortAsc = true;
      }
      _applyFilterAndSort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cardBox.name} - 卡片'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 搜索框
          SizedBox(
            width: 180,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索卡片',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                isDense: true,
              ),
            ),
          ),
          // 排序按钮
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: '排序',
            onSelected: _toggleSort,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "title",
                child: Row(
                  children: [
                    const Text('按标题'),
                    if (_sortBy == "title")
                      Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 16)
                  ],
                ),
              ),
              PopupMenuItem(
                value: "createdAt",
                child: Row(
                  children: [
                    const Text('按创建时间'),
                    if (_sortBy == "createdAt")
                      Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 16)
                  ],
                ),
              ),
            ],
          ),
          // 视图切换开关
          Row(
            children: [
              const Text('列表'),
              Switch(
                value: _isGridView,
                onChanged: (value) {
                  setState(() {
                    _isGridView = value;
                  });
                },
              ),
              const Text('网格'),
              const SizedBox(width: 16),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCards,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredCards.isEmpty
              ? _buildEmptyView()
              : _isGridView
                  ? _buildGridView()
                  : _buildListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCard,
        tooltip: '创建新卡片',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),  // 进一步减少内边距
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,  // 每行显示8张卡片
        childAspectRatio: 0.9,  // 调整宽高比
        crossAxisSpacing: 4,  // 减少卡片间水平间距
        mainAxisSpacing: 4,  // 减少卡片间垂直间距
      ),
      itemCount: _filteredCards.length,
      itemBuilder: (context, index) {
        final card = _filteredCards[index];
        return _buildCardItem(card);
      },
    );
  }

  Widget _buildCardItem(CardModel card) {
    return InkWell(
      onTap: () => _viewCard(card),
      child: Card(
        elevation: 2,  // 恢复默认阴影
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.note,
              size: 40,  // 适当放大图标
              color: Colors.blue,
            ),
            const SizedBox(height: 8),  // 增加间距
            Text(
              card.title,
              style: const TextStyle(
                fontSize: 14,  // 适当放大字体
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(4),  // 减少内边距
      itemCount: _filteredCards.length,
      itemBuilder: (context, index) {
        final card = _filteredCards[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),  // 减少边距
          child: ListTile(
            dense: true,  // 启用紧凑模式
            title: Text(
              card.title,
              style: const TextStyle(fontSize: 14),  // 减小字体大小
            ),
            subtitle: Text('点击查看详情'),
            leading: const Icon(
              Icons.note,
              color: Colors.blue,
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _viewCard(card),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '没有卡片',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('在此目录中创建子文件夹作为卡片'),
        ],
      ),
    );
  }
  
  void _viewCard(CardModel card) {
    // 实现卡片预览功能
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardPreviewScreen(card: card),
      ),
    );
  }
  
  // 添加创建新卡片的方法
  void _createNewCard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardCreateScreen(
          initialSaveDirectory: widget.cardBox.path,
        ),
      ),
    ).then((_) {
      // 当从创建卡片页面返回时，刷新卡片列表
      _loadCards();
    });
  }
}

// 修改卡片预览屏幕
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
                        MarkdownBody(
                          data: widget.card.content,
                          selectable: true,
                          imageBuilder: (uri, title, alt) {
                            try {
                              final filePath = uri.toFilePath();
                              return Image.file(
                                File(filePath),
                                errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                              );
                            } catch (e) {
                              return Text('图片加载失败: ${uri.path}');
                            }
                          },
                          styleSheet: MarkdownStyleSheet(
                            h1: Theme.of(context).textTheme.headlineMedium,
                            h2: Theme.of(context).textTheme.titleLarge,
                            h3: Theme.of(context).textTheme.titleMedium,
                            p: Theme.of(context).textTheme.bodyLarge,
                            code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            ),
                            blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontStyle: FontStyle.italic,
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
                        // 解析后的自测内容
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
              child: MarkdownBody(
                data: conceptSection.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyLarge,
                ),
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
          if (subSections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '暂无内容',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: subSections.map((section) => 
                  _buildSubSection(section)).toList(),
              ),
            ),
        ],
      ),
    );
  }
  
  // 构建子条目
  Widget _buildSubSection(Section section) {
    // 确保每个子条目都有对应的可见性状态
    _sectionVisibility.putIfAbsent(section.title, () => false); // 默认隐藏
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // 子条目标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _sectionVisibility[section.title]! 
                        ? Icons.visibility 
                        : Icons.visibility_off,
                    color: _sectionVisibility[section.title]! 
                        ? Colors.blue.shade600 
                        : Colors.grey,
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
              child: MarkdownBody(
                data: section.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _sectionVisibility[section.title]!
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
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
  
  List<Section> _parseSections(String markdownContent) {
    final List<Section> sections = [];
    String currentParentTitle = '';
    String currentTitle = '';
    int currentLevel = 0;
    StringBuffer currentContent = StringBuffer();
    
    // 按行分割Markdown内容
    final lines = markdownContent.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.startsWith('# ')) {  // 一级标题
        // 保存之前的部分（如果有）
        if (currentTitle.isNotEmpty) {
          sections.add(Section(
            title: currentTitle, 
            content: currentContent.toString().trim(),
            parentTitle: currentParentTitle,
            level: currentLevel,
          ));
          currentContent.clear();
        }
        
        // 设置新的一级标题
        currentTitle = line.substring(2).trim();
        currentParentTitle = '';  // 一级标题没有父标题
        currentLevel = 1;
      } else if (line.startsWith('## ')) {  // 二级标题
        // 保存之前的部分（如果有）
        if (currentTitle.isNotEmpty) {
          sections.add(Section(
            title: currentTitle, 
            content: currentContent.toString().trim(),
            parentTitle: currentParentTitle,
            level: currentLevel,
          ));
          currentContent.clear();
        }
        
        // 设置新的二级标题
        currentTitle = line.substring(3).trim();
        
        // 查找最近的一级标题作为父标题
        for (int j = sections.length - 1; j >= 0; j--) {
          if (sections[j].level == 1) {
            currentParentTitle = sections[j].title;
            break;
          }
        }
        
        currentLevel = 2;
      } else {
        // 将内容行添加到当前内容中
        currentContent.writeln(line);
      }
    }
    
    // 添加最后一个部分（如果有）
    if (currentTitle.isNotEmpty) {
      sections.add(Section(
        title: currentTitle, 
        content: currentContent.toString().trim(),
        parentTitle: currentParentTitle,
        level: currentLevel,
      ));
    }
    
    return sections;
  }
}

class Section {
  final String title;
  final String content;
  final String parentTitle;
  final int level;
  
  Section({
    required this.title, 
    required this.content, 
    this.parentTitle = '',
    required this.level,
  });
}