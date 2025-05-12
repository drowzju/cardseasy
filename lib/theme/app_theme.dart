import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      // fontFamily is valid here as a direct parameter
      fontFamily: 'NotoSansSC',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 16.0),
        bodyMedium: TextStyle(fontSize: 14.0),
        bodySmall: TextStyle(fontSize: 12.0),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Create a new ThemeData instead of using copyWith
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'NotoSansSC',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 16.0),
        bodyMedium: TextStyle(fontSize: 14.0),
        bodySmall: TextStyle(fontSize: 12.0),
      ),
    );
  }
}