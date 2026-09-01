import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_tokens.dart';

class AuthEditorialHeader extends StatelessWidget {
  const AuthEditorialHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            color: NytoColors.ctaSoft.withValues(alpha: 0.88),
          ),
        ),
        const SizedBox(height: AuthTokens.space12),
        Text(
          title,
          style: GoogleFonts.fraunces(
            fontSize: 36,
            fontWeight: FontWeight.w500,
            height: 1.08,
            letterSpacing: -0.8,
            color: NytoColors.cream,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AuthTokens.space12),
          Text(
            subtitle!,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.5,
              color: NytoColors.cream.withValues(alpha: 0.52),
            ),
          ),
        ],
      ],
    );
  }
}

class AuthBackLink extends StatelessWidget {
  const AuthBackLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: label,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AuthTokens.space8),
            minimumSize: const Size(AuthTokens.minTouch, AuthTokens.minTouch),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: NytoColors.ctaSoft.withValues(alpha: 0.92),
            ),
          ),
        ),
      ),
    );
  }
}

class InstagramLogoMark extends StatelessWidget {
  const InstagramLogoMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/instagram_logo.svg',
      width: size,
      height: size,
      semanticsLabel: 'Instagram',
    );
  }
}

class AppleLogoMark extends StatelessWidget {
  const AppleLogoMark({
    super.key,
    this.size = 22,
    this.color = Colors.black,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/apple_logo.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: 'Apple',
    );
  }
}
