import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Palette
  static const Color primary = Color(0xff6c63ff); // Playful Sprout Purple
  static const Color secondary = Color(0xffffb84d); // Warm Orange Sun
  static const Color accent = Color(0xff4ecdc4); // Magic Teal
  static const Color success = Color(0xff7ed957); // Happy Green
  static const Color background = Color(0xfff8faff); // Soft Sky Background
  static const Color surface = Color(0xffffffff); // Clean Card Surface
  
  // Custom Neutrals
  static const Color textDark = Color(0xff2d3142); // High-contrast Charcoal
  static const Color textLight = Color(0xff9094a6); // Soft Grey
  static const Color borderLight = Color(0xffe2e8f5); // Soft Divider
  
  // Design System constants
  static const double radiusLarge = 24.0;
  static const double radiusExtraLarge = 32.0;
  
  // Theme Data Builder
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surface,
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: background,
      
      // Card Theme with soft rounded corners
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: borderLight, width: 2),
        ),
      ),
      
      // Button themes with heavy borders and thick styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto', // fallback-safe rounded/clean font
          ),
        ),
      ),
      
      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textDark,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textDark,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textLight,
        ),
      ),
    );
  }

  // Playful thick-bordered container decoration
  static BoxDecoration playfulCardDecoration({
    Color color = surface,
    Color borderColor = borderLight,
    double radius = radiusLarge,
    double borderWidth = 3,
    bool showShadow = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.3),
                offset: const Offset(0, 4),
                blurRadius: 0,
              )
            ]
          : null,
    );
  }
}
