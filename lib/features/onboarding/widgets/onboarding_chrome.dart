import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';

/// Dark brand shell — deliberately different from cream “dating app” onboarding.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.child,
    this.onBack,
    this.footer,
    this.showProgress = true,
  });

  final int step;
  final int totalSteps;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: NytoColors.brandInk,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: NytoColors.brandInk,
        body: Stack(
          children: [
            const NytoAmbientField(intense: true),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          color: NytoColors.cream.withValues(alpha: 0.9),
                        ),
                        Expanded(
                          child: showProgress
                              ? OnboardingProgressBar(
                                  progress: step / totalSteps,
                                )
                              : const SizedBox.shrink(),
                        ),
                        if (showProgress) ...[
                          const SizedBox(width: 12),
                          Text(
                            '$step/$totalSteps',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: NytoColors.cream.withValues(alpha: 0.45),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ] else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: child,
                    ),
                  ),
                  if (footer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: footer!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: NytoColors.cream.withValues(alpha: 0.1)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.08, 1),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      NytoColors.ctaDeep,
                      NytoColors.cta,
                      NytoColors.ctaSoft,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: GoogleFonts.fraunces(
            fontSize: 30,
            fontWeight: FontWeight.w500,
            height: 1.15,
            letterSpacing: -0.4,
            color: NytoColors.cream,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.45,
              color: NytoColors.cream.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}

class NytoPrimaryButton extends StatelessWidget {
  const NytoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: active ? 1 : 0.38,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: active ? onPressed : null,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: active
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        NytoColors.ctaSoft,
                        NytoColors.cta,
                        NytoColors.ctaDeep,
                      ],
                    )
                  : null,
              color: active ? null : NytoColors.surfaceElevated,
              border: active
                  ? null
                  : Border.all(color: NytoColors.border.withValues(alpha: 0.8)),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: NytoColors.cta.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? Colors.white
                      : NytoColors.muted.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NytoGhostButton extends StatelessWidget {
  const NytoGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: NytoColors.cream.withValues(alpha: 0.55),
          decoration: TextDecoration.underline,
          decorationColor: NytoColors.cream.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

/// Premium NYTO page turn — parallax slide, soft scale, brand veil flash.
Route<T> onboardingRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 720),
    reverseTransitionDuration: const Duration(milliseconds: 560),
    opaque: true,
    barrierColor: NytoColors.brandInk,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _NytoPageTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
  );
}

class _NytoPageTransition extends StatelessWidget {
  const _NytoPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  static const _enterCurve = Cubic(0.16, 1.0, 0.3, 1.0);
  static const _exitCurve = Cubic(0.55, 0.0, 0.45, 1.0);

  @override
  Widget build(BuildContext context) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: _enterCurve,
      reverseCurve: _exitCurve,
    );
    final cover = CurvedAnimation(
      parent: secondaryAnimation,
      curve: _exitCurve,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([enter, cover]),
      builder: (context, _) {
        final t = enter.value;
        final c = cover.value;

        // Enter from the right with lift; leave left + shrink when covered.
        final dx = (1 - t) * 72.0 + c * -48.0;
        final dy = (1 - t) * 18.0 + c * 8.0;
        final scale = 0.90 + (0.10 * t) - (0.05 * c);
        final opacity = (t * (1.0 - c * 0.65)).clamp(0.0, 1.0);

        // Brand veil peaks in the middle of the turn.
        final veil = (t < 1 && t > 0)
            ? (math.sin(t * math.pi) * (1.0 - c * 0.5)).clamp(0.0, 1.0)
            : (c > 0 && c < 1)
                ? math.sin(c * math.pi) * 0.55
                : 0.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: child,
                ),
              ),
            ),
            if (veil > 0.02)
              IgnorePointer(
                child: Opacity(
                  opacity: veil * 0.55,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0x003D6EFF),
                          Color(0x993D6EFF),
                          Color(0xAA6B9AFF),
                          Color(0x003D6EFF),
                        ],
                        stops: [0.0, 0.35, 0.65, 1.0],
                      ),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

