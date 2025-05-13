import 'package:flutter/material.dart';

class EmptyCardView extends StatelessWidget {
  const EmptyCardView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '没有卡片',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('在此目录中创建子文件夹作为卡片'),
        ],
      ),
    );
  }
}