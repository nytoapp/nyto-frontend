import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_flow_state.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_header.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/facebook_logo_mark.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_tokens.dart';
import 'package:nyto_app/features/onboarding/widgets/google_g_logo.dart';

enum AuthSocialVariant { facebook, google, apple }

class AuthSocialButton extends StatefulWidget {
  const AuthSocialButton({
    super.key,
    required this.variant,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
  });

  final AuthSocialVariant variant;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;

  @override
  State<AuthSocialButton> createState() => _AuthSocialButtonState();
}

class _AuthSocialButtonState extends State<AuthSocialButton> {
  bool _pressed = false;

  String get _label {
    switch (widget.variant) {
      case AuthSocialVariant.facebook:
        return 'Facebook';
      case AuthSocialVariant.google:
        return 'Google';
      case AuthSocialVariant.apple:
        return 'Apple';
    }
  }

  String get _semanticsLabel => 'Continue with $_label';

  @override
  Widget build(BuildContext context) {
    final active =
        widget.enabled && !widget.loading && widget.onPressed != null;
    final scale = _pressed && active ? 0.98 : 1.0;

    return Semantics(
      button: true,
      enabled: active,
      label: _semanticsLabel,
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: active ? widget.onPressed : null,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: active ? 1 : 0.45,
            child: Container(
              height: AuthTokens.socialHeight,
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(AuthTokens.radiusMd),
                border: Border.all(color: _borderColor, width: 1),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AuthTokens.space16,
              ),
              child: Row(
                children: [
                  _iconSlot(),
                  const SizedBox(width: AuthTokens.space12),
                  Expanded(
                    child: Text(
                      widget.loading ? 'Signing in…' : _label,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: _textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _surfaceColor {
    if (widget.variant == AuthSocialVariant.apple) {
      return Colors.white.withValues(alpha: 0.96);
    }
    return AuthTokens.surfaceElevated.withValues(alpha: 0.92);
  }

  Color get _borderColor {
    if (widget.variant == AuthSocialVariant.apple) {
      return Colors.white.withValues(alpha: 0.08);
    }
    return AuthTokens.surfaceBorder;
  }

  Color get _textColor {
    if (widget.variant == AuthSocialVariant.apple) {
      return Colors.black.withValues(alpha: 0.88);
    }
    return NytoColors.cream.withValues(alpha: 0.9);
  }

  Widget _iconSlot() {
    if (widget.loading) {
      return SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.variant == AuthSocialVariant.apple
                  ? Colors.black54
                  : NytoColors.cream,
            ),
          ),
        ),
      );
    }

    switch (widget.variant) {
      case AuthSocialVariant.facebook:
        return const FacebookLogoMark(size: 26);
      case AuthSocialVariant.google:
        return const GoogleGLogo(size: 22);
      case AuthSocialVariant.apple:
        return const AppleLogoMark(size: 22, color: Colors.black);
    }
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.label = 'or continue with'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Divider(
      height: 1,
      thickness: 1,
      color: NytoColors.cream.withValues(alpha: 0.08),
    );
    return Row(
      children: [
        Expanded(child: line),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuthTokens.space16),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
              color: NytoColors.cream.withValues(alpha: 0.34),
            ),
          ),
        ),
        Expanded(child: line),
      ],
    );
  }
}

class AuthLegalFooter extends StatelessWidget {
  const AuthLegalFooter({super.key, this.onTermsTap});

  final VoidCallback? onTermsTap;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.dmSans(
          fontSize: 12,
          height: 1.5,
          color: NytoColors.cream.withValues(alpha: 0.38),
        ),
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onTermsTap,
              child: Text(
                'terms',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  height: 1.5,
                  color: NytoColors.ctaSoft.withValues(alpha: 0.75),
                  decoration: TextDecoration.underline,
                  decorationColor: NytoColors.ctaSoft.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const TextSpan(text: '. We never post without asking.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AuthTokens.space16,
        vertical: AuthTokens.space12,
      ),
      decoration: BoxDecoration(
        color: AuthTokens.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AuthTokens.radiusMd),
        border: Border.all(color: AuthTokens.error.withValues(alpha: 0.28)),
      ),
      child: Text(
        message,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          height: 1.4,
          color: AuthTokens.error.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

AuthSocialVariant socialVariant(AuthProviderKind kind) {
  switch (kind) {
    case AuthProviderKind.facebook:
      return AuthSocialVariant.facebook;
    case AuthProviderKind.google:
      return AuthSocialVariant.google;
    case AuthProviderKind.apple:
      return AuthSocialVariant.apple;
    case AuthProviderKind.phone:
      return AuthSocialVariant.google;
  }
}
