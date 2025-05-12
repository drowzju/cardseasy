import 'package:uuid/uuid.dart';

class Understanding {
  final String id;
  final String title;
  String content;

  Understanding({
    required this.id,
    required this.title,
    this.content = '',
  });

  factory Understanding.create(String title) {
    return Understanding(
      id: const Uuid().v4(),
      title: title,
    );
  }
}