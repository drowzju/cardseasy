import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/card_box.dart';
import '../../services/card_box_service.dart';
import '../card/card_create_screen.dart';
import '../card_box/card_box_detail_screen.dart';

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
    // 添加窗口最大化代码
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maximizeWindow();
    });
  }

  // 窗口最大化方法
  void _maximizeWindow() {
    // Flutter Web或Desktop平台可以使用window对象
    // 对于移动平台，此方法不会有效果
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
    
    // 进入卡片盒详情页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardBoxDetailScreen(cardBox: cardBox),
      ),
    );
  }

  // 创建新卡片 - 这个方法可以保留，但不再直接从主界面调用
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCardBoxGrid(),
    );
  }

  // 构建卡片盒网格
  Widget _buildCardBoxGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 增加列数，使卡片盒变小
        childAspectRatio: 0.8, // 调整宽高比
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      // 添加1是为了在第一个位置放置添加按钮
      itemCount: _cardBoxes.length + 1,
      itemBuilder: (context, index) {
        // 第一个位置是添加按钮
        if (index == 0) {
          return _buildAddCardBoxButton();
        }
        
        // 实际卡片盒索引需要减1
        final cardBox = _cardBoxes[index - 1];
        final isSelected = _selectedCardBox?.id == cardBox.id;
        
        return InkWell(
          onTap: () => _selectCardBox(cardBox),
          child: Tooltip(
            message: cardBox.path, // 鼠标悬停时显示完整路径
            child: Card(
              elevation: isSelected ? 8 : 2,
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
              child: Stack(
                children: [
                  // 卡片盒主体内容 - 只显示文件夹名称
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        cardBox.name, // 只显示文件夹名称
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                  ),
                  
                  // 右下角删除按钮 - 改为蓝色
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline, 
                        size: 40,
                        color: Colors.blue, // 改为蓝色，与添加卡片盒按钮一致
                      ),
                      onPressed: () => _removeCardBox(cardBox),
                      tooltip: '移除卡片盒',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建添加卡片盒按钮
  Widget _buildAddCardBoxButton() {
    return InkWell(
      onTap: _createCardBox,
      child: Card(
        elevation: 2,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, size: 48, color: Colors.blue),
              const SizedBox(height: 8),
              const Text(
                '添加卡片盒',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}