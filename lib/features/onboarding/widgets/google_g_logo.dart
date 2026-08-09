import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Official multicolor Google "G" mark.
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/google_g.svg',
      width: size,
      height: size,
      semanticsLabel: 'Google',
    );
  }
}
