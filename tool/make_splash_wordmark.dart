import 'dart:io';

import 'package:image/image.dart';

/// Wordmark for Flutter + native launch + Android 12 splash icon.
void main() {
  final src = decodePng(
    File('assets/brand/nyto_logo_primary.png').readAsBytesSync(),
  );
  if (src == null) {
    stderr.writeln('decode failed');
    exit(1);
  }

  // Flatten dark plate → pure black
  final flat = Image(width: src.width, height: src.height, numChannels: 4);
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
      if (maxC < 55 && (maxC - minC) < 28) {
        flat.setPixelRgba(x, y, 0, 0, 0, 255);
      } else {
        flat.setPixelRgba(x, y, r, g, b, 255);
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

  // Android 12+ system splash icon is circle-masked.
  // Put wordmark inside the safe circle so NYTO is visible instantly on tap.
  const canvas = 1152;
  final a12 = Image(width: canvas, height: canvas, numChannels: 4);
  fill(a12, color: ColorRgba8(0, 0, 0, 255));
  // ~52% of canvas fits inside the circular mask with margin
  final artW = (canvas * 0.72).round();
  final art = copyResize(flat, width: artW, interpolation: Interpolation.average);
  final artH = art.height;
  final ox = ((canvas - artW) / 2).round();
  final oy = ((canvas - artH) / 2).round();
  compositeImage(a12, art, dstX: ox, dstY: oy);

  Directory('android/app/src/main/res/drawable-xxxhdpi').createSync(recursive: true);
  File('android/app/src/main/res/drawable-xxxhdpi/nyto_android12_splash.png')
      .writeAsBytesSync(encodePng(a12));
  // Also provide fallback name in drawable/
  Directory('android/app/src/main/res/drawable').createSync(recursive: true);
  File('android/app/src/main/res/drawable/nyto_android12_splash.png')
      .writeAsBytesSync(encodePng(
    copyResize(a12, width: 288, interpolation: Interpolation.average),
  ));

  stdout.writeln('Splash wordmark + Android12 icon ready');
}
