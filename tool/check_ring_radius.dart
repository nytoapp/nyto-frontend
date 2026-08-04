import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

void main() {
  final img = decodePng(
    File('android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png')
        .readAsBytesSync(),
  )!;
  final w = img.width;
  final h = img.height;
  final cx = w / 2.0;
  final cy = h / 2.0;

  var minR = 1e9;
  var maxR = 0.0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = img.getPixel(x, y);
      final sat = (p.r - p.g).abs() + (p.g - p.b).abs() + (p.b - p.r).abs();
      if (sat > 40 && p.r + p.g + p.b > 80) {
        final dx = x + 0.5 - cx;
        final dy = y + 0.5 - cy;
        final r = math.sqrt(dx * dx + dy * dy) / (w / 2);
        if (r < minR) minR = r;
        if (r > maxR) maxR = r;
      }
    }
  }
  print('colorful ring radial span: min=$minR max=$maxR (1.0 = canvas edge)');
  print('black margin outside ring: ${(1 - maxR) * 100}% of radius');
}
