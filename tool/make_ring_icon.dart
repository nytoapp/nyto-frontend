import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Build launcher icons from official AppIcon.
/// Kills the baked-in light-pink squircle halo that shows as a home-dock rim.
void main() {
  const srcPath =
      r'C:\dev\nytoapp\nytoapp\designs\NYTO Logos\NYTO_AppIcon_1024.png';
  // Pure black — matches drawer look the user approved
  const plateR = 0;
  const plateG = 0;
  const plateB = 0;

  final bytes = File(srcPath).readAsBytesSync();
  final src = decodePng(bytes);
  if (src == null) {
    stderr.writeln('Failed to decode $srcPath');
    exit(1);
  }

  final w = src.width;
  final h = src.height;
  final cx = (w - 1) / 2.0;
  final cy = (h - 1) / 2.0;
  final maxR = math.min(cx, cy);

  // 1) Keep only the brand ring/dot (saturated color). Drop near-black AND
  //    the thin light-pink squircle AA halo near the outer edge of AppIcon_512.
  final ring = Image(width: w, height: h, numChannels: 4);
  fill(ring, color: ColorRgba8(0, 0, 0, 0));

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();

      final dx = x - cx;
      final dy = y - cy;
      final dist = math.sqrt(dx * dx + dy * dy) / maxR;

      // Outer zone of the source is the squircle plate + pink AA rim — kill it.
      if (dist > 0.92) continue;

      final maxC = math.max(r, math.max(g, b));
      final minC = math.min(r, math.min(g, b));
      final chroma = maxC - minC;

      // Near-black / dark plate
      if (maxC < 45) continue;

      // Light pink / white squircle fringe: bright but low-mid chroma, outer band
      final isFringe =
          dist > 0.78 && maxC > 80 && chroma < 90 && r >= g && r >= b;
      if (isFringe) continue;

      // Keep vivid ring / glow / dot
      if (chroma < 25 && maxC < 90) continue;

      ring.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // 2) Crop to ring bounds, then scale LARGE onto black plate.
  //    (Resizing the full padded canvas kept the ring tiny.)
  var minX = w;
  var minY = h;
  var maxX = 0;
  var maxY = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = ring.getPixel(x, y);
      if (p.a < 8) continue;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }
  if (maxX <= minX || maxY <= minY) {
    stderr.writeln('No ring pixels found in source icon');
    exit(1);
  }
  final pad = ((maxX - minX) * 0.08).round().clamp(4, 48);
  minX = (minX - pad).clamp(0, w - 1);
  minY = (minY - pad).clamp(0, h - 1);
  maxX = (maxX + pad).clamp(0, w - 1);
  maxY = (maxY + pad).clamp(0, h - 1);
  final cropped = copyCrop(
    ring,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );

  // Slightly bigger than 0.64; keep under ~0.72 so Realme mask doesn't clip the dot.
  const artRatio = 0.70;
  final artSize = (w * artRatio).round();
  final art = copyResize(
    cropped,
    width: artSize,
    height: artSize,
    interpolation: Interpolation.average,
  );

  final composed = Image(width: w, height: h, numChannels: 4);
  fill(composed, color: ColorRgba8(plateR, plateG, plateB, 255));
  final ox = ((w - artSize) / 2).round();
  final oy = ((h - artSize) / 2).round();
  compositeImage(composed, art, dstX: ox, dstY: oy);

  // Only wipe the extreme outer rim (squircle AA) — do not eat the logo tip/dot.
  final cMaxR = math.min((w - 1) / 2.0, (h - 1) / 2.0);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final dx = x - (w - 1) / 2.0;
      final dy = y - (h - 1) / 2.0;
      final dist = math.sqrt(dx * dx + dy * dy) / cMaxR;
      if (dist >= 0.97) {
        composed.setPixelRgba(x, y, plateR, plateG, plateB, 255);
      } else {
        final p = composed.getPixel(x, y);
        if (p.a < 255) {
          composed.setPixelRgba(x, y, plateR, plateG, plateB, 255);
        }
      }
    }
  }

  const mipmapSizes = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  for (final entry in mipmapSizes.entries) {
    final resized = copyResize(
      composed,
      width: entry.value,
      height: entry.value,
      interpolation: Interpolation.average,
    );
    // Re-clamp after resize (interpolation can reintroduce fringe)
    _forceOuterBlack(resized, plateR, plateG, plateB, 0.97);
    File('android/app/src/main/res/${entry.key}/ic_launcher.png')
        .writeAsBytesSync(encodePng(resized));
  }

  // Also refresh Flutter brand assets used for adaptive / previews.
  File('assets/brand/nyto_adaptive_foreground_1024.png')
      .writeAsBytesSync(encodePng(composed));
  File('assets/brand/nyto_app_icon_1024.png')
      .writeAsBytesSync(encodePng(composed));
  final icon512 = copyResize(
    composed,
    width: 512,
    height: 512,
    interpolation: Interpolation.average,
  );
  _forceOuterBlack(icon512, plateR, plateG, plateB, 0.97);
  File('assets/brand/nyto_app_icon_512.png').writeAsBytesSync(encodePng(icon512));

  const fgSizes = <String, int>{
    'drawable-mdpi': 108,
    'drawable-hdpi': 162,
    'drawable-xhdpi': 216,
    'drawable-xxhdpi': 324,
    'drawable-xxxhdpi': 432,
  };
  for (final entry in fgSizes.entries) {
    final dir = Directory('android/app/src/main/res/${entry.key}');
    dir.createSync(recursive: true);
    final resized = copyResize(
      composed,
      width: entry.value,
      height: entry.value,
      interpolation: Interpolation.average,
    );
    _forceOuterBlack(resized, plateR, plateG, plateB, 0.97);
    File('${dir.path}/ic_launcher_foreground.png')
        .writeAsBytesSync(encodePng(resized));
  }

  Directory('android/app/src/main/res/values').createSync(recursive: true);
  File('android/app/src/main/res/values/colors.xml').writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#000000</color>
