import 'dart:io';

import '../models/key_point.dart';
import '../models/understanding.dart';
import 'package:uuid/uuid.dart';


class CardParser {
  // 从Markdown内容中解析关键知识点
  static List<KeyPoint> parseKeyPoints(String markdown) {
    List<KeyPoint> keyPoints = [];
    
    // 查找关键知识点部分
    final keyPointsRegex = RegExp(r'# 关键知识点\s*\n([\s\S]*?)(?=# |$)');
    final keyPointsMatch = keyPointsRegex.firstMatch(markdown);
    
    if (keyPointsMatch != null) {
      final keyPointsContent = keyPointsMatch.group(1) ?? '';
      
      // 查找每个关键知识点
      final keyPointRegex = RegExp(r'## (.*?)\s*\n([\s\S]*?)(?=## |$)');
      final keyPointMatches = keyPointRegex.allMatches(keyPointsContent);
      
      for (var match in keyPointMatches) {
        final title = match.group(1)?.trim() ?? '';
        final content = match.group(2)?.trim() ?? '';
        
        if (title.isNotEmpty) {
          keyPoints.add(KeyPoint(
            id: const Uuid().v4(),
            title: title,
            content: content,
          ));
        }
      }
    }
    
    return keyPoints;
  }
  
  // 从Markdown内容中解析理解与关联
  static List<Understanding> parseUnderstandings(String markdown) {
    List<Understanding> understandings = [];
    
    // 查找理解与关联部分
    final understandingsRegex = RegExp(r'# 理解与关联\s*\n([\s\S]*?)(?=# |$)');
    final understandingsMatch = understandingsRegex.firstMatch(markdown);
    
    if (understandingsMatch != null) {
      final understandingsContent = understandingsMatch.group(1) ?? '';
      
      // 查找每个理解与关联
      final understandingRegex = RegExp(r'## (.*?)\s*\n([\s\S]*?)(?=## |$)');
      final understandingMatches = understandingRegex.allMatches(understandingsContent);
      
      for (var match in understandingMatches) {
        final title = match.group(1)?.trim() ?? '';
        final content = match.group(2)?.trim() ?? '';
        
        if (title.isNotEmpty) {
          understandings.add(Understanding(
            id: const Uuid().v4(),
            title: title,
            content: content,
          ));
        }
      }
    }
    
    return understandings;
  }
  
  // 从Markdown内容中解析整体概念
  static String parseConceptContent(String markdown) {
    // 查找整体概念部分
    final conceptRegex = RegExp(r'# 整体概念\s*\n([\s\S]*?)(?=# |$)');
    final conceptMatch = conceptRegex.firstMatch(markdown);
    
    if (conceptMatch != null) {
      return conceptMatch.group(1)?.trim() ?? '';
    }
    
    return '';
  }

  static Future<String> getCardContent(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        return content;
      }
      return "";
    } catch (e) {
      print('加载卡片失败: $e');
      return "";
    }
  }
}