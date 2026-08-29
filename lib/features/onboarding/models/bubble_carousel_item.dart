import 'package:flutter/material.dart';

import 'package:nyto_app/core/theme/app_theme.dart';

/// One option in the spatial bubble carousel (reusable across onboarding).
class BubbleCarouselItem {
  const BubbleCarouselItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
}

/// Two bubble fill states — focused hero vs side/unfocused (NYTO ice-blue).
abstract final class BubbleCarouselTokens {
  static const focusedGradient = [
    NytoColors.ctaSoft,
    NytoColors.ctaDeep,
  ];

  static const unfocusedGradient = [
    NytoColors.border,
    NytoColors.surfaceElevated,
  ];
}
