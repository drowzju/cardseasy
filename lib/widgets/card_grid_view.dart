import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/card_metadata.dart';

class CardGridView extends StatelessWidget {
  final List<CardModel> cards;
  final Function(CardModel) onCardTap;
  final Map<String, CardMetadata?> cardMetadataMap;

  const CardGridView({
    super.key,
    required this.cards,
    required this.onCardTap,
    required this.cardMetadataMap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        childAspectRatio: 0.9,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildCardItem(card, context);
      },
    );
  }

  Widget _buildCardItem(CardModel card, BuildContext context) {
    // 获取卡片的自测评分
    final metadata = cardMetadataMap[card.filePath];
    final int score = metadata?.selfTestScore ?? 6; // 默认为6分

    // 根据分数确定颜色
    Color scoreColor;    
    if (score < 6) {
      scoreColor = Colors.blue.shade200;
    } else if (score == 6) {
      scoreColor = Colors.blue.shade400;
    } else if (score <= 8) {
      scoreColor = Colors.blue.shade700;
    } else {
      scoreColor = Colors.blue.shade900;
    }

    return InkWell(
      onTap: () => onCardTap(card),
      child: Card(
        elevation: 2,
        child: Stack(
          alignment: Alignment.center, // 确保内容居中
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
                crossAxisAlignment: CrossAxisAlignment.center, // 水平居中
                children: [
                  const Icon(
                    Icons.note,
                    size: 40,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            // 右下角显示评分圆环，但位置稍微向中间偏移
            Positioned(
              right: 8, // 从右边缘向内偏移
              bottom: 8, // 从底部向上偏移
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 2),
                  // 添加阴影使圆环更加突出
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
