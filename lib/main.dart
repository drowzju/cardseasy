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
      title: 'CardsEasy',
      theme: AppTheme.lightTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade700,
          primary: Colors.blue.shade700,
          secondary: Colors.green.shade600,
          // 确保inversePrimary不是紫色
          inversePrimary: Colors.blue.shade100,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
