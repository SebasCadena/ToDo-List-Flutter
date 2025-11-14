import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Colors.purple,
    onPrimary: Colors.white,
    secondary: Colors.amber,
    onSecondary: Colors.black,
    surface: Color(0xFFF5F5F5),
    onSurface: Colors.black87,
    error: Colors.red,
    onError: Colors.white,
  ),

  scaffoldBackgroundColor: Colors.purple[50],

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.purple,
    foregroundColor: Colors.white,
    centerTitle: true,
    actionsPadding: EdgeInsets.only(right: 10),
  ),

  cardTheme: CardThemeData(
    //Asignar Color onPrimary
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
  ),

  useMaterial3: true,
);
