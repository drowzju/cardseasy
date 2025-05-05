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
}