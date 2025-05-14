import 'dart:io';
import 'dart:typed_data';
import '../models/card_metadata.dart';
import 'package:path/path.dart' as path;

class MetadataManager {
  // 保存卡片元数据
  static Future<bool> saveMetadata({
    required String cardFilePath,
    required CardMetadata metadata,
  }) async {
    try {
      // 获取元数据文件路径
      final String metaFilePath = _getMetaFilePath(cardFilePath);
      
      // 将元数据转换为二进制
      final Uint8List binaryData = metadata.toBinary();
      
      // 写入文件
      final File metaFile = File(metaFilePath);
      await metaFile.writeAsBytes(binaryData);
      
      return true;
    } catch (e) {
      print('保存元数据时出错: $e');
      return false;
    }
  }
  
  // 读取卡片元数据
  static Future<CardMetadata?> loadMetadata({
    required String cardFilePath,
  }) async {
    try {
      // 获取元数据文件路径
      final String metaFilePath = _getMetaFilePath(cardFilePath);
      
      // 检查文件是否存在
      final File metaFile = File(metaFilePath);
      if (!await metaFile.exists()) {
        return null;
      }
      
      // 读取二进制数据
      final Uint8List binaryData = await metaFile.readAsBytes();
      
      // 解析元数据
      return CardMetadata.fromBinary(binaryData);
    } catch (e) {
      print('读取元数据时出错: $e');
      return null;
    }
  }
  
  // 获取元数据文件路径
  static String _getMetaFilePath(String cardFilePath) {
    final String fileNameWithoutExt = path.basenameWithoutExtension(cardFilePath);
    final String dirPath = path.dirname(cardFilePath);
    return path.join(dirPath, '$fileNameWithoutExt.meta');
  }
}