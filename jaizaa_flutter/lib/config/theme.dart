import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JaizaaTheme {
  // Brand Colors
  static const Color primary = Color(0xFF2E7D32); // Medical Green
  static const Color onPrimary = Colors.white;
  static const Color secondary = Color(0xFF1565C0); // Trust Blue
  static const Color background = Color(0xFFF8F9FA); // Clinical Surface
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1B1C1C);
  static const Color textSecondary = Color(0xFF40493D);

  // Status/Urgency Colors
  static const Color criticalRed = Color(0xFFB71C1C);
  static const Color highWarning = Color(0xFFE65100);
  static const Color mediumCaution = Color(0xFFF9A825);
  static const Color lowSafe = Color(0xFF2E7D32);

  // Agent Trace Background
  static const Color traceBackground = Color(0xFF212121);
  static const Color traceText = Color(0xFFA3F69C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        background: background,
        surface: surface,
        onBackground: textPrimary,
        onSurface: textPrimary,
        error: criticalRed,
      ),
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.roboto(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        labelSmall: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE3E2E2), width: 1),
        ),
      ),
    );
  }

  // Monospace for Logs
  static TextStyle get traceStyle => GoogleFonts.robotoMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: traceText,
      );

  // Urdu Typography
  static TextStyle get urduStyle => GoogleFonts.notoSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      );
}
