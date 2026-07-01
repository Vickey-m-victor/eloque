import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFF6366F1); // Modern Indigo
  static const Color secondaryColor = Color(0xFF06B6D4); // Electric Cyan
  static const Color accentColor = Color(0xFFEC4899); // Coral Pink for micro-animations/badges

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        background: const Color(0xFFF8FAFC),
        surface: Colors.white,
        surfaceVariant: const Color(0xFFF1F5F9),
        onBackground: const Color(0xFF0F172A),
        onSurface: const Color(0xFF0F172A),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
        titleSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
        bodyLarge: GoogleFonts.plusJakartaSans(color: const Color(0xFF334155)),
        bodyMedium: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shadowColor: const Color(0x0F0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Color(0xFF0F172A),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFFF1F5F9),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: const Color(0xFF818CF8), // Slightly brighter for dark mode contrast
        secondary: const Color(0xFF22D3EE),
        tertiary: accentColor,
        background: const Color(0xFF0B0F19), // Midnight slate
        surface: const Color(0xFF151D30), // Sleek navy dark card background
        surfaceVariant: const Color(0xFF1E293B),
        onBackground: const Color(0xFFF1F5F9),
        onSurface: const Color(0xFFF1F5F9),
      ),
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFF1F5F9)),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFF1F5F9)),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFF1F5F9)),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFF1F5F9)),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFF1F5F9)),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFFF1F5F9)),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFFF1F5F9)),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1)),
        titleSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
        bodyLarge: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1)),
        bodyMedium: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF151D30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Color(0xFFF1F5F9),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1E293B),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
