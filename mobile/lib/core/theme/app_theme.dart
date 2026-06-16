import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2E073F),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFFAD49E1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111111),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFAD49E1),
        surface: Color(0xFF12071A),
        onSurface: Color(0xFFF3EAF8),

        secondary: Color(0xFFEBD3F8),

        surfaceContainer: Color(0xFF2E073F),
        surfaceContainerHighest: Color(0xFF7A1CAC),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFEBD3F8),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: const Color(0xFF7A1CAC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF7A1CAC),
        onPrimary: Colors.white,

        secondary: Color(0xFFAD49E1),
        onSecondary: Colors.white,

        surface: Color(0xFFFDFBFE),
        onSurface: Color(0xFF2E073F),

        surfaceContainer: Color(0xFFEBD3F8),
        surfaceContainerHighest: Color(0xFF7A1CAC),

        outline: Color(0xFFC8A9D8),
      ),
      useMaterial3: true,
    );
  }
}
