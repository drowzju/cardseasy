class CardModel {
  String title;
  String content;
  String filePath;
  DateTime createdAt;
  DateTime? lastModified;

  CardModel({
    required this.title,
    required this.content,
    required this.filePath,
    DateTime? createdAt,
    this.lastModified,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      title: json['title'],
      content: json['content'],
      filePath: json['filePath'],
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : null,
    );
  }

  String toMarkdown() {
    return '''# $title

$content
''';
  }
}