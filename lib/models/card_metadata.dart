import 'dart:typed_data';

class CardMetadata {
  final int selfTestScore; // 自测评分 (1-10)
  final DateTime lastTestDate; // 最后测试日期

  CardMetadata({
    this.selfTestScore = 0,
    DateTime? lastTestDate,
  }) : lastTestDate = lastTestDate ?? DateTime.now();

  // 将元数据转换为二进制数据
  Uint8List toBinary() {
    final ByteData byteData = ByteData(12); // 4字节整数 + 8字节时间戳
    byteData.setInt32(0, selfTestScore);
    byteData.setInt64(4, lastTestDate.millisecondsSinceEpoch);
    return byteData.buffer.asUint8List();
  }

  // 从二进制数据创建元数据对象
  factory CardMetadata.fromBinary(Uint8List data) {
    final ByteData byteData = ByteData.view(data.buffer);
    final int score = byteData.getInt32(0);
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(byteData.getInt64(4));
    return CardMetadata(
      selfTestScore: score,
      lastTestDate: date,
    );
  }
}