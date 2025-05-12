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
    final pathObj = Uri.directory(path);
    final name = pathObj.pathSegments.last;
    return CardBox(
      id: path,
      name: name,
      path: path,
    );
  }
}