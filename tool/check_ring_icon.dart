import 'dart:io';

import 'package:image/image.dart';

void main() {
  for (final path in [
    'assets/brand/nyto_app_icon_circle_1024.png',
    'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  ]) {
    final img = decodePng(File(path).readAsBytesSync())!;
    final w = img.width;
    final h = img.height;
    print('--- $path ${w}x${h} ch=${img.numChannels}');
    void sample(String label, int x, int y) {
      final p = img.getPixel(x, y);
      print('  $label ($x,$y) rgba=${p.r},${p.g},${p.b},${p.a}');
    }

    sample('corner', 0, 0);
    sample('mid-top', w ~/ 2, 2);
    sample('mid-edge', w - 3, h ~/ 2);
    sample('diag-outer', (w * 0.12).round(), (h * 0.12).round());
    sample('diag-inner', (w * 0.35).round(), (h * 0.35).round());
    sample('center', w ~/ 2, h ~/ 2);
  }
}
