import 'package:flutter/material.dart';

/// Spacing and radii for auth surfaces — 4px grid.
abstract final class AuthTokens {
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;

  static const double radiusMd = 14;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  static const double primaryHeight = 56;
  static const double socialHeight = 52;
  static const double minTouch = 48;

  static const Color surfaceElevated = Color(0xFF12161F);
  static const Color surfaceBorder = Color(0x33F2F5FA);
  static const Color error = Color(0xFFE57373);
}
