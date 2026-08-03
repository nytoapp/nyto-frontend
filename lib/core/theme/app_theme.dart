import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NYTO design tokens — matched to Figma Make references + brand mark.
class NytoColors {
  static const Color bg = Color(0xFF1A1512);
  static const Color cream = Color(0xFFF7F1E8);
  static const Color creamMuted = Color(0xFF9A8F82);
  static const Color creamFaint = Color(0x269A8F82); // ~15%
  static const Color orange = Color(0xFFC45C26);
  static const Color orangeDisabled = Color(0x59C45C26); // ~35%
  static const Color moss = Color(0xFF2F4F3E);
  static const Color surface = Color(0xFF221E1A);

  /// Brand splash / welcome (logo purple → pink).
  static const Color pureBlack = Color(0xFF000000);
  static const Color brandInk = Color(0xFF0A0610);
  static const Color brandViolet = Color(0xFF7A3CFF);
  static const Color brandMagenta = Color(0xFFE23A9A);
  static const Color brandPink = Color(0xFFFF5CB5);
  static const Color glass = Color(0x33FFFFFF);
  static const Color glassStrong = Color(0x55FFFFFF);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NytoColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: NytoColors.orange,
        secondary: NytoColors.moss,
        surface: NytoColors.bg,
        onPrimary: NytoColors.cream,
        onSurface: NytoColors.cream,
      ),
    );

    return base.copyWith(
      textTheme: TextTheme(
        displayLarge: GoogleFonts.fraunces(
          fontSize: 34,
          fontWeight: FontWeight.w400,
          color: NytoColors.cream,
          height: 1.15,
          letterSpacing: -0.2,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 26,
          fontWeight: FontWeight.w300,
          color: NytoColors.cream,
          height: 1.25,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NytoColors.cream,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: NytoColors.cream,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: NytoColors.creamMuted,
          height: 1.55,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
          color: NytoColors.creamMuted,
        ),
      ),
    );
  }

  /// @Deprecated Use [dark] — kept name for existing imports during migration.
  static ThemeData get light => dark;
}
