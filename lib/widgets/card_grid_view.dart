import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardGridView extends StatelessWidget {
  final List<CardModel> cards;
  final Function(CardModel) onCardTap;
  
  const CardGridView({
    super.key,
    required this.cards,
    required this.onCardTap,
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
    return InkWell(
      onTap: () => onCardTap(card),
      child: Card(
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}