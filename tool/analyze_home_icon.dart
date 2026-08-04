import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

void main() {
  final img = decodePng(File('_icon_check/home.png').readAsBytesSync());
  if (img == null) {
    stderr.writeln('bad screenshot');
    exit(1);
  }
  print('screenshot ${img.width}x${img.height}');

  // Emulator content is on the right side of desktop screenshots sometimes,
  // but adb screencap is device-only. Find the Nyto dock icon:
  // typically bottom-right of the 4 dock icons above the search bar.
  // Scan bottom third for circular high-saturation pink/purple clusters.
  final y0 = (img.height * 0.70).round();
  final y1 = (img.height * 0.92).round();
  final x0 = (img.width * 0.55).round();
  final x1 = (img.width * 0.98).round();

  // Find colorful pixels in dock area
  final points = <List<int>>[];
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final p = img.getPixel(x, y);
      final sat = (p.r - p.g).abs() + (p.g - p.b).abs() + (p.b - p.r).abs();
      // pink/magenta/purple
      if (sat > 60 && p.r > 80 && p.b > 60 && p.g < p.r) {
        points.add([x, y]);
      }
    }
  }
  print('pinkish pixels in dock-right: ${points.length}');
  if (points.isEmpty) {
    // try full bottom
    for (var y = y0; y < y1; y++) {
      for (var x = 0; x < img.width; x++) {
        final p = img.getPixel(x, y);
        final sat = (p.r - p.g).abs() + (p.g - p.b).abs() + (p.b - p.r).abs();
        if (sat > 80 && p.r > 100 && p.b > 80) {
          points.add([x, y]);
        }
      }
    }
    print('pinkish pixels bottom full: ${points.length}');
  }
  if (points.isEmpty) exit(0);

  var minX = points.first[0], maxX = points.first[0];
  var minY = points.first[1], maxY = points.first[1];
  var sx = 0, sy = 0;
  for (final pt in points) {
    minX = math.min(minX, pt[0]);
    maxX = math.max(maxX, pt[0]);
    minY = math.min(minY, pt[1]);
    maxY = math.max(maxY, pt[1]);
    sx += pt[0];
    sy += pt[1];
  }
  final cx = sx / points.length;
  final cy = sy / points.length;
  print('pink cluster bbox=($minX,$minY)-($maxX,$maxY) center=($cx,$cy)');

  // Crop icon around cluster with padding
  final pad = 20;
  final crop = copyCrop(
    img,
    x: math.max(0, minX - pad),
    y: math.max(0, minY - pad),
    width: math.min(img.width - 1, maxX + pad) - math.max(0, minX - pad),
    height: math.min(img.height - 1, maxY + pad) - math.max(0, minY - pad),
  );
  File('_icon_check/nyto_crop.png').writeAsBytesSync(encodePng(crop));
  print('wrote _icon_check/nyto_crop.png ${crop.width}x${crop.height}');

  // Sample outer ring of crop vs center
  final ccx = crop.width / 2;
  final ccy = crop.height / 2;
  final rad = math.min(ccx, ccy);
  for (final t in [0.95, 0.85, 0.70, 0.50, 0.30]) {
    final x = (ccx + rad * t).round().clamp(0, crop.width - 1);
    final y = ccy.round().clamp(0, crop.height - 1);
    final p = crop.getPixel(x, y);
    print('r=$t right px rgba=${p.r},${p.g},${p.b},${p.a}');
  }
}
