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
  // 添加 CardService 实例
  final CardService _cardService = CardService();
  List<CardModel> _cards = [];
  bool _isLoading = true;
  bool _isGridView = true; // 默认使用网格视图
  
  @override
  void initState() {
    super.initState();
    _loadCards();
  }
  
  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 使用CardService获取卡片
      final cards = await _cardService.getCardsInBox(widget.cardBox.path);
      setState(() {
        _cards = cards;
      });
    } catch (e) {
      _showErrorSnackBar('加载卡片失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 删除临时方法，因为已经移到了CardService中
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cardBox.name} - 卡片'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
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
          : _cards.isEmpty
              ? _buildEmptyView()
              : _isGridView
                  ? _buildGridView()
                  : _buildListView(),
      // 添加浮动操作按钮
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCard,
        tooltip: '创建新卡片',
        child: const Icon(Icons.add),
      ),
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
  
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return _buildCardItem(card);
      },
    );
  }
  
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(card.title),
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
  
  Widget _buildCardItem(CardModel card) {
    return InkWell(
      onTap: () => _viewCard(card),
      child: Card(
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.note,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              card.title,
              style: const TextStyle(
                fontSize: 16,
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
class CardPreviewScreen extends StatelessWidget {
  final CardModel card;
  
  const CardPreviewScreen({
    super.key,
    required this.card,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(card.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Row(
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
                            card.title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Markdown内容
                          MarkdownBody(
                            data: card.content,
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
      ),
    );
  }
}