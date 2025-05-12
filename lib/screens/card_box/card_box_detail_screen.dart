import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/card_box.dart';
import '../../models/card_model.dart';
import '../../services/card_service.dart';

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
      // 这里假设 CardService 有一个方法可以获取卡片盒内的所有卡片
      // 如果没有，您需要在 CardService 中添加相应的方法
      final cards = await _getCardsInBox(widget.cardBox.path);
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
  
  // 临时方法，用于获取卡片盒内的所有卡片
  // 在实际开发中，这个方法应该放在 CardService 中
  Future<List<CardModel>> _getCardsInBox(String boxPath) async {
    final directory = Directory(boxPath);
    final List<CardModel> cards = [];
    
    if (!await directory.exists()) {
      return [];
    }
    
    try {
      await for (var entity in directory.list()) {
        if (entity is Directory) {
          final dirName = entity.path.split(RegExp(r'[/\\]')).last;
          final mdFilePath = '${entity.path}/$dirName.md';
          final mdFile = File(mdFilePath);
          
          if (await mdFile.exists()) {
            // 读取 MD 文件内容
            final content = await mdFile.readAsString();
            // 创建卡片模型
            final card = CardModel(
              title: dirName,
              content: content,
              filePath: mdFilePath,
            );
            cards.add(card);
          }
        }
      }
    } catch (e) {
      print('获取卡片失败: $e');
    }
    
    return cards;
  }
  
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
    // 在迭代二中实现卡片预览功能
    _showErrorSnackBar('卡片预览功能将在下一次迭代中实现');
  }
}