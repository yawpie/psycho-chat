import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
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
