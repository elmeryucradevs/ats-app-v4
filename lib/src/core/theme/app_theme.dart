import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema personalizado de la aplicación
///
/// Define los colores, tipografía y estilos tanto para modo claro como oscuro.
/// Sigue las directrices de Material Design 3.
class AppTheme {
  // Constructor privado
  AppTheme._();

  // ===================================
  // PALETA DE COLORES - LIGHT MODE
  // ===================================
  static const Color _primaryLight = Color(0xFF1976D2); // Azul vibrante
  static const Color _secondaryLight = Color(0xFFFF6F00); // Naranja
  static const Color _tertiaryLight = Color(0xFF00897B); // Verde azulado
  static const Color _errorLight = Color(0xFFD32F2F); // Rojo
  static const Color _backgroundLight = Color(0xFFFAFAFA); // Gris muy claro
  static const Color _surfaceLight = Color(0xFFFFFFFF); // Blanco
  static const Color _onPrimaryLight = Color(0xFFFFFFFF); // Blanco
  static const Color _onSecondaryLight = Color(0xFFFFFFFF); // Blanco
  static const Color _onSurfaceLight = Color(0xFF000000); // Negro

  // ===================================
  // PALETA DE COLORES - DARK MODE
  // ===================================
  static const Color _primaryDark = Color(0xFF42A5F5); // Azul claro
  static const Color _secondaryDark = Color(0xFFFFB74D); // Naranja claro
  static const Color _tertiaryDark = Color(0xFF4DB6AC); // Verde azulado claro
  static const Color _errorDark = Color(0xFFEF5350); // Rojo claro
  static const Color _backgroundDark = Color(0xFF121212); // Negro puro
  static const Color _surfaceDark = Color(0xFF1E1E1E); // Gris oscuro
  static const Color _onPrimaryDark = Color(0xFF000000); // Negro
  static const Color _onSecondaryDark = Color(0xFF000000); // Negro
  static const Color _onSurfaceDark = Color(0xFFFFFFFF); // Blanco

  // ===================================
  // COLORES ESPECIALES
  // ===================================
  // Color para indicador "EN VIVO"
  static const Color liveIndicatorColor = Color(0xFFFF1744);

  // Color para shimmer loading
  static const Color shimmerBaseLight = Color(0xFFE0E0E0);
  static const Color shimmerHighlightLight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2C2C2C);
  static const Color shimmerHighlightDark = Color(0xFF3C3C3C);

  // ===================================
  // TEMA CLARO (LIGHT)
  // ===================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: _primaryLight,
        secondary: _secondaryLight,
        tertiary: _tertiaryLight,
        error: _errorLight,
        surface: _surfaceLight,
        onPrimary: _onPrimaryLight,
        onSecondary: _onSecondaryLight,
        onSurface: _onSurfaceLight,
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: _backgroundLight,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _surfaceLight,
        foregroundColor: _onSurfaceLight,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _onSurfaceLight,
        ),
      ),

      // Card
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.all(8),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _errorLight, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 8,
        selectedItemColor: _primaryLight,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      // Tipografía
      textTheme: GoogleFonts.poppinsTextTheme(),
    );
  }

  // ===================================
  // TEMA OSCURO (DARK)
  // ===================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: _primaryDark,
        secondary: _secondaryDark,
        tertiary: _tertiaryDark,
        error: _errorDark,
        surface: _surfaceDark,
        onPrimary: _onPrimaryDark,
        onSecondary: _onSecondaryDark,
        onSurface: _onSurfaceDark,
        onError: Colors.black,
      ),

      // Scaffold
      scaffoldBackgroundColor: _backgroundDark,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _surfaceDark,
        foregroundColor: _onSurfaceDark,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _onSurfaceDark,
        ),
      ),

      // Card
      cardTheme: const CardThemeData(
        elevation: 2,
        color: _surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.all(8),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _errorDark, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: _surfaceDark,
        selectedItemColor: _primaryDark,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      // Tipografía
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    );
  }
}