</resources>
''');

  final oldBg =
      File('android/app/src/main/res/drawable/ic_launcher_background.xml');
  if (oldBg.existsSync()) oldBg.deleteSync();

  Directory('android/app/src/main/res/mipmap-anydpi-v26')
      .createSync(recursive: true);
  File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
      .writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background" />
  <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
''');

  // Sanity: count non-black pixels in outer 10% radius band
  var outerColor = 0;
  final check = decodePng(
    File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png')
        .readAsBytesSync(),
  )!;
  final cw = check.width;
  final ch = check.height;
  final cr = math.min((cw - 1) / 2.0, (ch - 1) / 2.0);
  for (var y = 0; y < ch; y++) {
    for (var x = 0; x < cw; x++) {
      final dx = x - (cw - 1) / 2.0;
      final dy = y - (ch - 1) / 2.0;
      final dist = math.sqrt(dx * dx + dy * dy) / cr;
      if (dist < 0.90) continue;
      final p = check.getPixel(x, y);
      if (p.r > 8 || p.g > 8 || p.b > 8) outerColor++;
    }
  }

  stdout.writeln(
    'Fixed: stripped AppIcon squircle pink halo, pure black plate, outer clamp.',
  );
  stdout.writeln('Outer-band non-black pixels on xxxhdpi: $outerColor (want 0)');
}

void _forceOuterBlack(Image img, int r, int g, int b, double fromDist) {
  final w = img.width;
  final h = img.height;
  final cx = (w - 1) / 2.0;
  final cy = (h - 1) / 2.0;
  final maxR = math.min(cx, cy);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = math.sqrt(dx * dx + dy * dy) / maxR;
      if (dist >= fromDist) {
        img.setPixelRgba(x, y, r, g, b, 255);
      } else {
        final p = img.getPixel(x, y);
        if (p.a < 255) {
          img.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    }
  }
}
