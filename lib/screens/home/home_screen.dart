import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/card_box.dart';
import '../../services/card_box_service.dart';
import '../card/card_create_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardBoxService _cardBoxService = CardBoxService();
  List<CardBox> _cardBoxes = [];
  CardBox? _selectedCardBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCardBoxes();
  }

  // 加载卡片盒列表
  Future<void> _loadCardBoxes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cardBoxes = await _cardBoxService.getCardBoxes();
      setState(() {
        _cardBoxes = cardBoxes;
        _selectedCardBox = cardBoxes.isNotEmpty ? cardBoxes.first : null;
      });
    } catch (e) {
      _showErrorDialog('加载卡片盒失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 创建新卡片盒
  Future<void> _createCardBox() async {
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择卡片盒目录',
    );

    if (selectedDirectory == null) {
      return;
    }

    try {
      final cardBox = await _cardBoxService.addCardBox(selectedDirectory);
      if (cardBox != null) {
        setState(() {
          _cardBoxes.add(cardBox);
          _selectedCardBox = cardBox;
        });
        _showSnackBar('卡片盒创建成功');
      } else {
        _showSnackBar('该目录已存在或无效');
      }
    } catch (e) {
      _showErrorDialog('创建卡片盒失败: $e');
    }
  }

  // 移除卡片盒
  Future<void> _removeCardBox(CardBox cardBox) async {
    final bool confirm = await _showConfirmDialog(
      '确认移除',
      '确定要移除卡片盒 "${cardBox.name}" 吗？\n注意：这只会从列表中移除，不会删除实际文件。',
    );

    if (!confirm) {
      return;
    }

    try {
      final success = await _cardBoxService.removeCardBox(cardBox.id);
      if (success) {
        setState(() {
          _cardBoxes.removeWhere((box) => box.id == cardBox.id);
          if (_selectedCardBox?.id == cardBox.id) {
            _selectedCardBox = _cardBoxes.isNotEmpty ? _cardBoxes.first : null;
          }
        });
        _showSnackBar('卡片盒已移除');
      } else {
        _showSnackBar('移除卡片盒失败');
      }
    } catch (e) {
      _showErrorDialog('移除卡片盒失败: $e');
    }
  }

  // 选择卡片盒
  void _selectCardBox(CardBox cardBox) {
    setState(() {
      _selectedCardBox = cardBox;
    });
  }

  // 创建新卡片
  void _navigateToCreateCard() {
    if (_selectedCardBox == null) {
      _showSnackBar('请先选择一个卡片盒');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardCreateScreen(
          initialSaveDirectory: _selectedCardBox!.path,
        ),
      ),
    );
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

  // 显示确认对话框
  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // 显示提示消息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('卡片易 - 卡片盒'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createCardBox,
            tooltip: '添加卡片盒',
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: _navigateToCreateCard,
            tooltip: '创建新卡片',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cardBoxes.isEmpty
              ? _buildEmptyState()
              : _buildCardBoxGrid(),
    );
  }

  // 构建空状态提示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '没有卡片盒',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('点击右上角的"+"按钮添加卡片盒'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createCardBox,
            icon: const Icon(Icons.add),
            label: const Text('添加卡片盒'),
          ),
        ],
      ),
    );
  }

  // 构建卡片盒网格
  Widget _buildCardBoxGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _cardBoxes.length,
      itemBuilder: (context, index) {
        final cardBox = _cardBoxes[index];
        final isSelected = _selectedCardBox?.id == cardBox.id;
        
        return InkWell(
          onTap: () => _selectCardBox(cardBox),
          child: Card(
            elevation: isSelected ? 8 : 2,
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder, size: 64),
                const SizedBox(height: 8),
                Text(
                  cardBox.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  cardBox.path,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeCardBox(cardBox),
                      tooltip: '移除卡片盒',
                    ),
                    IconButton(
                      icon: const Icon(Icons.note_add),
                      onPressed: () {
                        _selectCardBox(cardBox);
                        _navigateToCreateCard();
                      },
                      tooltip: '创建新卡片',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}