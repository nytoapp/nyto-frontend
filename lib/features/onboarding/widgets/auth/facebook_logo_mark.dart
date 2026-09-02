import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Official Facebook brand mark — blue disc, white "f".
class FacebookLogoMark extends StatelessWidget {
  const FacebookLogoMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/facebook_logo.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: 'Facebook',
    );
  }
}
