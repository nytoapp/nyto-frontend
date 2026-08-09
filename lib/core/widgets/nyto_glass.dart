import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nyto_app/core/theme/app_theme.dart';

/// iOS-style frosted glass — use on chrome that sits over ambient light.
class NytoGlass extends StatelessWidget {
  const NytoGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.blur = 28,
    this.tint,
    this.borderColor,
    this.borderWidth = 1,
    this.height,
    this.width,
  });

  /// Soft panel (rows, tiles, sheets). No glow — selection stays quiet.
  factory NytoGlass.panel({
    Key? key,
    required Widget child,
    double borderRadius = 20,
    EdgeInsetsGeometry? padding,
    bool selected = false,
  }) {
    return NytoGlass(
      key: key,
      borderRadius: borderRadius,
      padding: padding,
      blur: 32,
      tint: selected
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.10),
      borderColor: selected
          ? NytoColors.cta.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.22),
      borderWidth: selected ? 1.2 : 1,
      child: child,
    );
  }

  /// Floating bar (bottom nav / sticky chrome).
  factory NytoGlass.bar({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return NytoGlass(
      key: key,
      borderRadius: 0,
      padding: padding,
      blur: 36,
      tint: Colors.white.withValues(alpha: 0.12),
      borderColor: Colors.white.withValues(alpha: 0.2),
      borderWidth: 0.8,
      child: child,
    );
  }

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final Color? tint;
  final Color? borderColor;
  final double borderWidth;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final fill = tint ?? Colors.white.withValues(alpha: 0.1);
    final stroke = borderColor ?? Colors.white.withValues(alpha: 0.2);

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: stroke, width: borderWidth),
            // Layered frost: brighter top edge like real iOS glass.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.28),
                fill,
                Colors.white.withValues(alpha: 0.06),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Soft light field so frosted glass has something to refract.
class NytoAmbientField extends StatelessWidget {
  const NytoAmbientField({super.key, this.intense = false});

  final bool intense;

  @override
  Widget build(BuildContext context) {
    final a = intense ? 1.35 : 1.15;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base lift — without this, blur has nothing to show on pure black.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.15, -0.55),
                radius: 1.15,
                colors: [
                  const Color(0xFF1A2438).withValues(alpha: 0.95 * a),
                  NytoColors.ground,
                ],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -50,
            child: _blob(280, NytoColors.cta.withValues(alpha: 0.38 * a)),
          ),
          Positioned(
            top: 160,
            left: -100,
            child: _blob(320, NytoColors.ctaDeep.withValues(alpha: 0.28 * a)),
          ),
          Positioned(
            bottom: 20,
            right: -40,
            child: _blob(260, NytoColors.ctaSoft.withValues(alpha: 0.2 * a)),
          ),
          Positioned(
            bottom: 180,
            left: 40,
            child: _blob(180, Colors.white.withValues(alpha: 0.06 * a)),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.transparent,
                  NytoColors.cta.withValues(alpha: 0.06),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}
