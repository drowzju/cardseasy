import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardListView extends StatelessWidget {
  final List<CardModel> cards;
  final Function(CardModel) onCardTap;
  
  const CardListView({
    super.key,
    required this.cards,
    required this.onCardTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            dense: true,
            title: Text(
              card.title,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: const Text('点击查看详情'),
            leading: const Icon(
              Icons.note,
              color: Colors.blue,
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => onCardTap(card),
          ),
        );
      },
    );
  }
}