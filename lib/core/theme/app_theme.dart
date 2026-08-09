import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NYTO design tokens — ice blue + near-black (Figma lock).
class NytoColors {
  // ── Locked ice-blue system ─────────────────────────────────────────────
  static const Color ground = Color(0xFF05070A);
  static const Color surfaceElevated = Color(0xFF0F1218);
  static const Color border = Color(0xFF243044);
  static const Color cta = Color(0xFF3D6EFF);
  static const Color ctaDeep = Color(0xFF2B5CE8);
  static const Color ctaSoft = Color(0xFF6B9AFF);
  static const Color ctaDisabled = Color(0x593D6EFF); // ~35%
  static const Color headline = Color(0xFFF2F5FA);
  static const Color subtext = Color(0xFF8B95A7);
  static const Color muted = Color(0xFF667084);

  // ── App shell aliases (existing call sites) ────────────────────────────
  static const Color bg = ground;
  static const Color surface = surfaceElevated;
  static const Color cream = headline;
  static const Color creamMuted = subtext;
  static const Color creamFaint = Color(0x26667084); // muted @ ~15%
  static const Color pureBlack = Color(0xFF000000);
  static const Color brandInk = ground;

  /// Ice-blue gradient stops (was violet → magenta → pink).
  static const Color brandViolet = ctaDeep;
  static const Color brandMagenta = cta;
  static const Color brandPink = ctaSoft;

  static const Color glass = Color(0x33FFFFFF);
  static const Color glassStrong = Color(0x55FFFFFF);

  /// Warm accent only — streaks / rare badges. Not primary chrome.
  static const Color orange = Color(0xFFE8843A);
  static const Color orangeDisabled = Color(0x59E8843A);
  static const Color moss = Color(0xFF2F4F3E);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NytoColors.ground,
      colorScheme: const ColorScheme.dark(
        primary: NytoColors.cta,
        secondary: NytoColors.ctaSoft,
        surface: NytoColors.surfaceElevated,
        onPrimary: NytoColors.headline,
        onSurface: NytoColors.headline,
        outline: NytoColors.border,
      ),
    );

    return base.copyWith(
      textTheme: TextTheme(
        displayLarge: GoogleFonts.fraunces(
          fontSize: 34,
          fontWeight: FontWeight.w400,
          color: NytoColors.headline,
          height: 1.15,
          letterSpacing: -0.2,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 26,
          fontWeight: FontWeight.w300,
          color: NytoColors.headline,
          height: 1.25,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NytoColors.headline,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: NytoColors.headline,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: NytoColors.subtext,
          height: 1.55,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
          color: NytoColors.muted,
        ),
      ),
    );
  }

  /// @Deprecated Use [dark] — kept name for existing imports during migration.
  static ThemeData get light => dark;
}
