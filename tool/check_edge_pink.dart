import 'dart:io';

import 'package:image/image.dart';

void main() {
  for (final path in [
    'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  ]) {
    final img = decodePng(File(path).readAsBytesSync())!;
    final w = img.width;
    final h = img.height;
    print('--- $path ${w}x$h ---');

    // Scan outer 8% ring for any non-black colorful pixels
    final margin = (w * 0.08).round();
    var colorful = 0;
    var maxSat = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final onEdge = x < margin ||
            y < margin ||
            x >= w - margin ||
            y >= h - margin;
        if (!onEdge) continue;
        final p = img.getPixel(x, y);
        final sat = (p.r - p.g).abs() + (p.g - p.b).abs() + (p.b - p.r).abs();
        if (sat > 30 && (p.r > 40 || p.g > 40 || p.b > 40)) {
          colorful++;
          if (sat > maxSat) maxSat = sat.toInt();
        }
      }
    }
    print('edge colorful pixels=$colorful maxSat=$maxSat');
  }
}
