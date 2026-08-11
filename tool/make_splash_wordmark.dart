import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Build transparent wordmark + native boot splash that MATCHES Flutter glow splash.
void main() {
  final src = decodePng(
    File('assets/brand/nyto_logo_primary.png').readAsBytesSync(),
  );
  if (src == null) {
    stderr.writeln('decode failed');
    exit(1);
  }

  final flat = Image(width: src.width, height: src.height, numChannels: 4);
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final a = p.a.toInt();
      final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
      final chroma = maxC - minC;
      if (a < 8 || (maxC < 72 && chroma < 36)) {
        flat.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        flat.setPixelRgba(x, y, r, g, b, a < 255 ? a : 255);
      }
    }
  }

  File('assets/brand/nyto_logo_wordmark.png').writeAsBytesSync(encodePng(flat));

  void writeDpi(String dir, int w) {
    Directory('android/app/src/main/res/$dir').createSync(recursive: true);
    final resized =
        copyResize(flat, width: w, interpolation: Interpolation.average);
    File('android/app/src/main/res/$dir/nyto_splash_logo.png')
        .writeAsBytesSync(encodePng(resized));
  }

  writeDpi('drawable-mdpi', 240);
  writeDpi('drawable-hdpi', 360);
  writeDpi('drawable-xhdpi', 480);
  writeDpi('drawable-xxhdpi', 640);
  writeDpi('drawable-xxxhdpi', 720);

  // Full-bleed boot frame — same look as Flutter glow splash (static).
  final boot = _glowFrame(1080, 1920, flat);
  Directory('android/app/src/main/res/drawable-nodpi').createSync(recursive: true);
  File('android/app/src/main/res/drawable-nodpi/nyto_boot_splash.png')
      .writeAsBytesSync(encodePng(boot));

  // Android 12 centered icon: ice-ink + baked glow + logo (no empty black).
  final a12 = _glowFrame(1152, 1152, flat, logoWidthFactor: 0.78);
  Directory('android/app/src/main/res/drawable-xxxhdpi').createSync(recursive: true);
  File('android/app/src/main/res/drawable-xxxhdpi/nyto_android12_splash.png')
      .writeAsBytesSync(encodePng(a12));
  Directory('android/app/src/main/res/drawable').createSync(recursive: true);
  File('android/app/src/main/res/drawable/nyto_android12_splash.png')
      .writeAsBytesSync(encodePng(
    copyResize(a12, width: 288, interpolation: Interpolation.average),
  ));

  stdout.writeln('Boot splash matches Flutter glow splash');
}

Image _glowFrame(
  int w,
  int h,
  Image logo, {
  double logoWidthFactor = 0.62,
}) {
  const gr = 5, gg = 7, gb = 10; // #05070A
  final img = Image(width: w, height: h, numChannels: 4);
  fill(img, color: ColorRgba8(gr, gg, gb, 255));

  // Soft ice-blue ambient blobs (matches Flutter NytoAmbientField).
  _blob(img, w * 0.72, h * 0.18, w * 0.55, 61, 110, 255, 0.38); // cta soft
  _blob(img, w * 0.18, h * 0.42, w * 0.62, 43, 92, 232, 0.28); // cta deep
  _blob(img, w * 0.78, h * 0.78, w * 0.48, 107, 154, 255, 0.20); // soft
  _blob(img, w * 0.50, h * 0.48, w * 0.42, 61, 110, 255, 0.32); // center bloom

  final artW = (w * logoWidthFactor).round();
  final art = copyResize(logo, width: artW, interpolation: Interpolation.average);
  final ox = ((w - art.width) / 2).round();
  final oy = ((h - art.height) / 2).round();
  compositeImage(img, art, dstX: ox, dstY: oy);
  return img;
}

void _blob(
  Image img,
  double cx,
  double cy,
  double radius,
  int r,
  int g,
  int b,
  double strength,
) {
  final x0 = math.max(0, (cx - radius).floor());
  final x1 = math.min(img.width - 1, (cx + radius).ceil());
  final y0 = math.max(0, (cy - radius).floor());
  final y1 = math.min(img.height - 1, (cy + radius).ceil());
  final r2 = radius * radius;

  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final d2 = dx * dx + dy * dy;
      if (d2 > r2) continue;
      final t = 1.0 - (math.sqrt(d2) / radius);
      final a = strength * t * t;
      if (a < 0.01) continue;
      final p = img.getPixel(x, y);
      final nr = (p.r.toInt() + ((r - p.r.toInt()) * a)).round().clamp(0, 255);
      final ng = (p.g.toInt() + ((g - p.g.toInt()) * a)).round().clamp(0, 255);
      final nb = (p.b.toInt() + ((b - p.b.toInt()) * a)).round().clamp(0, 255);
      img.setPixelRgba(x, y, nr, ng, nb, 255);
    }
  }
}
