import 'package:flutter/material.dart';

/// WaveLink Design System - Pixel perfect matching to web app
class AppTheme {
  // Colors from CSS variables
  static const Color _background = Color(0xFF0A0E1A); // hsl(225 30% 6%)
  static const Color _foreground = Color(0xFFE2E8F0); // hsl(210 40% 96%)
  static const Color _card = Color(0xFF1A2332); // hsl(225 25% 10%)
  static const Color _cardForeground = Color(0xFFE2E8F0);
  static const Color _primary = Color(0xFF00D4FF); // hsl(200 100% 50%)
  static const Color _primaryForeground = Color(0xFF0A0E1A);
  static const Color _secondary = Color(0xFF9945FF); // hsl(270 60% 55%)
  static const Color _secondaryForeground = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF1E293B); // hsl(225 20% 15%)
  static const Color _mutedForeground = Color(0xFF64748B); // hsl(215 20% 55%)
  static const Color _accent = Color(0xFFFF6B9D); // hsl(330 80% 60%)
  static const Color _accentForeground = Color(0xFFF8FAFC);
  static const Color _destructive = Color(0xFFEF4444); // hsl(0 84% 60%)
  static const Color _destructiveForeground = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFF334155); // hsl(225 20% 18%)
  static const Color _input = Color(0xFF334155);
  static const Color _ring = Color(0xFF00D4FF);

  // Glass effect colors
  static const Color _glassBg = Color(0x661A2332); // hsl(225 30% 12% / 0.4)
  static const Color _glassBorder = Color(0x2600D4FF); // hsl(200 80% 60% / 0.15)

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        background: _background,
        onBackground: _foreground,
        surface: _card,
        onSurface: _cardForeground,
        primary: _primary,
        onPrimary: _primaryForeground,
        secondary: _secondary,
        onSecondary: _secondaryForeground,
        tertiary: _accent,
        onTertiary: _accentForeground,
        error: _destructive,
        onError: _destructiveForeground,
        outline: _border,
        surfaceVariant: _muted,
        onSurfaceVariant: _mutedForeground,
      ),
      
      // Text themes matching web fonts (using system fonts as fallback)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w700,
          fontSize: 32,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w600,
          fontSize: 28,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w600,
          fontSize: 24,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 10,
          height: 1.4,
        ),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: _foreground,
        ),
      ),

      // Card theme for glass effects
      cardTheme: CardTheme(
        color: _glassBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: _glassBorder,
            width: 1,
          ),
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: _primaryForeground,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: _secondaryForeground,
          side: const BorderSide(color: _glassBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _glassBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _glassBorder, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _glassBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _destructive, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _destructive, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Scaffold theme
      scaffoldBackgroundColor: _background,
    );
  }

  // Gradients matching CSS exactly
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0066CC), // hsl(220 80% 20%)
      Color(0xFF00D4FF), // hsl(200 100% 40%)
      Color(0xFF00E5CC), // hsl(180 100% 45%)
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F1729), // hsl(225 40% 8%)
      Color(0xFF1E293B), // hsl(220 60% 12%)
      Color(0xFF1A2332), // hsl(240 40% 10%)
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xCC1A2332), // hsl(225 30% 12% / 0.8)
      Color(0x992D3748), // hsl(220 40% 15% / 0.6)
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      _primary,
      _secondary,
    ],
  );

  static const LinearGradient senderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00E5CC), // hsl(200 100% 45%)
      Color(0xFF00FFE5), // hsl(180 100% 50%)
    ],
  );

  static const LinearGradient receiverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      _secondary,
      _accent,
    ],
  );

  // Glass effect decoration
  static BoxDecoration glassDecoration({
    BorderRadius? borderRadius,
    BoxShadow? boxShadow,
  }) {
    return BoxDecoration(
      color: _glassBg,
      border: Border.all(color: _glassBorder, width: 1),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      boxShadow: boxShadow ?? [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Glow effects
  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: _primary.withOpacity(0.3),
      blurRadius: 30,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get accentGlow => [
    BoxShadow(
      color: _secondary.withOpacity(0.3),
      blurRadius: 30,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get liveGlow => [
    BoxShadow(
      color: _destructive.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  // Spacing constants
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Border radius
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radius2xl = BorderRadius.all(Radius.circular(24));
}
