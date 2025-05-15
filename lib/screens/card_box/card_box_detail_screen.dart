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
import '../card/card_preview_screen.dart';  // 添加导入

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
              ? const EmptyCardView()
              : _isGridView
                  ? CardGridView(cards: _filteredCards, onCardTap: _viewCard)
                  : CardListView(cards: _filteredCards, onCardTap: _viewCard),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCard,
        tooltip: '创建新卡片',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _viewCard(CardModel card) {
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
