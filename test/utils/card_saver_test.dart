import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:lifelong_learning_cards/utils/card_saver.dart';

void main() {
  group('CardSaver', () {
    group('_updateImageLinks', () {
      test('应该将图片链接更新为绝对路径', () {
        // 准备测试数据
        final String markdown = '''
# 测试标题

这是一个测试文档，包含一张图片：
![测试图片](file:///D:/obs/%E5%B7%A5%E4%BD%9C/work/Pasted%20image%2020250510220323.png)

另一张图片：
![另一张图片](D:/temp/image2.jpg)
''';

        final List<String> imageFiles = [
          'D:/temp/Pasted image 20250510220323.png',
          'D:/temp/image2.jpg',
        ];

        final String imagesDirPath = 'D:/temp/卡片/测试卡片/images';

        // 执行测试
        final String result = CardSaver._updateImageLinks(markdown, imageFiles, imagesDirPath);

        // 验证结果
        expect(result.contains('file:///D:\\temp\\卡片\\测试卡片\\images\\Pasted image 20250510220323.png'), isTrue);
        expect(result.contains('file:///D:\\temp\\卡片\\测试卡片\\images\\image2.jpg'), isTrue);
      });

      test('应该处理URL编码的路径', () {
        // 准备测试数据
        final String markdown = '''
# 测试标题

这是一个测试文档，包含一张URL编码的图片：
![测试图片](file:///D:/obs/%E5%B7%A5%E4%BD%9C/work/Pasted%20image%2020250510220323.png)
''';

        final List<String> imageFiles = [
          'D:/temp/Pasted image 20250510220323.png',
        ];

        final String imagesDirPath = 'D:/temp/卡片/测试卡片/images';

        // 执行测试
        final String result = CardSaver._updateImageLinks(markdown, imageFiles, imagesDirPath);

        // 验证结果
        expect(result.contains('file:///D:\\temp\\卡片\\测试卡片\\images\\Pasted image 20250510220323.png'), isTrue);
      });

      test('应该处理部分匹配的文件名', () {
        // 准备测试数据
        final String markdown = '''
# 测试标题

这是一个测试文档，包含一张文件名部分匹配的图片：
![测试图片](file:///D:/other/path/image_20250510.png)
''';

        final List<String> imageFiles = [
          'D:/temp/image_20250510_full.png',
        ];

        final String imagesDirPath = 'D:/temp/卡片/测试卡片/images';

        // 执行测试
        final String result = CardSaver._updateImageLinks(markdown, imageFiles, imagesDirPath);

        // 验证结果
        expect(result.contains('file:///D:\\temp\\卡片\\测试卡片\\images\\image_20250510_full.png'), isTrue);
      });

      test('不匹配的图片链接应保持不变', () {
        // 准备测试数据
        final String markdown = '''
# 测试标题

这是一个测试文档，包含一张不在列表中的图片：
![测试图片](https://example.com/image.jpg)
''';

        final List<String> imageFiles = [
          'D:/temp/other_image.png',
        ];

        // 将所有类似这样的路径：
        // final String imagesDirPath = 'D:/temp/卡片/测试卡片/images';
        // 修改为：
        final String imagesDirPath = 'D:/temp/卡片/测试卡片';

        // 执行测试
        final String result = CardSaver._updateImageLinks(markdown, imageFiles, imagesDirPath);

        // 验证结果
        expect(result.contains('![测试图片](https://example.com/image.jpg)'), isTrue);
      });
    });
  });
}