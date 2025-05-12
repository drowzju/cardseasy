import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_box.dart';

class CardBoxService {
  static const String _cardBoxesKey = 'card_boxes';
  List<CardBox> _cardBoxes = [];
  
  // 获取所有卡片盒
  Future<List<CardBox>> getCardBoxes() async {
    if (_cardBoxes.isNotEmpty) {
      return _cardBoxes;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList(_cardBoxesKey) ?? [];
    
    _cardBoxes = paths
        .map((path) => CardBox.fromPath(path))
        .where((box) => Directory(box.path).existsSync())
        .toList();
    
    return _cardBoxes;
  }
  
  // 添加卡片盒
  Future<CardBox?> addCardBox(String directoryPath) async {
    final directory = Directory(directoryPath);
    
    // 检查目录是否存在
    if (!await directory.exists()) {
      return null;
    }
    
    // 创建卡片盒对象
    final cardBox = CardBox.fromPath(directoryPath);
    
    // 检查是否已存在
    final existingBoxes = await getCardBoxes();
    if (existingBoxes.any((box) => box.path == cardBox.path)) {
      return null;
    }
    
    // 添加到列表
    _cardBoxes.add(cardBox);
    
    // 保存到SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final paths = _cardBoxes.map((box) => box.path).toList();
    await prefs.setStringList(_cardBoxesKey, paths);
    
    return cardBox;
  }
  
  // 移除卡片盒
  Future<bool> removeCardBox(String cardBoxId) async {
    final existingBoxes = await getCardBoxes();
    final initialLength = existingBoxes.length;
    
    _cardBoxes = existingBoxes.where((box) => box.id != cardBoxId).toList();
    
    if (_cardBoxes.length == initialLength) {
      return false;
    }
    
    // 保存到SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final paths = _cardBoxes.map((box) => box.path).toList();
    await prefs.setStringList(_cardBoxesKey, paths);
    
    return true;
  }
  
  // 获取默认卡片盒目录
  Future<String> getDefaultCardBoxDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'CardBoxes');
  }
}