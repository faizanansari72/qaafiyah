import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Colors - Dark
  static const Color darkBackground = Color(0xFF09090B);
  static const Color darkSurface = Color(0xFF151518);
  static const Color darkSurfaceCard = Color(0xFF1E1E24);
  static const Color darkPrimaryGold = Color(0xFFD4AF37); // Rich Gold
  static const Color darkAccentGold = Color(0xFFF3E5AB); // Soft Gold
  static const Color darkTextPrimary = Color(0xFFF8F9FA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkBorder = Color(0xFF27272A);
  
  // Theme Colors - Light
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF1F3F5);
  static const Color lightPrimaryGold = Color(0xFFB59410); // Deep Gold for contrast
  static const Color lightAccentGold = Color(0xFF8C6D0F);
  static const Color lightTextPrimary = Color(0xFF09090B);
  static const Color lightTextSecondary = Color(0xFF71717A);
  static const Color lightBorder = Color(0xFFE4E4E7);

  // Status Colors
  static const Color colorSuccess = Color(0xFF10B981); // Emerald Green
  static const Color colorWarning = Color(0xFFF59E0B); // Amber
  static const Color colorError = Color(0xFFEF4444);   // Rose/Red
  static const Color colorInfo = Color(0xFF3B82F6);    // Premium Blue

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF3E5AB), Color(0xFFD4AF37), Color(0xFF8C6D0F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGlassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x08FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGlassGradient = LinearGradient(
    colors: [Color(0xE6FFFFFF), Color(0x99FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkPrimaryGold,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryGold,
        secondary: darkAccentGold,
        background: darkBackground,
        surface: darkSurface,
        onPrimary: darkBackground,
        onSecondary: darkBackground,
        onSurface: darkTextPrimary,
        error: colorError,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 32),
          displayMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 28),
          displaySmall: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 24),
          headlineMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 20),
          titleLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
          titleMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w500, fontSize: 16),
          bodyLarge: TextStyle(color: darkTextPrimary, fontSize: 14),
          bodyMedium: TextStyle(color: darkTextSecondary, fontSize: 13),
          labelLarge: TextStyle(color: darkPrimaryGold, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimaryGold,
        unselectedItemColor: darkTextSecondary,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimaryGold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryGold,
          foregroundColor: darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: lightPrimaryGold,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      dividerColor: lightBorder,
      colorScheme: const ColorScheme.light(
        primary: lightPrimaryGold,
        secondary: lightAccentGold,
        background: lightBackground,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        error: colorError,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold, fontSize: 32),
          displayMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold, fontSize: 28),
          displaySmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold, fontSize: 24),
          headlineMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 20),
          titleLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
          titleMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w500, fontSize: 16),
          bodyLarge: TextStyle(color: lightTextPrimary, fontSize: 14),
          bodyMedium: TextStyle(color: lightTextSecondary, fontSize: 13),
          labelLarge: TextStyle(color: lightPrimaryGold, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightPrimaryGold,
        unselectedItemColor: lightTextSecondary,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimaryGold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimaryGold,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
