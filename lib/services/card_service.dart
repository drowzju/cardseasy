import 'dart:io';
import '../models/card_model.dart';
import 'package:path/path.dart' as path;

class CardService {
  Future<bool> saveCard(CardModel card) async {
    try {
      final file = File(card.filePath);
      await file.writeAsString(card.toMarkdown());
      return true;
    } catch (e) {
      print('保存卡片失败: $e');
      return false;
    }
  }

  Future<CardModel?> loadCard(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final fileName = path.basename(filePath);
        final title = fileName.replaceAll('.md', '');
        
        return CardModel(
          title: title,
          content: content.replaceFirst('# $title', '').trim(),
          filePath: filePath,
        );
      }
      return null;
    } catch (e) {
      print('加载卡片失败: $e');
      return null;
    }
  }

  String generateFileName(String title) {
    // 移除不合法的文件名字符
    final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '$sanitizedTitle.md';
  }

  // 获取卡片盒内的所有卡片
  Future<List<CardModel>> getCardsInBox(String boxPath) async {
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
            // 读取MD文件内容
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
}