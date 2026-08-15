import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyto_app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  runApp(const NytoApp());
}
