import 'package:flutter/material.dart';
import 'package:nyto_app/app/session.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';
import 'package:nyto_app/features/home/home_screen.dart';

class NytoApp extends StatelessWidget {
  const NytoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NYTO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _SessionGate(),
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  late final Future<bool> _session = NytoSession.hasSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: NytoColors.ground,
            body: Center(
              child: CircularProgressIndicator(color: NytoColors.ctaSoft),
            ),
          );
        }
        if (snapshot.data == true) return const HomeScreen();
        return const WelcomeScreen();
      },
    );
  }
}
