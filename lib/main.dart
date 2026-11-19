import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyto_app/app.dart';
import 'package:nyto_app/core/api/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  await rootBundle.load('assets/brand/nyto_boot_splash.png');
  final signedIn = await apiClient.hasSession();
  runApp(NytoApp(signedIn: signedIn));
}
