import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyto_app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  // Warm boot art into memory before first Flutter frame paints.
  await rootBundle.load('assets/brand/nyto_boot_splash.png');
  runApp(const NytoApp());
}
