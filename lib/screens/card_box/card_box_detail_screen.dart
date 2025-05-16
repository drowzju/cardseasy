import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as path;
import '../../models/card_box.dart';
import '../../models/card_model.dart';
import '../../services/card_service.dart';
import '../../widgets/card_grid_view.dart';
import '../../widgets/card_list_view.dart';
import '../../widgets/empty_card_view.dart';
import '../card/card_create_screen.dart';
import '../card/card_preview_screen.dart'; // 添加导入
import '../../utils/card_parser.dart';
import '../../utils/metadata_manager.dart';
import '../../models/card_metadata.dart';

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
  String _sortBy = "title"; // "title"、"createdAt" 或 "selfTestScore"
  bool _sortAsc = true;
  final TextEditingController _searchController = TextEditingController();
  // 存储卡片元数据的映射表
  final Map<String, CardMetadata?> _cardMetadataMap = {};

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
          _loadAllCardMetadata(); // 加载所有卡片的元数据
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

  // 加载所有卡片的元数据
  Future<void> _loadAllCardMetadata() async {
    for (var card in _allCards) {
      try {
        final metadata = await MetadataManager.loadMetadata(
          cardFilePath: card.filePath,
        );
        if (mounted) {
          setState(() {
            _cardMetadataMap[card.filePath] = metadata;
          });
        }
      } catch (e) {
        print('加载卡片元数据失败: ${e.toString()}');
      }
    }
    // 加载完元数据后应用筛选和排序
    if (mounted) {
      setState(() {
        _applyFilterAndSort();
      });
    }
  }

  // 获取卡片的自测评分，如果没有则返回默认值6
  int _getCardSelfTestScore(CardModel card) {
    final metadata = _cardMetadataMap[card.filePath];
    return metadata?.selfTestScore ?? 6; // 没有自测评分的默认为6分
  }

  void _applyFilterAndSort() {
    List<CardModel> cards = _allCards;
    // 搜索
    if (_searchText.isNotEmpty) {
      cards = cards
          .where(
              (c) => c.title.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    }
    // 排序
    cards.sort((a, b) {
      int cmp;
      if (_sortBy == "title") {
        cmp = a.title.compareTo(b.title);
      } else if (_sortBy == "createdAt") {
        // 按创建时间排序
        cmp = a.createdAt.compareTo(b.createdAt);
      } else if (_sortBy == "selfTestScore") {
        // 按自测评分排序，分数低的排前面
        cmp = _getCardSelfTestScore(a).compareTo(_getCardSelfTestScore(b));
      } else {
        // 默认按标题排序
        cmp = a.title.compareTo(b.title);
      }
      return _sortAsc ? cmp : -cmp;
    });
    _filteredCards = cards;
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text;
      _applyFilterAndSort();
    });
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
                      Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16)
                  ],
                ),
              ),
              PopupMenuItem(
                value: "createdAt",
                child: Row(
                  children: [
                    const Text('按创建时间'),
                    if (_sortBy == "createdAt")
                      Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16)
                  ],
                ),
              ),
              PopupMenuItem(
                value: "selfTestScore",
                child: Row(
                  children: [
                    const Text('按自测评价情况'),
                    if (_sortBy == "selfTestScore")
                      Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16)
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
              ? EmptyCardView()
              : _isGridView
                  ? CardGridView(
                      cards: _filteredCards,
                      onCardTap: _viewCard,
                      cardMetadataMap: _cardMetadataMap, // 添加元数据映射
                    )
                  : CardListView(
                      cards: _filteredCards,
                      onCardTap: _viewCard,
                      cardMetadataMap: _cardMetadataMap, // 添加元数据映射
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCard,
        tooltip: '创建新卡片',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _viewCard(CardModel card) async {
    card.content = await CardParser.getCardContent(card.filePath);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardPreviewScreen(card: card),
      ),
    );
  }

  void _createNewCard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardCreateScreen(
          initialSaveDirectory: widget.cardBox.path,
        ),
      ),
    ).then((_) {
      _loadCards();
    });
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
