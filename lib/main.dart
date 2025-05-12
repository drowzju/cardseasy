import 'package:flutter/material.dart';
import 'package:lifelong_learning_cards/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '卡片易',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // 移除重复的 theme 定义
      home: const HomeScreen(),
    );
  }
}
