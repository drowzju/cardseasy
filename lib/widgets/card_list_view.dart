import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/card_metadata.dart';

class CardListView extends StatelessWidget {
  final List<CardModel> cards;
  final Function(CardModel) onCardTap;
  final Map<String, CardMetadata?> cardMetadataMap;
  
  const CardListView({
    super.key,
    required this.cards,
    required this.onCardTap,
    required this.cardMetadataMap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
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
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Stack(
            children: [
              Center( // 确保内容居中
                child: ListTile(
                  dense: true,
                  title: Text(
                    card.title,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.left, // 文本左对齐
                  ),
                  leading: const Icon(
                    Icons.note,
                    color: Colors.blue,
                  ),                  
                  onTap: () => onCardTap(card),
                ),
              ),
              // 右下角显示评分圆环，位置调整
              Positioned(
                right: 40, // 调整位置，使其更靠近中间
                bottom: 10, // 稍微上移
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
        );
      },
    );
  }
}