import 'dart:io';

import 'package:image/image.dart';

void main() {
  for (final path in [
    '_icon_extract/res/drawable-xxxhdpi-v4/ic_launcher_foreground.png',
    '_icon_extract/res/mipmap-xxxhdpi-v4/ic_launcher.png',
  ]) {
    final img = decodePng(File(path).readAsBytesSync())!;
    final w = img.width;
    final h = img.height;
    print('--- $path ${w}x${h} ch=${img.numChannels}');
    final c = img.getPixel(0, 0);
    final d = img.getPixel((w * 0.12).round(), (h * 0.12).round());
    final m = img.getPixel(w ~/ 2, h ~/ 2);
    print('  corner rgba=${c.r},${c.g},${c.b},${c.a}');
    print('  diag-outer rgba=${d.r},${d.g},${d.b},${d.a}');
    print('  center rgba=${m.r},${m.g},${m.b},${m.a}');
  }
  print(File('_icon_extract/res/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync());
}
