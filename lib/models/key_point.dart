class KeyPoint {
  String id;
  String title;
  String content;

  KeyPoint({
    required this.id,
    required this.title, // 确保 title 是必需的
    this.content = '',
  });
}