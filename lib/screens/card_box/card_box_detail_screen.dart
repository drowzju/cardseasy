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
    // 解析markdown内容，提取关键知识点和理解与关联部分
    final sections = _parseSections(markdownContent);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCollapsibleSection(section.title, section.content),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
  
  List<Section> _parseSections(String markdownContent) {
    final List<Section> sections = [];
    final lines = markdownContent.split('\n');
    String currentTitle = '';
    StringBuffer currentContent = StringBuffer();
    
    for (final line in lines) {
      if (line.startsWith('## ')) {  // 二级标题作为章节标题
        if (currentTitle.isNotEmpty) {
          sections.add(Section(currentTitle, currentContent.toString().trim()));
          currentContent.clear();
        }
        currentTitle = line.substring(3).trim();
      } else if (currentTitle.isNotEmpty) {
        currentContent.writeln(line);
      }
    }
    
    if (currentTitle.isNotEmpty) {
      sections.add(Section(currentTitle, currentContent.toString().trim()));
    }
    
    return sections;
  }
  
  Widget _buildCollapsibleSection(String title, String content) {
    // 确保每个标题都有对应的可见性状态
    _sectionVisibility.putIfAbsent(title, () => false);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          InkWell(
            onTap: () {
              setState(() {
                _sectionVisibility[title] = !_sectionVisibility[title]!;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _sectionVisibility[title]! 
                        ? Icons.keyboard_arrow_down 
                        : Icons.keyboard_arrow_right,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_sectionVisibility[title]! 
                        ? Icons.visibility 
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _sectionVisibility[title] = !_sectionVisibility[title]!;
                      });
                    },
                    tooltip: _sectionVisibility[title]! ? '隐藏内容' : '显示内容',
                  ),
                ],
              ),
            ),
          ),
          // 内容区域
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(
                data: content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _sectionVisibility[title]! 
                ? CrossFadeState.showFirst 
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

// 添加Section类用于存储章节信息
class Section {
  final String title;
  final String content;
  
  Section(this.title, this.content);
}