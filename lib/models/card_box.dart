class CardBox {
  final String id;
  final String name;
  final String path;
  
  CardBox({
    required this.id,
    required this.name,
    required this.path,
  });
  
  // 从目录路径创建卡片盒
  factory CardBox.fromPath(String path) {
    // 修复：确保正确提取文件夹名称
    final pathSegments = path.split(RegExp(r'[/\\]')); // 同时处理 / 和 \ 分隔符
    final name = pathSegments.last.isEmpty ? pathSegments[pathSegments.length - 2] : pathSegments.last;
    
    return CardBox(
      id: path,
      name: name,
      path: path,
    );
  }
}